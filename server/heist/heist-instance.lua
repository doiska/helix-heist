---@class BankHeist
--- @field id string
--- @field config BankConfig
--- @field state HeistStates
--- @field participants string[]
--- @field leader string
--- @field timers table
--- @field startTime number
--- @field metadata { alarmTriggered: boolean, policeNotified: boolean, vaultOpenTime: number?, doorsBypassed: string[], minigameAttempts: number, totalLootCollected: number, failureReason: string? }
--- @field lootStatus table
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
    self.startTime = nil
    self.metadata = {
        alarmTriggered = false,
        policeNotified = false,
        vaultOpenTime = nil,
        doorsBypassed = {},
        minigameAttempts = 0,
        totalLootCollected = 0,
        failureReason = nil
    }

    self.lootStatus = {}

    if config.vault and config.vault.loot then
        for i, loot in ipairs(config.vault.loot) do
            self.lootStatus[i] = {
                collected = false,
                usesRemaining = loot.maxUses or 1,
                currentUser = nil,
                amount = 0
            }
        end
    end

    return self
end

---@param event string
function BankHeist:broadcastEvent(event, ...)
    for _, playerId in ipairs(self.participants) do
        TriggerClientEvent(event, tonumber(playerId), ...)
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
        return false, nil
    end

    self.state = newState

    if newState == HeistStates.FAILED and reason then
        -- TODO: add callback or event instead of reason?
        self.metadata.failureReason = reason
    end

    return true, oldState
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

    for _, loot in pairs(self.lootStatus) do
        -- TODO: should we give the loot to someone else?
        if loot.currentUser == playerId then
            loot.currentUser = nil
        end
    end

    if playerId == self.leader then
        -- TODO: promote a new leader like a lobby system
        self:transitionTo(HeistStates.FAILED, "All participants left")
    end

    -- TODO: handle if all players leave
end

---@param lootIndex number
---@param playerId string
function BankHeist:startLootCollection(lootIndex, playerId)
    local loot = self.lootStatus[lootIndex]

    if not loot or loot.collected or loot.usesRemaining <= 0 then
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

    if not self.lootTimers then
        self.lootTimers = {}
    end
    self.lootTimers[lootIndex] = timerId

    return { success = true, duration = duration }
end

---@param lootIndex number
---@param playerId string
function BankHeist:abortLootCollection(lootIndex, playerId)
    local loot = self.lootStatus[lootIndex]

    if not loot or loot.currentUser ~= playerId then
        return { success = false }
    end

    if self.lootTimers and self.lootTimers[lootIndex] then
        Timer.ClearTimeout(self.lootTimers[lootIndex])
        self.lootTimers[lootIndex] = nil
    end

    loot.currentUser = nil
    return { success = true, aborted = true }
end

---@param lootIndex number
---@param playerId string
---@private
function BankHeist:completeLootCollection(lootIndex, playerId)
    local loot = self.lootStatus[lootIndex]

    if not loot or loot.currentUser ~= playerId then
        return
    end

    local amount = math.random(1000, 5000)
    loot.usesRemaining = loot.usesRemaining - 1

    if loot.usesRemaining <= 0 then
        loot.collected = true
    end

    self.metadata.totalLootCollected = self.metadata.totalLootCollected + amount
    loot.currentUser = nil

    if self.lootTimers then
        self.lootTimers[lootIndex] = nil
    end

    self:broadcastEvent('lootCollected', self.metadata.totalLootCollected)
end
