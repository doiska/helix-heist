if not Config.Debug then
    return
end

local Console = GetActorByTag('HConsole')
local commands = {}

function DebugCommand(name, cb)
    print("Registering " .. name .. " command")
    local commandInstance = Console:FindCommand(name)

    if commandInstance then
        Console:UnregisterCommand(commandInstance)
    end

    Console:RegisterCommand(name, name, nil, {
        HWorld,
        function(_, _, args)
            cb(args)
        end
    })
end

function onShutdown()
    for _, command in ipairs(commands) do
        local commandInstance = Console:FindCommand(command)
        Console:UnregisterCommand(commandInstance)
    end
end
