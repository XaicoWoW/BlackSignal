-- Core/Events.lua
-- @module Events
-- @alias Events

local BS = _G.BS;

BS.Events    = BS.Events or CreateFrame("Frame")

--- Event frame to handle and dispatch events to modules
local f = BS.Events

--- Table to track unit events and their filters
local unitEventFilters = {}

--- Register a unit event with a filter
--- @param event string The event to register
--- @param unit string The unit to filter for (e.g., "player", "target")
function f:RegisterUnitEvent(event, unit)
  -- Initialize the event filter table if needed
  if not unitEventFilters[event] then
    unitEventFilters[event] = {}
    -- Register the event with the frame
    f:RegisterEvent(event)
  end

  -- Track that we're interested in this unit for this event
  unitEventFilters[event][unit] = true
end

--- Original event dispatch (for non-unit events)
local function dispatchNormalEvent(event, ...)
  for _, module in pairs(BS.API.modules) do
    if module and module.events and module.events[event] then
      module.events[event](module, ...)
    end
  end
end

--- Event handler to dispatch events to modules with unit filtering
f:SetScript("OnEvent", function(_, event, ...)
  -- Check if this event has unit filters
  if unitEventFilters[event] then
    -- Get the first argument (the unit for UNIT_* events)
    local unit = ...

    -- Only dispatch if we're interested in this unit
    if unit and unitEventFilters[event][unit] then
      dispatchNormalEvent(event, ...)
    end
  else
    -- No unit filter, dispatch normally
    dispatchNormalEvent(event, ...)
  end
end)

--- Register events to the event frames
f:RegisterEvent("PLAYER_LOGIN")
f:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
f:RegisterEvent("TRAIT_CONFIG_UPDATED")
f:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED")

--- Core module to handle core events
BS.API.modules.__core = BS.API.modules.__core or {
  name = "__core",
  enabled = true,
  events = {
    PLAYER_LOGIN = function()
      BS.API:Load()
    end,
  },
}
