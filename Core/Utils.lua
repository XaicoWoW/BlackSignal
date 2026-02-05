-- Core/Utils.lua
-- @module Utils
-- @alias Utils

-- Use the global BS table created by Init.lua
local BS = _G.BS

-- Use the table created by Init.lua, don't create a new one
local Utils = BS.Utils

--- Check if a value is a valid number
--- @param v any The value to check
--- @return boolean True if the value is a valid number, false otherwise
function Utils:IsValidNumber(v)
    return v ~= nil and type(v) == "number"
end

--- Check if a table has a specific key
--- @param t table The table to check
--- @param k any The key to look format
--- @return boolean True if the key exists in the table, false otherwise
function Utils:HasKey(t, k) return type(t) == "table" and t[k] ~= nil end
