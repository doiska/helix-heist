-- some considerations:
-- I know the return logic is redundant, I'm still thinking in a better approach, but this makes the response consistent and easy to handle

RegisterCallback("CreateHeist", function(player)
    local source = player:GetName()

    print("Received CreateHeist server-side: " .. source)
    -- hardcoded bank cfg for now (need to add to the ui)
    local heist, errorMessage = HeistManager:createHeist("heist_" .. source, Config.Banks.central, source)

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
    local source = player:GetName()
    local success, errorMessage = HeistManager:joinHeist(source, heistId)

    if not success then
        return {
            status = "success",
            data = {}
        }
    end

    return {
        status = success,
        message = errorMessage
    }
end)

RegisterCallback('LeaveHeist', function(player, reason)
    local source = player:GetName()
    local success, errorMessage = HeistManager:leaveHeist(source, reason)

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
    local success, message = HeistManager:startHeist(player:GetName())

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
    local source = player:GetName()
    local heistId = HeistManager:getPlayerHeistById(source)

    return {
        status = "success",
        data = {
            inHeist = heistId ~= nil,
            heistId = heistId
        }
    }
end)

RegisterCallback("StartMinigame", function(player, minigameId)
    local playerId = player:GetName()
    local heist = HeistManager:getPlayerHeist(playerId)

    if not heist then
        return { status = "error", message = "Not in a heist" }
    end

    local minigame = heist.minigames[minigameId]
    if not minigame then
        return { status = "error", message = "Minigame not found" }
    end

    if minigame.solved then
        return { status = "error", message = "Already solved" }
    end

    local progress = heist.playerProgress[playerId] and heist.playerProgress[playerId][minigameId]
    local attemptsUsed = progress and progress.attemptsCount or 0

    return {
        status = "success",
        data = {
            id = minigame.id,
            type = minigame.type,
            minigameType = minigame.minigameType,
            maxAttempts = minigame.maxAttempts,
            attemptsRemaining = minigame.maxAttempts - attemptsUsed
        }
    }
end)

RegisterCallback("SubmitMinigameAttempt", function(player, minigameId, attempt)
    local playerId = player:GetName()
    local heist = HeistManager:getPlayerHeist(playerId)

    if not heist then
        return { status = "error", message = "Not in a heist" }
    end

    return HeistMinigame.validate(heist, playerId, minigameId, attempt)
end)
