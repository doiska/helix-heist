-- This code is commented because I haven't made any visibility toggle yet.

-- local UI = WebUI("heist-ui", "main/ui/dist/index.html", 1)

-- UI.Browser.OnLoadCompleted:Add(UI.Browser, function()
--     UI:SendEvent('Loaded')
-- end)

-- -- this function will relay events that come from the UI (registered) directly to the server, without having to re-emit through the client
-- -- it works like RegisterCallback but as if you registered on server
-- -- has a amazing DX because you could make minigame attemps and get feedback instantly
-- -- few flaws: no ratelimit, weak error handling
-- function UiServerCallbackProxy(event)
--     UI:RegisterEventHandler(event, function(...)
--         TriggerCallback(event, function(result)
--             local callbackName = event .. "_callback"

--             if result == nil or result.status == nil then
--                 UI:SendEvent(callbackName, {
--                     status = "error",
--                     message = "No response"
--                 })
--                 return
--             end

--             if result.status == "success" then
--                 UI:SendEvent(callbackName, {
--                     status = "success",
--                     data = result.data or nil
--                 })
--             elseif result.status == "error" then
--                 UI:SendEvent(callbackName, {
--                     status = "error",
--                     message = result.message
--                 })
--             end
--         end, ...)
--     end)
-- end

-- UiServerCallbackProxy('GetActiveHeistInfo')
-- UiServerCallbackProxy('JoinHeist')
-- UiServerCallbackProxy('CreateHeist')
-- UiServerCallbackProxy('LeaveHeist')
-- UiServerCallbackProxy('GetUserHeistState')
-- UiServerCallbackProxy('StartMinigame')
-- UiServerCallbackProxy('SubmitMinigameAttempt')

-- RegisterClientEvent('HeistUpdate', function(data)
--     if not UI then
--         return
--     end

--     UI:SendEvent('HeistUpdate', data)
-- end)

-- function onShutdown()
--     if UI then
--         UI:Destroy()
--     end
-- end
