HeistDoors = {}

function HeistDoors.init(heist)
    heist.doors = heist.doors or {}

    if heist.config.security and heist.config.security.doors then
        for i, door in ipairs(heist.config.security.doors) do
            local doorActor = StaticMesh(door.location, door.rotation, door.entity)
            doorActor:SetActorScale3D(door.scale or Vector(1, 1, 1))

            local doorId = "door_" .. i

            heist.doors[doorId] = {
                id = doorId,
                config = door,
                opened = false,
                openedBy = nil,
                actor = doorActor
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

function HeistDoors.getDoors(heist)
    return heist.doors or {}
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

    if door.actor ~= nil and door.actor:IsValid() then
        DeleteEntity(door.actor)
        door.mesh = nil
    end

    heist:broadcastEvent("HeistDoorOpened", {
        heistId = heist.id,
        doorId = doorId,
        openedBy = playerId
    })

    if HeistDoors.areAllDoorsBypassed(heist) and heist:canTransitionTo(HeistStates.VAULT_LOCKED) then
        heist:transitionTo(HeistStates.VAULT_LOCKED)
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
        if door.actor and door.actor:IsValid() then
            DeleteEntity(door.actor)
        end
    end

    heist.doors = {}
end
