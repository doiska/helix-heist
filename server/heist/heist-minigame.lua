HeistMinigame = {}

function HeistMinigame.initializeMinigames(heist)
    local config = heist.config

    if config.vault and config.vault.minigame then
        HeistMinigame.createMinigame(heist, "vault_door", "vault", config.vault.minigame)
    end

    if config.security and config.security.doors then
        for i, door in ipairs(config.security.doors) do
            local doorId = "door_" .. i
            local minigameConfig = {
                type = "lockpick",
                lockpick = { maxAttempts = 3 }
            }

            HeistMinigame.createMinigame(heist, doorId, "door", minigameConfig)
        end
    end
end

function HeistMinigame.createMinigame(heist, id, obstacleType, config)
    local minigameType = config.type
    local answer = nil
    local maxAttempts = 5

    if minigameType == "pattern" then
        answer = {}
        for _ = 1, 4 do
            table.insert(answer, math.random(0, 9))
        end
        maxAttempts = config.pattern and config.pattern.maxAttempts or 5
    elseif minigameType == "lockpick" then
        answer = math.random(0, 360)
        maxAttempts = config.lockpick and config.lockpick.maxAttempts or 3
    end

    heist.minigames[id] = {
        id = id,
        type = obstacleType,
        minigameType = minigameType,
        answer = answer,
        solved = false,
        solvedBy = nil,
        maxAttempts = maxAttempts
    }

    print(string.format("[Heist:%s] Minigame %s created (type:%s)", heist.id, id, minigameType))
end

function HeistMinigame.validate(heist, playerId, minigameId, attempt)
    local minigame = heist.minigames[minigameId]

    if not minigame then
        return { status = "error", message = "Minigame not found" }
    end

    if minigame.solved then
        return { status = "error", message = "Already solved by " .. minigame.solvedBy }
    end

    if not heist.playerProgress[playerId] then
        heist.playerProgress[playerId] = {}
    end

    if not heist.playerProgress[playerId][minigameId] then
        heist.playerProgress[playerId][minigameId] = {
            attempts = {},
            attemptsCount = 0,
            completed = false
        }
    end

    local progress = heist.playerProgress[playerId][minigameId]

    if progress.completed then
        return { status = "error", message = "You already completed this" }
    end

    local result = nil

    if minigame.minigameType == "pattern" then
        result = HeistMinigame.validatePattern(minigame.answer, attempt)
    elseif minigame.minigameType == "lockpick" then
        result = HeistMinigame.validateLockpick(minigame.answer, attempt)
    else
        print("Invalid minigame: " .. minigame)
        return {
            status = "error",
            message = "Invalid minigame"
        }
    end

    progress.attemptsCount = progress.attemptsCount + 1
    table.insert(progress.attempts, { attempt = attempt, result = result })

    if result.status == "success" then
        minigame.solved = true
        minigame.solvedBy = playerId
        progress.completed = true

        if minigame.type == "vault" then
            heist:transitionTo(HeistStates.VAULT_OPEN)
        end

        return {
            status = "success",
            data = {
                solved = true,
                complete = true,
                result = result,
                message = "Solved!",
                attemptsRemaining = 0
            }
        }
    end

    local attemptsRemaining = minigame.maxAttempts - progress.attemptsCount

    if attemptsRemaining <= 0 then
        progress.completed = true

        return {
            status = "success",
            data = {
                solved = false,
                complete = true,
                message = "Max attempts exceeded",
                result = result,
                attemptsRemaining = 0
            }
        }
    end

    return {
        status = "success",
        data = {
            solved = false,
            complete = false,
            result = result,
            message = "Incorrect",
            attemptsRemaining = attemptsRemaining
        }
    }
end

function HeistMinigame.validatePattern(answer, guess)
    if #guess ~= 4 then
        return { status = "error", error = "Must be 4 digits" }
    end

    local correct = 0
    local present = 0
    local usedAnswer = {}
    local usedGuess = {}

    for i = 1, 4 do
        if guess[i] == answer[i] then
            correct = correct + 1
            usedAnswer[i] = true
            usedGuess[i] = true
        end
    end

    for i = 1, 4 do
        if not usedGuess[i] then
            for j = 1, 4 do
                if not usedAnswer[j] and guess[i] == answer[j] then
                    present = present + 1
                    usedAnswer[j] = true
                    break
                end
            end
        end
    end

    return {
        status = "success",
        data = {
            solved = (correct == 4),
            correct = correct,
            present = present
        }
    }
end

function HeistMinigame.validateLockpick(answer, guess)
    local diff = math.abs(answer - guess)

    -- i added a tolerance because would be really annoying to guess the perfect position
    local tolerance = 10

    return {
        status = "success",
        data = {
            solved = (diff <= tolerance),
            difference = diff,
            hint = diff < 30 and "very close" or (diff < 60 and "close" or "far")
        }
    }
end
