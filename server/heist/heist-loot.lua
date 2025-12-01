HeistLoot = {}

---@param heist BankHeist
function HeistLoot.init(heist)
    heist.lootTimers = heist.lootTimers or {}

    heist.loot = {
        status = {},
        playerTotals = {}
    }

    if heist.config.vault and heist.config.vault.loot then
        for i, lootConfig in ipairs(heist.config.vault.loot) do
            heist.loot.status[i] = {
                maxUses = lootConfig.maxUses or 1,
                uses = 0,
                amount = math.random(2000, 6000),
                currentUser = nil
            }
        end
    end
end

---@param heist BankHeist
---@param lootIndex number
---@param playerId string
function HeistLoot.start(heist, lootIndex, playerId)
    local loot = heist.loot.status[lootIndex]

    if not loot or loot.uses >= loot.maxUses then
        return { status = "error", message = "Loot not available" }
    end

    if loot.currentUser then
        return { status = "error", message = "Someone else is collecting" }
    end

    loot.currentUser = playerId

    local duration = heist.config.vault.loot[lootIndex].channelingTimeInSeconds

    local timerId = Timer.SetTimeout(function()
        HeistLoot.complete(heist, lootIndex, playerId)
    end, duration * 1000)

    heist.lootTimers[lootIndex] = timerId

    return { status = "success", duration = duration }
end

---@param heist BankHeist
---@param lootIndex number
---@param playerId string
function HeistLoot.abort(heist, lootIndex, playerId)
    local loot = heist.loot.status[lootIndex]

    if not loot or loot.currentUser ~= playerId then
        return { status = "error", message = "Loot not available" }
    end

    if heist.lootTimers[lootIndex] then
        Timer.ClearTimeout(heist.lootTimers[lootIndex])
        heist.lootTimers[lootIndex] = nil
    end

    loot.currentUser = nil
    return { status = "success", message = "Loot collection aborted" }
end

---@param heist BankHeist
---@param lootIndex number
---@param playerId string
function HeistLoot.complete(heist, lootIndex, playerId)
    local loot = heist.loot.status[lootIndex]

    if not loot then
        return false, "Loot no longer exists"
    end

    if loot.currentUser ~= playerId then
        return false, "Loot is being collected by another player"
    end

    -- todo: make it configurable
    local amount = math.random(1000, 5000)

    loot.uses = loot.uses + 1
    loot.currentUser = nil

    heist.loot.playerTotals[playerId] = (heist.loot.playerTotals[playerId] or 0) + amount
    heist.lootTimers[lootIndex] = nil

    return true
end
