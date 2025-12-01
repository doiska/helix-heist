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
--- @field createdAt number
--- @field startedAt number?
--- @field finishedAt number?
--- @field loot { status: { uses: number, maxUses: number, amount: number, currentUser: Player? }, playerTotals: table<Player, number> }
--- @field minigames table<string, Minigame>
--- @field playerProgress table<Player, table<string, PlayerMinigameProgress>>
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
    self.createdAt = os.time()
    self.startedAt = nil
    self.finishedAt = nil
    self.minigames = {}
    self.playerProgress = {}
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

        if self.state == HeistStates.VAULT_OPEN then
            payload.vault.loot = HELIXTable.map(self.config.vault.loot, function(loot)
                return {
                    location = loot.location,
                    maxUses = loot.maxUses,
                    channelingTimeInSeconds = loot.channelingTimeInSeconds
                }
            end)
        end
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
        return
    end

    if newState == HeistStates.VAULT_OPEN then
        self.metadata.vaultOpenTime = os.time()

        if self.config.vault and self.config.vault.openDuration then
            print("Vault will close in " .. self.config.vault.openDuration .. " seconds.")
            self:startTimer("vaultClose", self.config.vault.openDuration, function()
                self:transitionTo(HeistStates.ESCAPE)
            end)
        end

        if self.config.vault and self.config.vault.policeAutoArriveInSeconds then
            print("Police will arrive in " .. self.config.vault.policeAutoArriveInSeconds .. " seconds.")
            self:startTimer("policeArrival", self.config.vault.policeAutoArriveInSeconds, function()
                self:alertPolice(true)
            end)
        end

        return
    end

    if newState == HeistStates.ESCAPE then
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
        return
    end

    if newState == HeistStates.COMPLETE then
        self:distributeRewards()
        self:cleanup()
        return
    end

    if newState == HeistStates.FAILED then
        print(string.format("[Heist:%s] Failed", self.id))
        self:cleanup()
        return
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

    -- for _, loot in pairs(self.loot.status) do
    --     -- TODO: should we give the loot to someone else?
    --     if loot.currentUser == playerId then
    --         loot.currentUser = nil
    --     end
    -- end

    if #self.participants == 0 then
        self:transitionTo(HeistStates.FAILED, "All participants left")
        return
    end

    if playerId == self.leader and #self.participants ~= 0 then
        self.leader = self.participants[1]
        return
    end

    -- TODO: dispatch user leaving event
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

    local notificationData = {
        id = self.id,
        location = self.config.vault.location,
        participantCount = #self.participants,
        alarmType = loud and "LOUD" or "SILENT",
        timestamp = os.time()
    }

    -- TODO: notificacao client side
end

function BankHeist:distributeRewards()
    -- TODO: add items/cash to players - equally?
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

    HeistDoors.cleanup(self)
end
