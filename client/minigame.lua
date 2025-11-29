local activeMinigame = nil
local Console = GetActorByTag('HConsole')

Console:RegisterCommand("startminigame", "Start a minigame", nil, {
    HWorld,
    function(minigameId)
        if not minigameId then
            print("Usage: /startminigame <id>")
            print("IDs: vault_door, door_1, door_2")
            return
        end

        TriggerCallback("StartMinigame", function(result)
            if result.status ~= "success" then
                print("Error: " .. (result.message or "Unknown"))
                return
            end

            activeMinigame = result.data

            if result.data.minigameType == "pattern" then
                print("Use: /submitminigame vault_door 1 2 3 4")
            elseif result.data.minigameType == "lockpick" then
                print("Use: /submitminigame door_1 180")
            end
        end, minigameId)
    end
})

Console:RegisterCommand("submitminigame", "Submit minigame attempt", nil, {
    HWorld,
    function(minigameId, ...)
        if not minigameId then
            print("submitminigame <id> <attempt>")
            return
        end

        local args = { ... }
        local attempt = nil

        if not activeMinigame then
            print("No active minigame")
            return
        end

        if activeMinigame and activeMinigame.minigameType == "pattern" then
            if #args ~= 4 then
                print("Pattern requires 4 digits")
                return
            end

            attempt = {
                tonumber(args[1]),
                tonumber(args[2]),
                tonumber(args[3]),
                tonumber(args[4])
            }
        elseif activeMinigame and activeMinigame.minigameType == "lockpick" then
            if #args ~= 1 then
                print("Lockpick requires 1 number")
                return
            end

            attempt = tonumber(args[1])
        end

        TriggerCallback("SubmitMinigameAttempt", function(result)
            if result.status == "error" then
                print("Error: " .. (result.message or "Unknown"))
                return
            end

            local data = result.data

            if data.result and data.solved then
                activeMinigame = nil
                return
            end

            if not data.solved and data.complete then
                print("FAILED: " .. (data.message or "Max attempts"))
                activeMinigame = nil
                return
            end

            if activeMinigame.minigameType == "pattern" then
                print(string.format(
                    "Correct: %d Present: %d | Left: %d",
                    data.result.correct,
                    data.result.present,
                    data.attemptsRemaining
                ))
            elseif activeMinigame.minigameType == "lockpick" then
                print(string.format(
                    "Diff: %d (%s) | Left: %d",
                    data.result.difference,
                    data.result.hint,
                    data.attemptsRemaining
                ))
            end
        end, minigameId, attempt)
    end
})
