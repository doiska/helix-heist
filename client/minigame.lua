local activeMinigame = nil
local DOOR_INTERACT_RANGE = 50.0

-- all 3 functions are not properly documented
---@param doors { id: string, location: Vector }
local function findClosestDoor(doors)
    if not doors then
        return nil
    end

    local playerLocation = GetPlayerLocation()

    if not playerLocation then
        return nil
    end

    local closest = nil

    for _, door in ipairs(doors) do
        local distance = HELIXMath.VectorDistance(playerLocation, door.location)

        if distance <= DOOR_INTERACT_RANGE and (closest == nil or distance < closest.distance) then
            closest = {
                id = door.id,
                distance = distance
            }
        end
    end

    return closest
end

DebugCommand("startminigame", function(args)
    local minigameId = args[1]

    if not minigameId then
        print("/startminigame <id>")
        print("vault_door, door_1, door_2")
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
    end)
end)

DebugCommand("heist:door", function()
    if not CurrentHeist or (CurrentHeist.state ~= HeistStates.ENTRY and CurrentHeist.state ~= HeistStates.VAULT_LOCKED) then
        print("Player is not in a Heist or not in entry/vault_locked states")
        return
    end

    if not CurrentHeist.doors and not CurrentHeist.vault then
        print("No access to current doors")
    end

    local door = findClosestDoor(CurrentHeist.doors)

    if not door then
        print("No bank door nearby")
        return
    end

    TriggerCallback("StartMinigame", function(result)
        if result.status ~= "success" then
            print("Error: " .. (result.message or "Unknown"))
            return
        end

        activeMinigame = result.data

        if result.data.minigameType == "lockpick" then
            print(string.format("Lockpick %s (Attempts left: %d) /submitminigame %s <angle>", door.id,
                result.data.attemptsRemaining, door.id))
        else
            print(string.format("Minigame %s ready (Attempts left: %d)", door.id, result.data.attemptsRemaining))
        end
    end, door.id)
end)

DebugCommand("heist:vault", function()
    if not CurrentHeist or CurrentHeist.state ~= HeistStates.VAULT_LOCKED then
        print("Player is not in a Heist or vault is not locked")
        return
    end

    if not CurrentHeist.vault or not CurrentHeist.vault.location then
        print("No access to current vault")
        return
    end

    local vault = findClosestDoor({
        {
            id = "vault_door",
            location = CurrentHeist.vault.location
        }
    })

    if not vault then
        print("No bank vault nearby")
        return
    end

    TriggerCallback("StartMinigame", function(result)
        if result.status ~= "success" then
            print("Error: " .. (result.message or "Unknown"))
            return
        end

        activeMinigame = result.data

        if result.data.minigameType == "lockpick" then
            print(string.format("Lockpick %s (Attempts left: %d) /submitminigame %s <angle>", vault.id,
                result.data.attemptsRemaining, vault.id))
        else
            print(string.format("Minigame %s ready (Attempts left: %d)", vault.id, result.data.attemptsRemaining))
        end
    end, vault.id)
end)

DebugCommand("submitminigame", function(commandArgs)
    local minigameId = commandArgs[1]

    if not minigameId then
        print("submitminigame <id> <attempt>")
        return
    end

    local args = {}

    for i = 2, #commandArgs do
        table.insert(args, commandArgs[i])
    end

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

        if data.solved then
            activeMinigame = nil
            print("Solved!")
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
                data.progress.correct,
                data.progress.present,
                data.attemptsRemaining
            ))
        elseif activeMinigame.minigameType == "lockpick" then
            print(string.format(
                "Diff: %d (%s) | Left: %d",
                data.progress.difference,
                data.progress.hint,
                data.attemptsRemaining
            ))
        end
    end, minigameId, attempt)
end)

RegisterClientEvent("HeistDoorOpened", function(data)
    if not data then
        return
    end

    print(string.format("[Heist] Door %s opened by %s", data.doorId or "unknown", data.openedBy or "unknown"))
end)
