-- some considerations:
-- I know the return logic is redundant, I'm still thinking in a better approach, but this makes the response consistent and easy to handle

local DOOR_INTERACT_RANGE = 300.0

local function distanceBetweenVectors(a, b)
    return HELIXMath.VectorDistance(a, b)
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

    local progress = heist.playerProgress[player] and heist.playerProgress[player][minigameId]
    local attemptsUsed = progress and progress.attemptsCount or 0
    local attemptsRemaining = math.max(0, minigame.maxAttempts - attemptsUsed)

    if progress and progress.completed then
        return { status = "error", message = "No attempts remaining" }
    end

    if minigame.type == "door" then
        if HeistDoors.isDoorBypassed(heist, minigameId) then
            return { status = "error", message = "Door already open" }
        end

        if heist.state ~= HeistStates.ENTRY then
            return { status = "error", message = "Doors can only be bypassed during entry" }
        end

        local doorConfig = HeistDoors.getDoorConfig(heist, minigameId)

        local pawn = GetPlayerPawn(player)
        local playerLocation = GetEntityCoords(pawn)

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
            attemptsRemaining = attemptsRemaining
        }
    }
end)

RegisterCallback("SubmitMinigameAttempt", function(player, minigameId, attempt)
    local heist = HeistManager:getPlayerHeist(player)

    if not heist then
        return { status = "error", message = "Not in a heist" }
    end

    return HeistMinigame.validate(heist, player, minigameId, attempt)
end)
