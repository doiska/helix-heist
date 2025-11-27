---@enum CollisionType
--- Chooses the best setting automatically
CollisionType = {
    -- Standard collision based on channel settings
    Normal = 0,
    -- Only collides with static objects
    StaticOnly = 1,
    -- Ignores all collisions
    NoCollision = 2,
    -- Ignores player and NPCs, but collides with everything else
    IgnoreOnlyPawn = 3,
    -- Chooses the best setting automatically
    Auto = 4
}
