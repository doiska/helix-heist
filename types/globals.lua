---@class Rotator
---@field pitch number
---@field yaw number
---@field roll number

---@param pitch number
---@param yaw number
---@param roll number
---@return Rotator
function Rotator(pitch, yaw, roll) end

---@class Vector
---@field X number
---@field Y number
---@field Z number

---@param X number
---@param Y number
---@param Z number
---@return Vector
function Vector(X, Y, Z) end

---@class Timer
Timer = {}

---@param callback function
---@param milliseconds number
function Timer.SetTimeout(callback, milliseconds) end
