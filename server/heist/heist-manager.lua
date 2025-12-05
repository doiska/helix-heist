---@class HeistManager
---@field activeHeists table<string, BankHeist>
---@field playerHeists table<string, string>
---@field playersInCooldown table<string, number>
HeistManager = {
    activeHeists = {},
    playerHeists = {},
    playersInCooldown = {}
}

---@param heistId string
---@param config BankConfig
---@param leaderId Player
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

---@param player Player
---@return boolean
function HeistManager:isPlayerInHeist(player)
    return self.playerHeists[player] ~= nil
end

---@param player string
---@return BankHeist|nil
function HeistManager:getPlayerHeist(player)
    local heistId = self.playerHeists[player]

    if not heistId then
        return nil
    end

    return self.activeHeists[heistId]
end

---@param heistId string
---@param player Player
---@return boolean, string?
function HeistManager:joinHeist(player, heistId)
    if self:isPlayerInHeist(player) then
        return false, "Player is already in a heist"
    end

    local heist = self.activeHeists[heistId]

    if not heist then
        return false, "Heist not found"
    end

    if heist.state ~= HeistStates.IDLE and heist.state ~= HeistStates.PREPARED then
        return false, "Heist is not accepting new players"
    end

    local success = heist:addParticipant(player)

    if not success then
        return false, "Failed to add participant"
    end

    self.playerHeists[player] = heistId

    heist:broadcastEvent('HeistUpdate', {
        heistId = heistId,
        state = heist.state,
        participants = heist.participants,
        leader = heist.leader,
        canJoin = heist.state == HeistStates.IDLE or heist.state == HeistStates.PREPARED
    })

    return true, nil
end

---@param player Player
---@param reason string?
---@return boolean, string?
function HeistManager:leaveHeist(player, reason)
    local heistId = self.playerHeists[player]

    if not heistId then
        return false, "Player is not in a heist"
    end

    local heist = self.activeHeists[heistId]

    if not heist then
        self.playerHeists[player] = nil
        return false, "Heist not found"
    end

    heist:removeParticipant(player)
    self.playerHeists[player] = nil

    heist:broadcastState()

    if heist.state == HeistStates.FAILED or #heist.participants == 0 then
        self:removeHeist(heistId)
    end

    return true, nil
end

function HeistManager:startHeist(player)
    local heist = self:getPlayerHeist(player)

    if not heist then
        return false, "No heist found"
    end

    local isLeader = heist.leader == player

    if not isLeader then
        return false, "Only the leader can start the heist"
    end

    if not heist:canTransitionTo(HeistStates.ENTRY) then
        return false, "The Heist is not at preparing state, it is currently in state " .. heist.state
    end

    for _, participant in ipairs(heist.participants) do
        for _, requiredItem in ipairs(heist.config.start.requiredItems) do
            local itemCount = exports['qb-inventory']:GetItemCount(participant, requiredItem.id)

            if not itemCount then
                return false, "Something went wrong, item count was nil"
            end

            local hasItem = itemCount >= requiredItem.amount

            if not hasItem then
                local playerName = exports['qb-core']:GetPlayer(participant).PlayerData.charinfo.firstname
                return false, "Player " .. playerName .. " does not have enough " .. requiredItem.id
            end
        end
    end

    heist:transitionTo(HeistStates.ENTRY)
    heist:broadcastState()

    for _, participant in ipairs(heist.participants) do
        SetEntityCoords(GetPlayerPawn(participant), heist.config.start.location)
    end

    heist:notify("Heist started, time is ticking!")

    return true, "Started!"
end

---@param heistId string
function HeistManager:removeHeist(heistId)
    local heist = self.activeHeists[heistId]

    if not heist then
        return
    end

    for player, pHeistId in pairs(self.playerHeists) do
        if pHeistId == heistId then
            self.playerHeists[player] = nil
        end
    end

    heist:cleanup()
    self.activeHeists[heistId] = nil
end

---@param player Player
function HeistManager:getPlayerHeistById(player)
    return self.playerHeists[player]
end

---@param player Player
function HeistManager:handlePlayerDisconnect(player)
    self:leaveHeist(player, "disconnected")
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

---@param heist BankHeist
function HeistManager:cleanup(heist)
    HeistDoors.cleanup(heist)
end

_G.HeistManager = HeistManager

function onShutdown()
    for _, heist in pairs(HeistManager.activeHeists) do
        HeistManager:cleanup(heist)
    end
end
