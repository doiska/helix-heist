if not Config.Debug then
    return
end

while not DebugCommand do
    Wait(50)
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

DebugCommand("heist:join", function(args)
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
    TriggerCallback("LeaveHeist", function(result)
        if result.status == "success" then
            print("Left heist")
        elseif result.status == "error" then
            print(result.message)
        end
    end)
end)
