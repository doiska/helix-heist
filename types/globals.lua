---@class Rotator
---@field pitch number
---@field yaw number
---@field roll number

---@type fun(pitch: number, yaw: number, roll: number): Rotator
Rotator = Rotator


---@class Vector
---@field X number
---@field Y number
---@field Z number

---@type fun(X: number, Y: number, Z: number): Vector
Vector = Vector


---@class Timer
Timer = {}

---@param callback fun()
---@param milliseconds number
function Timer.SetTimeout(callback, milliseconds) end

---@param intervalId string
function Timer.ClearInterval(intervalId) end

---@param intervalId string
function Timer.ClearTimeout(intervalId) end
