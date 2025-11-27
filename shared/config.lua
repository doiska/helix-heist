Config = {}

Config.Debug = true -- Disables start requirements

Config.Persistence = {
    type = "json",
    json = {
        file = "heist.json"
    },
    database = {

    }
}



---@type BankCfg
Config.Banks = {
    central = {
        label = "Central Bank",
        start = {
            minPlayers = 4,        -- Ignored in debug mode
            minPoliceOfficers = 2, -- Ignored in debug mode
        },
        security = {
            doors = {
                {
                    entity = "/Game/HelixDoors/Blueprints/BP_Door_Rotating.BP_Door_Rotating_C",
                    lockType = nil, -- Laptop to solve the game
                    location = Vector(1119.21, -688.387, 100.0),
                    rotation = Rotator(0, 0, 0)
                },
            },
            alarm = {
                silentAlarmChance = 30,
                silentAlarmDelayInSeconds = 10
            }
        },
        vault = {
            location = Vector(1119.21, -688.387, 100.0),
            openDuration = 3 * 60, -- Duration that the vault will stay open
            policeAutoArriveInSeconds = 3 * 60,
            minigame = {
                type = "pattern",
                pattern = {
                    sequenceLength = 5,
                    timeLimitInSeconds = 30,
                    maxAttempts = 5
                }
            },
            loot = {
                {
                    entity = "/Game/QBCore/Meshes/SM_ATM.SM_ATM",
                    location = Vector(1119.21, -688.387, 100.0),
                    maxUses = 1,
                    channelingTimeInSeconds = 30
                },
                {
                    entity = "",
                    location = Vector(1119.21, -688.387, 100.0),
                    maxUses = 1,
                    channelingTimeInSeconds = 5
                }
            }
        },
        escape = {
            condition = "radius", -- Can be radius and police
            radius = {
                distanceFromTheBank = 40,
            },
            police = {
                durationInSeconds = 45 * 60
            }
        }
    }
}
