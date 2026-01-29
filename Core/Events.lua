-- Core/Events.lua
local BS = _G.BS

_G.BS_EventFrame = _G.BS_EventFrame or CreateFrame("Frame")
local f = _G.BS_EventFrame

f:SetScript("OnEvent", function(_, event, ...)
  for _, module in pairs(BS.modules) do
    if module and module.events and module.events[event] then
      module.events[event](module, ...)
    end
  end
end)

-- Eventos base
f:RegisterEvent("PLAYER_LOGIN")
f:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
f:RegisterEvent("TRAIT_CONFIG_UPDATED")
f:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED")

-- Core module: carga módulos al login
BS.modules.__core = BS.modules.__core or {
  name = "__core",
  enabled = true,
  events = {
    PLAYER_LOGIN = function()
      BS:LoadModules()
    end,
  },
}