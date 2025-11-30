---@class Client
---@field GetLocalPlayer fun(): Player
Client = {}
function Client:GetLocalPlayer() end

---@class Player
---@field GetControlledCharacter fun(): Character

---@class Character
---@field GetLocation fun(): Vector
Character = {}
function Character:GetLocation() end
