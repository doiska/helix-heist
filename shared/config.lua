Config = {}

Config.Debug = {
    enabled = true,
    disableItemRequirement = true,
    disableMinPlayersRequirement = true
}

Config.Persistence = {
    database = {}
}

---@type BankCfg
Config.Banks = {
    central = {
        id = "central",
        label = "Central Bank",
        start = {
            minPlayers = 4,        -- ignored in debug mode
            minPoliceOfficers = 2, -- ignored in debug mode
            requiredItems = {
                { id = "lockpick", amount = 5 },
                { id = "laptop",   amount = 1 }
            },
            location = Vector(-4700, 14520.0, -390.0)
        },
        security = {
            doors = {
                {
                    entity = "/QuietRuntimeEditor/UserContent/StaticMeshes/Primitives/SM_Cube.SM_Cube",
                    lockType = "lockpick",
                    location = Vector(-5530.526, 15580.0, -330.0),
                    rotation = Rotator(0, 0, 0),
                    scale = Vector(1.05, 0.04, 2.28),
                    interact = {
                        Text = "Open Garage",
                        SubText = "Press E to start lockpicking",
                        Input = '/Game/Input/Actions/IA_Interact.IA_Interact',
                    }
                },
                {
                    entity = "/QuietRuntimeEditor/UserContent/StaticMeshes/Primitives/SM_Cube.SM_Cube",
                    lockType = "lockpick",
                    location = Vector(-4720.526, 15660.0, -320.0),
                    rotation = Rotator(0, 0, 0),
                    scale = Vector(1.05, 0.04, 2.12),
                    interact = {
                        Text = "Open Garage",
                        SubText = "Press E to start lockpicking",
                        Input = '/Game/Input/Actions/IA_Interact.IA_Interact',
                    }
                },
            },
            alarm = {
                silentAlarmChance = 30,
                silentAlarmDelayInSeconds = 10
            }
        },
        vault = {
            location = Vector(59.63, 289.30, 91.65),
            openDuration = 40, -- duration that the vault will stay open
            policeAutoArriveInSeconds = 10,
            minigame = {
                type = "pattern",
                pattern = {
                    sequenceLength = 5,
                    timeLimitInSeconds = 30,
                    maxAttempts = 999
                }
            },
            loot = {
                {
                    entity = "/Game/QBCore/Meshes/SM_ATM.SM_ATM",
                    location = Vector(610.0, -90.0, 0.0),
                    maxUses = 1,
                    channelingTimeInSeconds = 5,
                    items = {
                        { id = "cash",        amount = 5000 },
                        { id = "bank_titles", amount = 2 } -- i havent robbed a bank, yet. so im not sure what items to give
                    }
                }
            }
        },
        escape = {
            condition = "police", -- Can be radius and police
            radius = {
                distanceFromTheBank = 40,
            },
            police = {
                durationInSeconds = 15
            }
        }
    }
}
