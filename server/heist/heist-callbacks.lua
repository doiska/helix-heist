-- some considerations:
-- I know the return logic is redundant, I'm still thinking in a better approach, but this makes the response consistent and easy to handle

local DOOR_INTERACT_RANGE = 300.0
local LOOT_INTERACT_RANGE = 300.0

local function distanceBetweenVectors(a, b)
    return HELIXMath.VectorDistance(a, b)
end

local function getPlayerLocation(player)
    local pawn = GetPlayerPawn(player)

    if not pawn then
        return
    end

    return GetEntityCoords(pawn)
end

local function isVaultOpen(heist)
    return heist.state == HeistStates.VAULT_OPEN
end

RegisterCallback("CreateHeist", function(player)
    -- hardcoded bank cfg for now (need to add to the ui)
    local heist, errorMessage = HeistManager:createHeist("heist_" .. player:GetName(), Config.Banks.central, player)

    if heist == nil then
        return {
            status = "error",
            message = errorMessage
        }
    end

    return {
        status = "success",
        data = heist
    }
end)

RegisterCallback('JoinHeist', function(player, heistId)
    local success, errorMessage = HeistManager:joinHeist(player, heistId)

    if success then
        return {
            status = "success",
            data = {}
        }
    end

    return {
        status = "error",
        message = errorMessage
    }
end)

RegisterCallback('LeaveHeist', function(player, reason)
    local success, errorMessage = HeistManager:leaveHeist(player, reason)

    if not success then
        return {
            status = "error",
            message = errorMessage
        }
    end

    return {
        status = "success",
        data = {}
    }
end)

RegisterCallback("StartHeist", function(player, ...)
    local success, message = HeistManager:startHeist(player)

    if success then
        return {
            status = "success",
            data = {}
        }
    else
        return {
            status = "error",
            message = message
        }
    end
end)

RegisterCallback("GetActiveHeistInfo", function()
    return {
        status = "success",
        data = HeistManager:getActiveHeistsInfo()
    }
end)

RegisterCallback("GetUserHeistState", function(player)
    local heistId = HeistManager:getPlayerHeistById(player)

    return {
        status = "success",
        data = {
            inHeist = heistId ~= nil,
            heistId = heistId
        }
    }
end)

RegisterCallback("StartMinigame", function(player, minigameId)
    local heist = HeistManager:getPlayerHeist(player)

    if not heist then
        return { status = "error", message = "Not in a heist" }
    end

    local minigame = heist.minigames[minigameId]
    if not minigame then
        return { status = "error", message = "Minigame not found" }
    end


    if minigame.progress.exhausted then
        return { status = "error", message = "All attempts have been exhausted" }
    end

    local lockAcquired, lockError = HeistMinigame.acquireLock(heist, minigame, player)

    if not lockAcquired then
        return { status = "error", message = lockError }
    end

    local progress = minigame.progress
    local attemptsRemaining = math.max(0, minigame.maxAttempts - progress.attemptsCount)

    if minigame.type == "door" then
        if HeistDoors.isDoorBypassed(heist, minigameId) then
            return { status = "error", message = "Door already open" }
        end

        if heist.state ~= HeistStates.ENTRY then
            return { status = "error", message = "Doors can only be bypassed during entry" }
        end

        local doorConfig = HeistDoors.getDoorConfig(heist, minigameId)

        local playerLocation = getPlayerLocation(player)

        if not playerLocation then
            return { status = "error", message = "Unable to find your character" }
        end

        if doorConfig and playerLocation then
            local distance = distanceBetweenVectors(playerLocation, doorConfig.location)

            if distance > DOOR_INTERACT_RANGE then
                return { status = "error", message = "Move closer to the door" }
            end
        end
    elseif minigame.type == "vault" then
        if heist.state ~= HeistStates.VAULT_LOCKED then
            return { status = "error", message = "Vault is not ready yet" }
        end
    end

    if minigame.solved then
        return { status = "error", message = "Already solved" }
    end

    return {
        status = "success",
        data = {
            id = minigame.id,
            type = minigame.type,
            minigameType = minigame.minigameType,
            maxAttempts = minigame.maxAttempts,
            attemptsRemaining = attemptsRemaining,
            timeLimit = minigame.timeLimit
        }
    }
end)

RegisterCallback("SubmitMinigameAttempt", function(player, data)
    local heist = HeistManager:getPlayerHeist(player)

    if not heist then
        return { status = "error", message = "Not in a heist" }
    end

    if not data.minigameId or not data.attempt then
        return { status = "error", message = "Invalid data" }
    end

    return HeistMinigame.validate(heist, player, data.minigameId, data.attempt)
end)

RegisterCallback("StartLootCollection", function(player, lootIndex)
    local heist = HeistManager:getPlayerHeist(player)

    if not heist then
        return { status = "error", message = "Not in a heist" }
    end

    if not isVaultOpen(heist) then
        return { status = "error", message = "Vault is not open" }
    end

    local index = tonumber(lootIndex)

    if not index then
        return { status = "error", message = "Invalid loot index" }
    end

    local lootConfig = heist.config.vault and heist.config.vault.loot and heist.config.vault.loot[index]

    if not lootConfig then
        return { status = "error", message = "Loot not found" }
    end

    local playerLocation = getPlayerLocation(player)

    if not playerLocation then
        return { status = "error", message = "Unable to find your character" }
    end

    local distance = distanceBetweenVectors(playerLocation, lootConfig.location)

    if distance > LOOT_INTERACT_RANGE then
        return { status = "error", message = "Move closer to the loot" }
    end

    return HeistLoot.start(heist, index, player)
end)

RegisterCallback("StopLootCollection", function(player, lootIndex)
    local heist = HeistManager:getPlayerHeist(player)

    if not heist then
        return { status = "error", message = "Not in a heist" }
    end

    if not isVaultOpen(heist) then
        return { status = "error", message = "Vault is not open" }
    end

    local index = tonumber(lootIndex)

    if not index then
        return { status = "error", message = "Invalid loot index" }
    end

    local lootConfig = heist.config.vault and heist.config.vault.loot and heist.config.vault.loot[index]

    if not lootConfig then
        return { status = "error", message = "Loot not found" }
    end

    local playerLocation = getPlayerLocation(player)

    if not playerLocation then
        return { status = "error", message = "Unable to find your character" }
    end

    local distance = distanceBetweenVectors(playerLocation, lootConfig.location)

    if distance > LOOT_INTERACT_RANGE then
        return { status = "error", message = "Move closer to the loot" }
    end

    return HeistLoot.abort(heist, index, player)
end)
