if not Config.Debug then
    return
end

RegisterClientEvent("HeistUpdate", function(...)
    print("Received HeistUpdate")
    HELIXTable.Dump(...)
end)

DebugCommand("heist:create", function(args)
    TriggerCallback("CreateHeist", function(result)
        if result.status == "success" then
            print("Created and joined heist!")
        elseif result.status == "error" then
            print(result.message)
        end
    end)
end)

DebugCommand("heist:start", function()
    TriggerCallback("StartHeist", function(result)
        if result.status == "success" then
            print("Started heist!")
        elseif result.status == "error" then
            print(result.message)
        end
    end)
end)

DebugCommand("heist:leave", function()
    TriggerCallback("LeaveHeist", function(result)
        if result.status == "success" then
            print("Left heist")
        elseif result.status == "error" then
            print(result.message)
        end
    end)
end)
