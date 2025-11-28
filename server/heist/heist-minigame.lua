HeistMinigame = {}

---@param heist BankHeist
function HeistMinigame.generate(heist)
    local config = heist.config.vault.minigame

    if config.type ~= "pattern" then
        return
    end

    local sequence = {}
    for _ = 1, 4 do
        table.insert(sequence, math.random(0, 9))
    end

    heist.minigame = {
        sequence = sequence,
        attempts = {}
    }

    print(string.format("minigame: [%d, %d, %d, %d]", heist.id, sequence[1], sequence[2], sequence[3], sequence[4]))
end

---@param heist BankHeist
---@param playerId string
---@param guess [number, number, number, number]
---@return { success: boolean, correct: number?, present: number?, message: string? }
function HeistMinigame.validate(heist, playerId, guess)
    if heist.state ~= HeistStates.VAULT_LOCKED then
        return { success = false, message = "Vault not in correct state" }
    end

    if not heist.minigame then
        return { success = false, message = "Minigame not initialized" }
    end

    if #guess ~= 4 then
        return { success = false, message = "Guess must be 4 digits" }
    end

    heist.metadata.minigameAttempts = heist.metadata.minigameAttempts + 1

    local correct = 0
    local present = 0
    local sequence = heist.minigame.sequence
    local usedSequence = {}
    local usedGuess = {}

    for i = 1, 4 do
        if guess[i] == sequence[i] then
            correct = correct + 1
            usedSequence[i] = true
            usedGuess[i] = true
        end
    end

    for i = 1, 4 do
        if not usedGuess[i] then
            for j = 1, 4 do
                if not usedSequence[j] and guess[i] == sequence[j] then
                    present = present + 1
                    usedSequence[j] = true
                    break
                end
            end
        end
    end

    table.insert(heist.minigame.attempts, {
        playerId = playerId,
        guess = guess,
        result = { correct = correct, present = present }
    })

    if correct == 4 then
        heist:transitionTo(HeistStates.VAULT_OPEN)
        return { success = true, correct = correct, present = present }
    end

    local maxAttempts = heist.config.vault.minigame.pattern.maxAttempts
    if heist.metadata.minigameAttempts >= maxAttempts then
        heist:transitionTo(HeistStates.FAILED, "Too many minigame attempts")
        return { success = false, message = "Max attempts exceeded" }
    end

    return { success = false, correct = correct, present = present }
end
