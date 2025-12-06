HeistMinigame = {}

function HeistMinigame.init(heist)
    local config = heist.config

    if config.vault and config.vault.minigame then
        HeistMinigame.createMinigame(heist, "vault_door", "vault", config.vault.minigame)
    end

    local doors = HeistDoors.getDoors(heist)

    if not doors or #doors == 0 then
        return
    end

    for doorId, door in ipairs(doors) do
        local minigameConfig = {
            type = "lockpick",
            lockpick = { maxAttempts = 3 }
        }

        HeistMinigame.createMinigame(heist, doorId, "door", minigameConfig)
    end
end

function HeistMinigame.createMinigame(heist, id, obstacleType, config)
    local minigameType = config.type
    local answer = nil
    local maxAttempts = 5
    local timeLimit = 0

    if minigameType == "pattern" then
        answer = {}

        for _ = 1, 4 do
            table.insert(answer, math.random(0, 9))
        end

        maxAttempts = config.pattern and config.pattern.maxAttempts or 5
        timeLimit = config.pattern and config.pattern.timeLimitInSeconds or 60
    elseif minigameType == "lockpick" then
        answer = math.random(0, 360)
        maxAttempts = config.lockpick and config.lockpick.maxAttempts or 3
        timeLimit = config.lockpick and config.lockpick.timeLimitInSeconds or 30
    end

    heist.minigames[id] = {
        id = id,
        type = obstacleType,
        minigameType = minigameType,
        answer = answer,
        solved = false,
        solvedBy = nil,
        maxAttempts = maxAttempts,
        timeLimit = timeLimit,
        progress = {
            attempts = {},
            attemptsCount = 0,
            exhausted = false,
            lockedBy = nil,
            lockedAt = nil
        }
    }

    print(string.format("[Heist:%s] Minigame %s created (type:%s, timeLimit:%ds)", heist.id, id, minigameType, timeLimit))
end

---@param heist BankHeist
---@param minigame Minigame
---@param playerId Player
---@return boolean, string?
function HeistMinigame.acquireLock(heist, minigame, playerId)
    if minigame.progress.lockedBy ~= nil and minigame.progress.lockedBy ~= playerId then
        return false, "Another player is using this minigame"
    end

    minigame.progress.lockedBy = playerId
    minigame.progress.lockedAt = os.time()

    if minigame.timeLimit > 0 then
        HeistMinigame.startLockTimer(heist, minigame)
    end

    return true, nil
end

---@param heist BankHeist
---@param minigame Minigame
---@param playerId Player?
function HeistMinigame.releaseLock(heist, minigame, playerId)
    if playerId and minigame.progress.lockedBy ~= playerId then
        return
    end

    HeistMinigame.clearLockTimer(heist, minigame.id)

    minigame.progress.lockedBy = nil
    minigame.progress.lockedAt = nil
end

---@param heist BankHeist
---@param minigame Minigame
function HeistMinigame.startLockTimer(heist, minigame)
    local timerId = Timer.SetTimeout(function()
        HeistMinigame.handleLockTimeout(heist, minigame.id)
    end, minigame.timeLimit * 1000)

    heist.minigameTimers[minigame.id] = timerId
end

---@param heist BankHeist
---@param minigameId string
function HeistMinigame.clearLockTimer(heist, minigameId)
    if not heist.minigameTimers[minigameId] then
        return
    end

    Timer.ClearTimeout(heist.minigameTimers[minigameId])
    heist.minigameTimers[minigameId] = nil
end

---@param heist BankHeist
---@param minigameId string
function HeistMinigame.handleLockTimeout(heist, minigameId)
    local minigame = heist.minigames[minigameId]

    if not minigame or not minigame.progress.lockedBy then
        return
    end

    local playerId = minigame.progress.lockedBy

    minigame.progress.attemptsCount = minigame.progress.attemptsCount + 1
    table.insert(minigame.progress.attempts, {
        attempt = "timeout",
        result = { status = "timeout", message = "Time expired" }
    })

    if minigame.progress.attemptsCount >= minigame.maxAttempts then
        minigame.progress.exhausted = true
    end

    minigame.progress.lockedBy = nil
    minigame.progress.lockedAt = nil
    heist.minigameTimers[minigameId] = nil

    heist:broadcastEvent("HeistMinigameTimeout", {
        heistId = heist.id,
        minigameId = minigameId,
        playerId = playerId,
        attemptsRemaining = minigame.maxAttempts - minigame.progress.attemptsCount,
        exhausted = minigame.progress.exhausted
    })

    print(string.format("[Heist:%s] Minigame %s timeout for player %s (remaining:%d)",
        heist.id, minigameId, playerId, minigame.maxAttempts - minigame.progress.attemptsCount))
end

function HeistMinigame.validate(heist, playerId, minigameId, attempt)
    local minigame = heist.minigames[minigameId]

    if not minigame then
        return { status = "error", message = "Minigame not found" }
    end

    if minigame.type == "door" and heist.state ~= HeistStates.ENTRY then
        return { status = "error", message = "Door is not available right now" }
    end

    if minigame.type == "vault" and heist.state ~= HeistStates.VAULT_LOCKED then
        return { status = "error", message = "Vault is not ready yet" }
    end

    if minigame.solved then
        return { status = "error", message = "Already solved by " .. minigame.solvedBy }
    end

    local progress = minigame.progress

    if progress.lockedBy ~= playerId then
        return { status = "error", message = "You do not have access to this minigame" }
    end

    if progress.exhausted then
        return { status = "error", message = "All attempts have been exhausted" }
    end

    local result = nil

    if minigame.minigameType == "pattern" then
        result = HeistMinigame.validatePattern(minigame.answer, attempt)
    elseif minigame.minigameType == "lockpick" then
        result = HeistMinigame.validateLockpick(minigame.answer, attempt)
    else
        print("Invalid minigame: " .. minigameId)
        return {
            status = "error",
            message = "Invalid minigame"
        }
    end

    progress.attemptsCount = progress.attemptsCount + 1
    table.insert(progress.attempts, { attempt = attempt, result = result })

    if result.status ~= "success" then
        return {
            status = "error",
            message = result.error
        }
    end

    if result.data.solved then
        minigame.solved = true
        minigame.solvedBy = playerId

        HeistMinigame.releaseLock(heist, minigame, playerId)

        if minigame.type == "door" then
            HeistDoors.markDoorBypassed(heist, minigameId, playerId)
        end

        if minigame.type == "vault" then
            print("Vault minigame concluded, transition to vault open")
            heist:transitionTo(HeistStates.VAULT_OPEN)
        end

        return {
            status = "success",
            data = {
                solved = true,
                complete = true,
                message = "Solved!",
                attemptsRemaining = 0,
                progress = result.data
            }
        }
    end

    local attemptsRemaining = minigame.maxAttempts - progress.attemptsCount

    if attemptsRemaining <= 0 then
        progress.exhausted = true

        HeistMinigame.releaseLock(heist, minigame, playerId)

        -- TODO: break the lockpick or remove the item

        return {
            status = "success",
            data = {
                solved = false,
                complete = true,
                exhausted = true,
                message = "All attempts exhausted",
                progress = result.data,
                attemptsRemaining = 0
            }
        }
    end

    return {
        status = "success",
        data = {
            solved = false,
            complete = false,
            progress = result.data,
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
    local correctNumbers = {}
    local misplacedNumbers = {}
    local wrongNumbers = {}
    local usedAnswer = {}
    local usedGuess = {}

    for i = 1, 4 do
        if guess[i] == answer[i] then
            correct = correct + 1
            usedAnswer[i] = true
            usedGuess[i] = true
            table.insert(correctNumbers, { index = i, value = guess[i] })
        end
    end

    for i = 1, 4 do
        if not usedGuess[i] then
            for j = 1, 4 do
                if not usedAnswer[j] and guess[i] == answer[j] then
                    present = present + 1
                    usedAnswer[j] = true
                    usedGuess[i] = true
                    table.insert(misplacedNumbers, { index = i, value = guess[i] })
                    break
                end
            end

            if not usedGuess[i] then
                table.insert(wrongNumbers, { index = i, value = guess[i] })
            end
        end
    end

    return {
        status = "success",
        data = {
            solved = (correct == 4),
            correct = correct,
            present = present,
            correctNumbers = correctNumbers,
            misplacedNumbers = misplacedNumbers,
            wrongNumbers = wrongNumbers
        }
    }
end

function HeistMinigame.validateLockpick(answer, guess)
    local diff = math.abs(answer - guess)

    -- i added a tolerance because would be really annoying to guess the perfect position
    local tolerance = 40 -- was 10, increased to 40 only for testing

    return {
        status = "success",
        data = {
            solved = (diff <= tolerance),
            difference = diff,
            hint = diff < 30 and "very close" or (diff < 60 and "close" or "far")
        }
    }
end
