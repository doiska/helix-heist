local UI = WebUI("heist-ui", "main/ui/dist/index.html", 1)

-- I'm not sure if that's the right usage because theres no docs about commands yet :/
local Console = GetActorByTag('HConsole')

-- Console:RegisterCommand("heist:ui", "Opens heist ui", nil, {
--     HWorld,
--     function()
--         print("Heist UI called")
--         UI = WebUI("heist-ui", "main/ui/dist/index.html", 1)
--         -- I wanted to create it on-demand but doesn't seem possible yet, or at least doesn't seem to be working.
--         UI.Browser.OnLoadCompleted:Add(UI.Browser, function()

--         end)
--     end
-- })
--

-- this function will relay events that come from the UI (registered) directly to the server, without having to re-emit through the client
-- it works like RegisterCallback but as if you registered on server
-- few flaws: no ratelimit, weak error handling
function UiServerCallbackProxy(event)
    UI:RegisterEventHandler(event, function(...)
        print("Received " .. event)

        TriggerCallback(event, function(result)
            local callbackName = event .. "_callback"

            if result == nil or result.status == nil then
                UI:SendEvent(callbackName, {
                    status = "error",
                    message = "No response"
                })
                return
            end

            if result.status == "success" then
                UI:SendEvent(callbackName, {
                    status = "success",
                    data = result.data or nil
                })
            elseif result.status == "error" then
                UI:SendEvent(callbackName, {
                    status = "error",
                    message = result.message
                })
            end
        end, ...)
    end)
end

UiServerCallbackProxy('GetActiveHeistInfo')
UiServerCallbackProxy('JoinHeist')
UiServerCallbackProxy('CreateHeist')
UiServerCallbackProxy('LeaveHeist')
UiServerCallbackProxy('GetUserHeistState')

RegisterClientEvent('HeistUpdate', function(data)
    if not UI then
        return
    end

    UI:SendEvent('HeistUpdate', data)
end)

function onShutdown()
    if UI then
        UI:Destroy()
    end
end
