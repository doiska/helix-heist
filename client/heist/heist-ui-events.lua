function BindHeistUIEvents()
    HeistUI:RegisterEventHandler(
        "ui.SubmitMinigameAttempt",
        function(...)
            TriggerCallback("SubmitMinigameAttempt", function(result)
                if result.status ~= "success" then
                    print("Error: " .. (result.message or "Unknown"))
                    return
                end

                if result.data and (result.data.solved or result.data.exhausted) then
                    HeistUI:SendEvent("HideMinigame")
                    HeistUI:SetInputMode(0)
                    return
                end

                HeistUI:SendEvent("MinigameAttemptResult", result)
            end, ...)
        end
    )

    HeistUI:RegisterEventHandler("ui.Close", function()
        HeistUI:SetInputMode(0)
    end)

    HeistUI:RegisterEventHandler(
        "ui.CreateHeist",
        function()
            TriggerCallback("CreateHeist")
        end
    )

    HeistUI:RegisterEventHandler(
        "ui.StartHeist",
        function()
            TriggerCallback("StartHeist")
        end
    )
end

_G.BindHeistUIEvents = BindHeistUIEvents
