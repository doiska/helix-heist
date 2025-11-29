---@enum HeistStates
HeistStates = {
    IDLE = "IDLE",
    PREPARED = "PREPARED",
    ENTRY = "ENTRY",
    VAULT_LOCKED = "VAULT_LOCKED",
    VAULT_OPEN = "VAULT_OPEN",
    LOOTING = "LOOTING",
    ESCAPE = "ESCAPE",
    COMPLETE = "COMPLETE",
    FAILED = "FAILED"
}

---@class BankHeist
--- @field id string
--- @field config BankConfig
--- @field state HeistStates
--- @field participants string[]
--- @field leader string
--- @field timers table
--- @field lootTimers table
--- @field createdAt number
--- @field startedAt number?
--- @field finishedAt number?
--- @field loot { status: { uses: number, maxUses: number, amount: number, currentUser: string? }, playerTotals: table<string, number> }
--- @field minigame { sequence: number[], attempts: { playerId: string, guess: number[], result: { correct: number, present: number } }[] }?
--- @field metadata { alarmTriggered: boolean, policeNotified: boolean, vaultOpenTime: number?, doorsBypassed: string[], minigameAttempts: number }
BankHeist = {}
BankHeist.__index = BankHeist

--- @param id string
--- @param leaderId string
--- @param config BankConfig
function BankHeist.new(id, config, leaderId)
    local self = setmetatable({}, BankHeist)

    self.id = id
    self.config = config
    self.state = HeistStates.IDLE
    self.participants = {
        leaderId
    }

    self.leader = leaderId
    self.timers = {}
    self.lootTimers = {}
    self.createdAt = os.time()
    self.startedAt = nil
    self.finishedAt = nil

    self.loot = {
        status = {},
        playerTotals = {}
    }

    self.metadata = {
        alarmTriggered = false,
        policeNotified = false,
        vaultOpenTime = nil,
        doorsBypassed = {},
        minigameAttempts = 0
    }

    if config.vault and config.vault.loot then
        for i, lootConfig in ipairs(config.vault.loot) do
            self.loot.status[i] = {
                maxUses = lootConfig.maxUses or 1,
                uses = 0,
                amount = math.random(2000, 6000),
                currentUser = nil
            }
        end
    end

    return self
end

---@param event string
function BankHeist:broadcastEvent(event, ...)
    for _, playerId in ipairs(self.participants) do
        TriggerClientEvent(event, playerId, ...)
    end
end

function BankHeist:canTransitionTo(newState)
    local validTransitions = {
        [HeistStates.IDLE] = { HeistStates.PREPARED },
        [HeistStates.PREPARED] = { HeistStates.IDLE, HeistStates.ENTRY, HeistStates.FAILED },
        [HeistStates.ENTRY] = { HeistStates.VAULT_LOCKED, HeistStates.FAILED },
        [HeistStates.VAULT_LOCKED] = { HeistStates.VAULT_OPEN, HeistStates.FAILED },
        [HeistStates.VAULT_OPEN] = { HeistStates.LOOTING, HeistStates.FAILED },
        [HeistStates.LOOTING] = { HeistStates.ESCAPE, HeistStates.FAILED },
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

function BankHeist:onStateEnter(newState, oldState)
    if newState == HeistStates.ENTRY then
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
            self:startTimer("vaultClose", self.config.vault.openDuration, function()
                self:transitionTo(HeistStates.ESCAPE)
            end)
        end

        if self.config.vault and self.config.vault.policeAutoArriveInSeconds then
            self:startTimer("policeArrival", self.config.vault.policeAutoArriveInSeconds, function()
                self:alertPolice(true)
            end)
        end

        self:transitionTo(HeistStates.LOOTING)
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
    print("Player .. " .. playerId .. " joined")

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

---@param lootIndex number
---@param playerId string
function BankHeist:startLootCollection(lootIndex, playerId)
    local loot = self.loot.status[lootIndex]

    if not loot or loot.uses >= loot.maxUses then
        return { success = false, message = "Loot not available" }
    end

    if loot.currentUser then
        return { success = false, message = "Someone else is collecting" }
    end

    loot.currentUser = playerId

    local duration = self.config.vault.loot[lootIndex].channelingTimeInSeconds

    local timerId = Timer.SetTimeout(function()
        self:completeLootCollection(lootIndex, playerId)
    end, duration * 1000)

    self.lootTimers[lootIndex] = timerId

    return { success = true, duration = duration }
end

---@param lootIndex number
---@param playerId string
function BankHeist:abortLootCollection(lootIndex, playerId)
    local loot = self.loot.status[lootIndex]

    if not loot or loot.currentUser ~= playerId then
        return { success = false }
    end

    if self.lootTimers[lootIndex] then
        Timer.ClearTimeout(self.lootTimers[lootIndex])
        self.lootTimers[lootIndex] = nil
    end

    loot.currentUser = nil
    return { success = true, aborted = true }
end

---@param lootIndex number
---@param playerId string
function BankHeist:completeLootCollection(lootIndex, playerId)
    local loot = self.loot.status[lootIndex]

    if not loot then
        return false, "Loot no longer exists"
    end

    if loot.currentUser ~= playerId then
        return false, "Loot is being collected by another player"
    end

    -- todo: make it configurable
    local amount = math.random(1000, 5000)

    loot.uses = loot.uses + 1
    loot.currentUser = nil

    self.loot.playerTotals[playerId] = (self.loot.playerTotals[playerId] or 0) + amount
    self.lootTimers[lootIndex] = nil

    return true
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
end
