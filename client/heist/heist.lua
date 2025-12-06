---@class ClientHeist
---@field id string
---@field state HeistStates
---@field loot table
---@field doors? { id: string, location: Vector }[]
---@field vault? { location: Vector, loot: { id: string, location: Vector }[] }
---
---@type ClientHeist | nil
local CurrentHeist = nil

-- Break this into a table with functions like HeistUI.ShowLobby and handle indexes, etc
local HeistUI = WebUI("heist-ui", "heist/ui/dist/index.html", 0)

HeistUI.Browser.OnLoadCompleted:Add(HeistUI.Browser, function()
    HeistUI:SendEvent('Loaded')
    BindHeistUIEvents()
end)

RegisterClientEvent("HeistUpdate", function(newHeistState)
    if not newHeistState or newHeistState.state == "FAILED" or newHeistState.state == "COMPLETE" then
        CurrentHeist = nil
        return
    end

    CurrentHeist = newHeistState

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

    HeistUI:SendEvent('HeistUpdate', newHeistState)
end)

function onShutdown()
    if HeistUI then
        HeistUI:Destroy()
    end
end

_G.HeistUI = HeistUI
_G.CurrentHeist = CurrentHeist
