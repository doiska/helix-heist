---@class BankStartConfig
---@field minPlayers integer
---@field minPoliceOfficers integer
---@field requiredItems table{ id: string, amount: integer }[]
---@field location Vector

---@class BankDoor
---@field entity string
---@field lockType string|nil
---@field location Vector
---@field rotation Rotator

---@class BankAlarmConfig
---@field silentAlarmChance integer
---@field silentAlarmDelayInSeconds number

---@class BankSecurityConfig
---@field doors BankDoor[]
---@field alarm BankAlarmConfig

---@class BankMinigamePatternConfig
---@field sequenceLength integer
---@field timeLimitInSeconds number
---@field maxAttempts integer

---@class BankMinigameLockpickConfig
---@field maxAttempts integer
---@field timeLimitInSeconds number

---@class BankMinigameConfig
---@field type string -- "pattern", "lockpick", "drill" -- lua lacks unions :(
---@field pattern BankMinigamePatternConfig|nil
---@field lockpick BankMinigameLockpickConfig|nil

---@class MinigameProgress
---@field attempts any[]
---@field attemptsCount number
---@field exhausted boolean
---@field lockedBy Player?
---@field lockedAt number?

---@class Minigame
---@field id string
---@field type string                    -- "vault" | "door"
---@field minigameType string            -- "pattern" | "lockpick"
---@field answer any
---@field solved boolean
---@field solvedBy string?
---@field maxAttempts number
---@field timeLimit number
---@field progress MinigameProgress

---@class PlayerMinigameProgress
---@field attempts any[]
---@field attemptsCount number
---@field completed boolean

---@class BankLootEntry
---@field entity string
---@field location Vector
---@field maxUses integer
---@field channelingTimeInSeconds number

---@class BankVaultConfig
---@field location Vector
---@field openDuration number
---@field policeAutoArriveInSeconds number
---@field minigame BankMinigameConfig
---@field loot BankLootEntry[]

---@class BankEscapeRadiusConfig
---@field distanceFromTheBank number

---@class BankEscapePoliceConfig
---@field durationInSeconds number

---@class BankEscapeConfig
---@field condition string              -- "radius"
---@field radius BankEscapeRadiusConfig|nil
---@field police BankEscapePoliceConfig|nil

---@class BankConfig
---@field id string
---@field label string
---@field start BankStartConfig
---@field security BankSecurityConfig
---@field vault BankVaultConfig
---@field escape BankEscapeConfig

---@alias BankCfg table<string, BankConfig>

---@class Config
---@field Banks BankCfg
