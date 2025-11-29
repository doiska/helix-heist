---@class HeistManager
---@field activeHeists table<string, BankHeist>
---@field playerHeists table<string, string>
---@field playersInCooldown table<string, number>
HeistManager = {
    -- TODO: not completely sure if we should aim for a single source of truth (only a single heist array) or
    -- 1 array for heists and 1 array for players in heists and focusing in O(1) for our lookup functions (isPlayerInHeist for exmaple)
    activeHeists = {},
    playerHeists = {},
    playersInCooldown = {}
}

---@param heistId string
---@param config BankConfig
---@param leaderId string
---@return BankHeist|nil, string?
function HeistManager:createHeist(heistId, config, leaderId)
    if self.activeHeists[heistId] then
        return nil, "Heist already exists"
    end

    if self:isPlayerInHeist(leaderId) then
        return nil, "Player is already in a heist"
    end

    local heist = BankHeist.new(heistId, config, leaderId)

    self.activeHeists[heistId] = heist
    self.playerHeists[leaderId] = heistId

    return heist, nil
end

---@param heistId string
---@return BankHeist|nil
function HeistManager:getHeist(heistId)
    return self.activeHeists[heistId]
end

---@param playerId string
---@return boolean
function HeistManager:isPlayerInHeist(playerId)
    return self.playerHeists[playerId] ~= nil
end

---@param playerId string
---@return BankHeist|nil
function HeistManager:getPlayerHeist(playerId)
    local heistId = self.playerHeists[playerId]

    if not heistId then
        return nil
    end

    return self.activeHeists[heistId]
end

---@param heistId string
---@param playerId string
---@return boolean, string?
function HeistManager:joinHeist(playerId, heistId)
    local heist = self.activeHeists[heistId]

    if not heist then
        return false, "Heist not found"
    end

    if self:isPlayerInHeist(playerId) then
        return false, "Player is already in a heist"
    end

    if heist.state ~= HeistStates.IDLE and heist.state ~= HeistStates.PREPARED then
        return false, "Heist is not accepting new players"
    end

    local success = heist:addParticipant(playerId)

    if not success then
        return false, "Failed to add participant"
    end

    self.playerHeists[playerId] = heistId

    print(playerId, heistId)

    heist:broadcastEvent('HeistUpdate', {
        heistId = heistId,
        state = heist.state,
        participants = heist.participants,
        leader = heist.leader,
        canJoin = heist.state == HeistStates.IDLE or heist.state == HeistStates.PREPARED
    })

    return true, nil
end

---@param playerId string
---@param reason string?
---@return boolean, string?
function HeistManager:leaveHeist(playerId, reason)
    local heistId = self.playerHeists[playerId]

    if not heistId then
        return false, "Player is not in a heist"
    end

    local heist = self.activeHeists[heistId]

    if not heist then
        self.playerHeists[playerId] = nil
        return false, "Heist not found"
    end

    heist:removeParticipant(playerId)
    self.playerHeists[playerId] = nil

    heist:broadcastState()

    if heist.state == HeistStates.FAILED or #heist.participants == 0 then
        self:removeHeist(heistId)
    end

    return true, nil
end

function HeistManager:startHeist(playerId)
    local heist = self:getPlayerHeist(playerId)

    if not heist then
        return false, "No heist found"
    end

    local isLeader = heist.leader == playerId

    if not isLeader then
        return false, "Only the leader can start the heist"
    end

    -- loop through all participants and check if they have necessary items
    for index, value in ipairs(heist.participants) do
        for _, requiredItem in ipairs(heist.config.start.requiredItems) do
            local mockInventoryCount = math.random(1, 10)
            local hasItem = mockInventoryCount >= requiredItem.amount

            if not hasItem then
                return false, "Not all participants have necessary items"
            end
        end
    end

    if not heist:canTransitionTo(HeistStates.ENTRY) then
        return false, "The Heist is not at preparing state"
    end

    heist:transitionTo(HeistStates.ENTRY)

    --todo: teleport players to the heist entrace or mark on their map
    heist:broadcastState()
end

-- TODO: add the option to the leader to delete the heist?
---@param heistId string
function HeistManager:removeHeist(heistId)
    local heist = self.activeHeists[heistId]

    if not heist then
        return
    end

    for playerId, pHeistId in pairs(self.playerHeists) do
        if pHeistId == heistId then
            self.playerHeists[playerId] = nil
        end
    end

    heist:cleanup()

    -- TODO: change the event to something else, we shouldn't need a event only for deletion, might be better to handle like a game state change (aka failed)
    heist:broadcastEvent("HeistDeleted")
    self.activeHeists[heistId] = nil
end

function HeistManager:getPlayerHeistById(playerId)
    return self.playerHeists[playerId]
end

---@param playerId string
function HeistManager:handlePlayerDisconnect(playerId)
    if not self:isPlayerInHeist(playerId) then
        return
    end

    self:leaveHeist(playerId, "disconnected")
end

---@return table
function HeistManager:getActiveHeistsInfo()
    local info = {}

    for heistId, heist in pairs(self.activeHeists) do
        table.insert(info, {
            id = heistId,
            state = heist.state,
            participants = heist.participants,
            leader = heist.leader,
            canJoin = heist.state == HeistStates.IDLE or heist.state == HeistStates.PREPARED
        })
    end

    return info
end

-- TODO: im not sure if i should leave it here or move to heist-events (some kind of handler for player interactions) or something like that, cleanup later
