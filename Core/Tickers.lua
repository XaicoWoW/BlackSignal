-- Core/Tickers.lua
-- @module Tickers
-- @alias Tickers
-- Timer system using AceTimer-3.0 with backward compatibility layer

local BS = _G.BS
local AceTimer = LibStub("AceTimer-3.0")

-------------------------------------------------
-- AceTimer-3.0 Integration
-------------------------------------------------

-- Use the table created by Init.lua, don't create a new one
local Tickers = BS.Tickers

--- Store active timers using AceTimer handles
-- Keys are the owner objects, values are the timer handles
Tickers._timers = {}

-------------------------------------------------
-- Backward Compatibility API
-------------------------------------------------

--- Register a ticker for a specific owner
-- Uses AceTimer-3.0 internally while maintaining the old API
--- @param owner any The owner of the ticker (typically the module object)
--- @param interval number The interval in seconds
--- @param func function The function to call on each tick
--- @return handle timerHandle The AceTimer handle (can be used with CancelTimer)
function Tickers:Register(owner, interval, func)
    -- Stop any existing timer for this owner
    self:Stop(owner)

    -- Create a new repeating timer using AceTimer
    -- We need to handle the function call properly
    local handle

    -- Create a wrapper function that calls the user's function
    local wrapper = function()
        if func then
            func()
        end
    end

    -- Use AceTimer to schedule the repeating timer
    -- The handle is stored for cancellation later
    handle = AceTimer.ScheduleRepeatingTimer(BS.Addon or BS, wrapper, interval)

    -- Store the handle associated with the owner
    self._timers[owner] = handle

    return handle
end

--- Stop and remove a ticker for a specific owner
--- @param owner any The owner of the ticker
function Tickers:Stop(owner)
    local handle = self._timers[owner]

    if handle then
        -- Cancel the timer using AceTimer
        AceTimer.CancelTimer(BS.Addon or BS, handle)
        self._timers[owner] = nil
    end
end

--- Check if an owner has an active ticker
--- @param owner any The owner to check
--- @return boolean True if the owner has an active ticker
function Tickers:IsRunning(owner)
    return self._timers[owner] ~= nil
end

--- Get the handle for a specific owner's ticker
--- @param owner any The owner of the ticker
--- @return handle|nil The timer handle, or nil if no timer exists
function Tickers:GetHandle(owner)
    return self._timers[owner]
end

-------------------------------------------------
-- Advanced AceTimer Features (New API)
-------------------------------------------------

--- Schedule a one-shot timer
--- @param delay number Delay in seconds before the callback fires
--- @param callback function|string The callback function or method name
--- @param ... any Optional arguments to pass to the callback
--- @return handle timerHandle The AceTimer handle
function Tickers:ScheduleOnce(delay, callback, ...)
    return AceTimer.ScheduleTimer(BS.Addon or BS, callback, delay, ...)
end

--- Schedule a repeating timer with more control
--- @param delay number Delay between each callback execution
--- @param callback function|string The callback function or method name
--- @param ... any Optional arguments to pass to the callback
--- @return handle timerHandle The AceTimer handle
function Tickers:ScheduleRepeating(delay, callback, ...)
    return AceTimer.ScheduleRepeatingTimer(BS.Addon or BS, callback, delay, ...)
end

--- Cancel a timer by handle
--- @param handle handle The timer handle to cancel
function Tickers:Cancel(handle)
    AceTimer.CancelTimer(BS.Addon or BS, handle)
end

--- Cancel all timers for a specific owner
--- @param owner any The owner whose timers should be cancelled
function Tickers:CancelAll(owner)
    self:Stop(owner)
end

-------------------------------------------------
-- Cleanup on Disable
-------------------------------------------------

--- Cancel all active tickers (for addon shutdown)
function Tickers:CancelAllTimers()
    for owner, handle in pairs(self._timers) do
        if handle then
            AceTimer.CancelTimer(BS.Addon or BS, handle)
        end
    end
    self._timers = {}
end

-------------------------------------------------
-- Integration with BlackSignal Lifecycle
-------------------------------------------------

-- Register cleanup on addon disable (if using AceAddon properly)
if BS.Addon and BS.Addon.OnDisable then
    local originalOnDisable = BS.Addon.OnDisable
    function BS.Addon:OnDisable()
        -- Cancel all tickers when addon is disabled
        Tickers:CancelAllTimers()
        -- Call original OnDisable if it exists
        if originalOnDisable then
            originalOnDisable(self)
        end
    end
end

return Tickers
