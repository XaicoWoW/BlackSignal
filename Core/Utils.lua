-- Core/Utils.lua
local BS = _G.BS

function BS:IsValidNumber(v)
    return v ~= nil and type(v) == "number"
end
