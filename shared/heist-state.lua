---@enum HeistStates
HeistStates = {
    IDLE = "IDLE",                 -- leader still waiting for players
    PREPARED = "PREPARED",         -- minPlayers joined, ready to start
    ENTRY = "ENTRY",               -- heist started, they need to open doors
    VAULT_LOCKED = "VAULT_LOCKED", -- all doors opened, vault locked
    VAULT_OPEN = "VAULT_OPEN",     -- vault unlocked, players can enter (I think this state is redundant because of "LOOTING")
    ESCAPE = "ESCAPE",             -- vault auto-close after X seconds
    COMPLETE = "COMPLETE",         -- players have completed the heist by escaping from radius
    FAILED = "FAILED",             -- players have somehow failed: ran out of time
    CLEANUP = "CLEANUP"            -- everything cleaned up, removing players
}
