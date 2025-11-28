---@class BankStartConfig
---@field minPlayers integer
---@field minPoliceOfficers integer

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

---@class BankMinigameConfig
---@field type string -- "pattern", "lockpick", "drill" -- lua lacks unions :()
---@field pattern BankMinigamePatternConfig|nil

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
---@field condition string              -- "radius" | "police"
---@field radius BankEscapeRadiusConfig|nil
---@field police BankEscapePoliceConfig|nil

---@class BankConfig
---@field label string
---@field start BankStartConfig
---@field security BankSecurityConfig
---@field vault BankVaultConfig
---@field escape BankEscapeConfig

---@alias BankCfg table<string, BankConfig>

---@class Config
---@field Banks BankCfg
