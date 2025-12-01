---@class ClientHeist
---@field id string
---@field state string
---@field doors? { id: string, location: Vector }[]
---@field vault? { location: Vector, loot: { id: string, location: Vector }[] }
CurrentHeist = {}

local function handleHeistUpdate(data)
    if not data or data.state == "CLEANUP" then
        CurrentHeist = nil
        print("Cleaned up client-side Heist state")
        return
    end

    CurrentHeist = {
        id = data.heistId,
        state = data.state,
        doors = data.doors,
        vault = data.vault
    }

    HELIXTable.Dump(CurrentHeist)
end

RegisterClientEvent("HeistUpdate", function(data)
    print("Received HeistUpdate")
    handleHeistUpdate(data)
end)

_G.CurrentHeist = CurrentHeist
