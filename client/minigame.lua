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
            HeistUI:SetInputMode(1)
        end, ...)
    end
)

RegisterClientEvent("client.StartMinigame", function(data)
    if not data.doorId then
        return
    end

    TriggerCallback("StartMinigame", function(result)
        if result.status ~= "success" then
            print("Error: " .. (result.message or "Unknown"))
            return
        end

        HeistUI:SendEvent("StartMinigame", result)
        HeistUI:SetInputMode(1)
    end, data.doorId)
end)

RegisterClientEvent("client.HideMinigame", function()
    HeistUI:SendEvent("HideMinigame")
    HeistUI:SetInputMode(0)
end)

RegisterClientEvent("client.HeistMinigameTimeout", function(data)
    HeistUI:SendEvent("HideMinigame")
    HeistUI:SetInputMode(0)
end)
