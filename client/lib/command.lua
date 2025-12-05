if not Config.Debug then
    return
end

local Console = GetActorByTag('HConsole')

-- this is a hack to normalize the args, I'm not sure why the args are being treated as table or single arg sometimes
local function normalizeArgs(...)
    local argc = select("#", ...)

    if argc == 1 then
        local first = ...

        if type(first) == "table" then
            return first
        end

        local length = nil

        if first ~= nil and type(first.Length) == "function" then
            length = first:Length()
        elseif first ~= nil and type(first.Num) == "function" then
            length = first:Num()
        end

        if length and length > 0 then
            local out = {}

            for i = 1, length do
                out[i] = first[i]
            end

            return out
        end
    end

    return { ... }
end

function DebugCommand(name, cb)
    print("Registering " .. name .. " command")
    local commandInstance = Console:FindCommand(name)

    if commandInstance then
        Console:UnregisterCommand(commandInstance)
    end

    Console:RegisterCommand(name, name, nil, {
        HWorld,
        function(_, _, ...)
            cb(normalizeArgs(...))
        end
    })
end
