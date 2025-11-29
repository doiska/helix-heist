local ui = WebUI("ui", "ui.html", 0)

function UiServerCallbackProxy(event)
    ui:Subscribe(event, function(...)
        TriggerCallback(event, function(result)
            ui:CallFunction(event .. '_callback', {
                status = "success",
                data = result
            })
        end, ...)
    end)
end

UiServerCallbackProxy('GetActiveHeistInfo')
UiServerCallbackProxy('JoinHeist')
UiServerCallbackProxy('LeaveHeist')
UiServerCallbackProxy('GetUserHeistState')

RegisterClientEvent('HeistPlayerJoined', function(data)
    ui:SendEvent('HeistPlayerJoined', data)
end)

RegisterClientEvent('HeistPlayerLeft', function(data)
    ui:SendEvent('HeistPlayerLeft', data)
end)
