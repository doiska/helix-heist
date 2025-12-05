--  this class represents the player instance server-side
---@class Player

---@class BankHeist
--- @field id string
--- @field config BankConfig
--- @field state HeistStates
--- @field participants Player[]
--- @field leader Player
--- @field timers table
--- @field lootTimers table
--- @field minigameTimers table
--- @field createdAt number
--- @field startedAt number?
--- @field finishedAt number?
--- @field loot { status: { uses: number, maxUses: number, amount: number, currentUser: Player? }, playerTotals: table<Player, number> }
--- @field minigames table<string, Minigame>
--- @field metadata { alarmTriggered: boolean, policeNotified: boolean, vaultOpenTime: number? }
--- @field doors table<string, { id: string, config: BankDoor, opened: boolean }>
BankHeist = {}
BankHeist.__index = BankHeist

--- @param id string
--- @param playerLeader Player
--- @param config BankConfig
function BankHeist.new(id, config, playerLeader)
    local self = setmetatable({}, BankHeist)

    self.id = id
    self.config = config
    self.state = HeistStates.IDLE
    self.participants = {
        playerLeader
    }

    self.leader = playerLeader
    self.timers = {}
    self.lootTimers = {}
    self.minigameTimers = {}
    self.createdAt = os.time()
    self.startedAt = nil
    self.finishedAt = nil
    self.minigames = {}
    self.metadata = {
        alarmTriggered = false,
        policeNotified = false,
        vaultOpenTime = nil
    }


    if Config.Debug.enabled then
        if Config.Debug.disableItemRequirement then
            self.config.start.requiredItems = {}
        end

        if Config.Debug.disableMinPlayersRequirement then
            self.config.start.minPlayers = 0
            self.config.start.minPoliceOfficers = 0
            self.state = HeistStates.PREPARED
        end
    end

    HeistDoors.init(self)
    HeistMinigame.init(self)
    HeistLoot.init(self)

    return self
end

---@param event string
function BankHeist:broadcastEvent(event, payload)
    for _, player in ipairs(self.participants) do
        if not player then
            print("Player not found.")
            return
        end

        TriggerClientEvent(player, event, payload)
    end
end

function BankHeist:notify(text)
    for _, player in ipairs(self.participants) do
        if not player then
            print("Player not found.")
            return
        end

        -- I'm not sure why the notify export was throwing errors, went with the event instead
        TriggerClientEvent(player, 'QBCore:Notify', text, 'success')
        -- exports['qb-core']:Notify(player, text, "success")
    end
end

function BankHeist:broadcastState()
    local payload = {
        heistId = self.id,
        state = self.state,
        participants = self.participants,
        leader = self.leader,
        canJoin = self.state == HeistStates.IDLE or self.state == HeistStates.PREPARED
    }

    if self.state == HeistStates.ENTRY then
        payload.doors = HeistDoors.getClientDoors(self)
    end

    if self.state == HeistStates.VAULT_LOCKED then
        payload.vault = {
            location = self.config.vault and self.config.vault.location or nil
        }
    end

    if self.state == HeistStates.VAULT_OPEN then
        payload.vault = {
            location = self.config.vault and self.config.vault.location or nil,
            loot = HELIXTable.map(self.config.vault.loot, function(loot)
                return {
                    location = loot.location,
                    maxUses = loot.maxUses,
                    channelingTimeInSeconds = loot.channelingTimeInSeconds
                }
            end)
        }
    end

    self:broadcastEvent('HeistUpdate', payload)
end

function BankHeist:canTransitionTo(newState)
    local validTransitions = {
        [HeistStates.IDLE] = { HeistStates.PREPARED },
        [HeistStates.PREPARED] = { HeistStates.IDLE, HeistStates.ENTRY, HeistStates.FAILED },
        [HeistStates.ENTRY] = { HeistStates.VAULT_LOCKED, HeistStates.FAILED },
        [HeistStates.VAULT_LOCKED] = { HeistStates.VAULT_OPEN, HeistStates.FAILED },
        [HeistStates.VAULT_OPEN] = { HeistStates.ESCAPE, HeistStates.FAILED },
        [HeistStates.ESCAPE] = { HeistStates.COMPLETE, HeistStates.FAILED },
    }

    local allowed = validTransitions[self.state]

    if not allowed then
        return false
    end

    for _, allowedState in ipairs(allowed) do
        if allowedState == newState then
            return true
        end
    end

    return false
end

function BankHeist:transitionTo(newState, reason)
    local oldState = self.state

    if not self:canTransitionTo(newState) then
        return false
    end

    self.state = newState

    if newState == HeistStates.ENTRY and not self.startedAt then
        self.startedAt = os.time()
    end

    if newState == HeistStates.COMPLETE or newState == HeistStates.FAILED then
        self.finishedAt = os.time()
    end

    self:onStateEnter(newState, oldState)
    self:broadcastState()

    return true
end

function BankHeist:onStateEnter(newState, _oldState)
    if newState == HeistStates.ENTRY then
        if HeistDoors.getTotalDoors(self) == 0 then
            self:transitionTo(HeistStates.VAULT_LOCKED)
            return
        end

        if not self.config.security or not self.config.security.alarm then
            return
        end

        local alarmChance = self.config.security.alarm.silentAlarmChance or 0

        if math.random(1, 100) > alarmChance then
            return
        end

        local delay = self.config.security.alarm.silentAlarmDelayInSeconds or 0
        self:scheduleSilentAlarm(delay)
    elseif newState == HeistStates.VAULT_OPEN then
        self.metadata.vaultOpenTime = os.time()

        if self.config.vault and self.config.vault.openDuration then
            print("Vault will close in " .. self.config.vault.openDuration .. " seconds.")
            self:startTimer("vaultClose", self.config.vault.openDuration, function()
                print("Vault closed!")
                self:transitionTo(HeistStates.ESCAPE)
            end)
        end

        if self.config.vault and self.config.vault.policeAutoArriveInSeconds then
            print("Police will arrive in " .. self.config.vault.policeAutoArriveInSeconds .. " seconds.")
            self:startTimer("policeArrival", self.config.vault.policeAutoArriveInSeconds, function()
                print("Police has arrived.")
                self:alertPolice(true)
            end)
        end
    elseif newState == HeistStates.ESCAPE then
        self:clearTimer("vaultClose")

        if not self.config.escape then
            return
        end

        if self.config.escape.condition ~= "police" or not self.config.escape.police then
            return
        end

        self:startTimer("escapeDeadline", self.config.escape.police.durationInSeconds, function()
            self:transitionTo(HeistStates.FAILED, "Failed to escape in time")
        end)
    elseif newState == HeistStates.COMPLETE then
        self:distributeRewards()
        self:cleanup()
    elseif newState == HeistStates.FAILED then
        print(string.format("[Heist:%s] Failed", self.id))
        self:cleanup()
    end
end

function BankHeist:addParticipant(playerId)
    for _, pid in ipairs(self.participants) do
        if pid == playerId then
            return false
        end
    end

    table.insert(self.participants, playerId)

    if #self.participants == self.config.start.minPlayers then
        self:transitionTo(HeistStates.PREPARED)
    end

    return true
end

function BankHeist:removeParticipant(playerId)
    for i, pid in ipairs(self.participants) do
        if pid == playerId then
            table.remove(self.participants, i)
            break
        end
    end

    for _, minigame in pairs(self.minigames) do
        if minigame.progress.lockedBy == playerId then
            HeistMinigame.releaseLock(self, minigame, playerId)
        end
    end

    if #self.participants == 0 then
        self:transitionTo(HeistStates.FAILED, "All participants left")
        return
    end

    if playerId == self.leader and #self.participants ~= 0 then
        self.leader = self.participants[1]
        return
    end
end

function BankHeist:startTimer(name, duration, callback)
    if self.timers[name] then
        self:clearTimer(name)
    end

    local timerId = Timer.SetTimeout(callback, duration * 1000)
    self.timers[name] = timerId
end

function BankHeist:clearTimer(name)
    if not self.timers[name] then
        return
    end

    Timer.ClearTimeout(self.timers[name])
    self.timers[name] = nil
end

function BankHeist:scheduleSilentAlarm(delay)
    self:startTimer("silentAlarm", delay, function()
        self.metadata.alarmTriggered = true
        self:alertPolice(false)
    end)
end

function BankHeist:alertPolice(loud)
    if self.metadata.policeNotified then
        return
    end

    self.metadata.policeNotified = true

    -- local notificationData = {
    --     id = self.id,
    --     location = self.config.vault.location,
    --     participantCount = #self.participants,
    --     alarmType = loud and "LOUD" or "SILENT",
    --     timestamp = os.time()
    -- }

    -- The QBCore police job doesn't have alerts implemented yet, I'm using the Notify to replace it
    -- https://github.com/hypersonic-laboratories/qbcore-rp/blob/8a5bb60d34852a3fd6d538e8b1210ac689821d57/qb-policejob/Client/main.lua#L180
    local policeOfficers = QBCore.Functions.GetPlayersOnDuty("police")

    for _, playerSource in ipairs(policeOfficers) do
        exports['qb-core']:Player(playerSource, 'Notify', 'Bank ' .. self.id .. ' is being robbed!')
    end
end

function BankHeist:distributeRewards()
    local heistTotal = HELIXTable.reduce(self.loot.playerTotals, function(acc, val) return acc + val end, 0)
    local rewardPerPlayer = math.floor(heistTotal / #self.participants)

    for _, player in ipairs(self.participants) do
        exports['qb-core']:Player(player, 'AddMoney', 'bank', rewardPerPlayer, 'Heist reward')
        -- Copied from https://github.com/hypersonic-laboratories/qbcore-rp/blob/8a5bb60d34852a3fd6d538e8b1210ac689821d57/qb-banking/server.lua#L219C9-L219C97
        -- This syntax doesn't work: QBCore.Functions.AddMoney(player, "bank", rewardPerPlayer)
    end

    self:notify("Money laundered, your cut is: $" .. rewardPerPlayer)
end

function BankHeist:cleanup()
    for timerName, _ in pairs(self.timers) do
        self:clearTimer(timerName)
    end

    for lootIndex, _ in pairs(self.lootTimers) do
        if self.lootTimers[lootIndex] then
            Timer.ClearTimeout(self.lootTimers[lootIndex])
            self.lootTimers[lootIndex] = nil
        end
    end

    for minigameId, _ in pairs(self.minigameTimers) do
        if self.minigameTimers[minigameId] then
            Timer.ClearTimeout(self.minigameTimers[minigameId])
            self.minigameTimers[minigameId] = nil
        end
    end

    HeistDoors.cleanup(self)
end
