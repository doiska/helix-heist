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

-- TODO: update target, idk what type source is in helix
---@param event string
---@param source string
---@param ... any
function TriggerClientEvent(event, source, ...) end

---@param event string
---@param ... any
function RegisterClientEvent(event, ...)

end

---@param event string
---@param callback fun(source: any, ...): any
function RegisterCallback(event, callback)

end

---@param event string
---@param ... any
function TriggerCallback(event, ...) end
