---@class JSON
JSON = JSON

--- Parses a JSON string into a Lua table.
---@param json string
---@return table
function JSON.parse(json)
end

--- Serializes a Lua table into a JSON string.
---@param table table
---@return string
function JSON.stringify(table)
end

--@class HELIXTable
HELIXTable = HELIXTable

--- Reduces a table to a single value using a reducer function.
---@param table table
---@param reducer function
---@param initial any
---@return any
function HELIXTable.reduce(table, reducer, initial) end
