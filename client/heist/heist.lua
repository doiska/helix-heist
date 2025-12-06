---@class ClientHeist
---@field id string
---@field state string
---@field loot table
---@field doors? { id: string, location: Vector }[]
---@field vault? { location: Vector, loot: { id: string, location: Vector }[] }
CurrentHeist = {}
HeistUI = WebUI("heist-ui", "heist/ui/dist/index.html", 0)

HeistUI.Browser.OnLoadCompleted:Add(HeistUI.Browser, function()
    HeistUI:SendEvent('Loaded')
end)

RegisterClientEvent("HeistUpdate", function(data)
    if not data or data.state == "CLEANUP" then
        CurrentHeist = nil
        return
    end

    CurrentHeist = {
        id = data.heistId,
        state = data.state,
        doors = data.doors,
        vault = data.vault
    }

    if CurrentHeist.state == HeistStates.ENTRY and CurrentHeist.doors then
        for _, door in pairs(CurrentHeist.doors) do
            exports['qb-target']:AddTargetEntity(door.actor.Object, {
                distance = 5000,
                options = {
                    {
                        label = "Start lockpick",
                        icon = "fas fa-lock",
                        event = "client.StartMinigame",
                        doorId = door.id
                    },
                }
            })
        end
    end

    HeistUI:SendEvent('HeistUpdate', data)
end)

function onShutdown()
    if HeistUI then
        HeistUI:Destroy()
    end
end

_G.HeistUI = HeistUI
_G.CurrentHeist = CurrentHeist
