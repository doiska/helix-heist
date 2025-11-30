function GetPlayerLocation()
    local player = GetLocalPlayer()

    if not player then
        print("Player not found")
        return nil
    end

    local character = GetPlayerPawn(player)

    if not character then
        return
    end

    return GetEntityCoords(character)
end
