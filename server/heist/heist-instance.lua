BankHeist = {}
BankHeist.__index = BankHeist

function BankHeist.new(id, config, leaderId)
    local self = setmetatable({}, BankHeist)

    self.id = id
    self.config = config
    self.state = HeistStates.IDLE
    self.participants = {
        leaderId
    }
    self.leader = leaderId
    self.timers = {}
    self.startTime = nil
    self.metadata = {
        alarmTriggered = false,
        policeNotified = false,
        vaultOpenTime = nil,
        doorsBypassed = {},
        minigameAttempts = 0,
        totalLootCollected = 0,
        failureReason = nil
    }

    self.lootStatus = {}
    if config.vault and config.vault.loot then
        for i, loot in ipairs(config.vault.loot) do
            self.lootStatus[i] = {
                collected = false,
                usesRemaining = loot.maxUses or 1,
                currentUser = nil,
                amount = 0
            }
        end
    end

    return self
end
