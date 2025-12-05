HeistDoors = {}

function HeistDoors.init(heist)
    heist.doors = heist.doors or {}

    if heist.config.security and heist.config.security.doors then
        for i, door in ipairs(heist.config.security.doors) do
            --
            -- StaticMesh(PawnCoords, Rotator(), Config.Prop.Mesh)
            local doorMesh = StaticMesh(door.location, door.rotation, door.entity)
            doorMesh:SetActorScale3D(door.scale or Vector(1, 1, 1))

            local doorId = "door_" .. i

            heist.doors[doorId] = {
                config = door,
                opened = false,
                openedBy = nil,
                mesh = doorMesh
            }
        end
    end
end

function HeistDoors.getDoorConfig(heist, doorId)
    local door = heist.doors and heist.doors[doorId]

    if not door then
        return nil
    end

    return door.config
end

function HeistDoors.getTotalDoors(heist)
    if not heist.config.security or not heist.config.security.doors then
        return 0
    end

    return #heist.config.security.doors
end

function HeistDoors.getClientDoors(heist)
    local clientDoors = {}

    for id, door in pairs(heist.doors or {}) do
        table.insert(clientDoors, {
            id = id,
            location = door.config.location
        })
    end

    return clientDoors
end

function HeistDoors.isDoorBypassed(heist, doorId)
    local door = heist.doors and heist.doors[doorId]

    if not door then
        return false
    end

    return door.opened == true
end

function HeistDoors.markDoorBypassed(heist, doorId, playerId)
    local door = heist.doors and heist.doors[doorId]

    if not door or door.opened then
        return
    end

    door.opened = true
    door.openedBy = playerId

    heist:broadcastEvent("HeistDoorOpened", {
        heistId = heist.id,
        doorId = doorId,
        openedBy = playerId
    })

    if HeistDoors.areAllDoorsBypassed(heist) and heist:canTransitionTo(HeistStates.VAULT_LOCKED) then
        heist:transitionTo(HeistStates.VAULT_LOCKED)
        heist:broadcastState()
    end
end

function HeistDoors.areAllDoorsBypassed(heist)
    local totalDoors = HeistDoors.getTotalDoors(heist)
    local openedDoors = 0

    if totalDoors == 0 then
        return true
    end

    for _, door in pairs(heist.doors) do
        if door.opened then
            openedDoors = openedDoors + 1
        end
    end

    return openedDoors >= totalDoors
end

function HeistDoors.cleanup(heist)
    for _, door in pairs(heist.doors) do
        if door.mesh and door.mesh:IsValid() then
            DeleteEntity(door.mesh)
        end
    end

    heist.doors = {}
end
