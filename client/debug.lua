if not Config.Debug.enabled then
    return
end

-- Not sure if there's a better approach for this, like wrapping in a registerCommands() fn, load order or something else.
if not DebugCommand then
    Timer.Wait(1000)
end

local LOOT_INTERACT_RANGE = 500.0

local function getLootAtIndex(index)
    if not CurrentHeist or not CurrentHeist.vault or not CurrentHeist.vault.loot then
        return nil
    end

    return CurrentHeist.vault.loot[index]
end

local function isVaultOpen()
    return CurrentHeist and CurrentHeist.state == HeistStates.VAULT_OPEN
end

DebugCommand("heist", function()
    TriggerCallback("GetActiveHeistsInfo", function(lobby)
        if not lobby or not lobby.status then
            print("Something went wrong.")
            return
        end

        if lobby.status == 'error' then
            print(lobby.message or "Response returned but no content.")
            return
        end

        HeistUI:SendEvent("ShowLobby", lobby)
        HeistUI:SetInputMode(1)
    end)
end)

DebugCommand("heist:join", function(args)
    if not args or #args ~= 1 then
        print("Use heist:join <heistId>")
        return
    end

    local heistId = args[1]

    if not heistId then
        print("No heist id found")
        return
    end

    TriggerCallback("JoinHeist", function(result)
        if result.status == "success" then
            print("Joined heist!")
        elseif result.status == "error" then
            print(result.message)
        end
    end, heistId)
end)

DebugCommand("heist:leave", function()
    TriggerCallback("LeaveHeist")
end)

DebugCommand("heist:loot-collect", function(args)
    local index = tonumber(args and args[1])

    if not index then
        print("Use heist:loot-collect <lootIndex>")
        return
    end

    if not isVaultOpen() then
        print("Vault is not open")
        return
    end

    local loot = getLootAtIndex(index)

    if not loot or not loot.location then
        print("Loot location not available")
        return
    end

    local playerLocation = GetPlayerLocation()

    if not playerLocation then
        print("Unable to find your character")
        return
    end

    local distance = HELIXMath.VectorDistance(playerLocation, loot.location)

    print("Distance from the loot " .. distance)

    if distance > LOOT_INTERACT_RANGE then
        print("Move closer to the loot")
        return
    end

    TriggerCallback("StartLootCollection", function(result)
        if result.status == "success" then
            local duration = result.duration or 0
            print(string.format("Collecting loot #%d (%d seconds)", index, duration))
        elseif result.status == "error" then
            print(result.message or "Unable to start loot collection")
        end
    end, index)
end)

DebugCommand("heist:loot-collect-stop", function(args)
    local index = tonumber(args and args[1])

    if not index then
        print("Use heist:loot-collect-stop <lootIndex>")
        return
    end

    if not isVaultOpen() then
        print("Vault is not open")
        return
    end

    local loot = getLootAtIndex(index)

    if not loot or not loot.location then
        print("Loot location not available")
        return
    end

    local playerLocation = GetPlayerLocation()

    if not playerLocation then
        print("Unable to find your character")
        return
    end

    local distance = HELIXMath.VectorDistance(playerLocation, loot.location)

    if distance > LOOT_INTERACT_RANGE then
        print("Move closer to the loot")
        return
    end

    TriggerCallback("StopLootCollection", function(result)
        if result.status == "success" then
            print(string.format("Stopped collecting loot #%d", index))
        elseif result.status == "error" then
            print(result.message or "Unable to stop loot collection")
        end
    end, index)
end)
