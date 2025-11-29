print("Starting Heist script")

local doors = {}

for i, bank in pairs(Config.Banks) do
    local bankName = Config.Banks[i].label
    print('Loading ' .. bankName)

    for _, door in ipairs(bank.security.doors) do
        print('Spawning door ' .. door.entity .. ' (' .. (door.lockType or 'no lock') .. ')')

        local SpawnTransform = Transform()
        SpawnTransform.Translation = door.location
        SpawnTransform.Rotation = door.rotation

        doors[#doors + 1] = Door(DoorType.Classic, SpawnTransform, door.entity, {
            bSupportsLocking = false,
            bStartLocked = true
        })
    end
end

function onShutdown()
    for _, value in ipairs(doors) do
        DeleteEntity(value)
    end
end
