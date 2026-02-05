-- Modules/CombatTime/CombatTime.lua
-- @module CombatTime
-- @alias CombatTime
--
-- Tracks time spent in combat.
-- Shows a simple "mm:ss" timer ONLY while the player is in combat.
-- When leaving combat: hides and resets the timer to 00:00.
-- When entering combat: starts from 00:00.
-- Persists an all-time total (optional) into SavedVariables.

local BS = _G.BS

local _, BS = ...

-------------------------------------------------
-- Create as an Ace3 Module
-------------------------------------------------
-- BS.Addon is the main AceAddon created in Core/Init.lua
-- NewModule creates a child module that inherits all embedded libraries
local CombatTime = BS.Addon:NewModule("CombatTime", "AceEvent-3.0", "AceTimer-3.0")

-------------------------------------------------
-- Module Metadata (for BS.API compatibility)
-------------------------------------------------
CombatTime.name = "BS_CT"
CombatTime.label = "Combat Timer"
CombatTime.enabled = true
CombatTime.defaults = {
    enabled = true,
    x = 0,
    y = -120,
    fontSize = 20,
    font = "Fonts\\FRIZQT__.TTF",
    updateInterval = 1,
    persistTotal = true,
    totalSeconds = 0,
}

-------------------------------------------------
-- Register with BS.API (for Config panel compatibility)
-------------------------------------------------
BS.API:Register(CombatTime)

-------------------------------------------------
-- State
-------------------------------------------------
CombatTime.inCombat = false
CombatTime.combatStart = nil
CombatTime.totalSeconds = 0

-------------------------------------------------
-- Formatting
-------------------------------------------------
local function FormatMMSS(seconds)
    seconds = tonumber(seconds) or 0
    if seconds < 0 then seconds = 0 end
    seconds = math.floor(seconds + 0.5)
    local m = math.floor(seconds / 60)
    local s = seconds % 60
    return string.format("%02d:%02d", m, s)
end

-------------------------------------------------
-- UI
-------------------------------------------------

local function CalculateHeight(self)
    if not self.textFS or not self.db then return 30 end
    local fontSize = tonumber(self.db.fontSize) or 20
    return fontSize + 10
end

local function CalculateWidth(self)
    if not self.textFS or not self.db then return 100 end
    local fontSize = tonumber(self.db.fontSize) or 20
    return (fontSize * 4) + 20
end

local function EnsureUI(self)
    if self.frame and self.textFS then return end

    local displayFrame = CreateFrame("Frame", "BS_CombatTimeDisplay", UIParent)
    displayFrame:SetHeight(CalculateHeight(self))
    displayFrame:SetWidth(CalculateWidth(self))
    displayFrame:SetFrameStrata("LOW")
    displayFrame:Show()

    local statusText = displayFrame:CreateFontString(nil, "OVERLAY")
    statusText:SetPoint("CENTER")
    statusText:SetJustifyH("CENTER")
    statusText:SetTextColor(1, 1, 1, 1)

    self.frame = displayFrame
    self.textFS = statusText
end

local function ApplyPosition(self)
    if not self.frame or not self.db then return end
    self.frame:ClearAllPoints()
    self.frame:SetPoint("CENTER", UIParent, "CENTER", self.db.x or 0, self.db.y or -120)
end

local function ApplyFont(self)
    if not self.textFS or not self.db then return end
    self.textFS:SetFont(self.db.font, tonumber(self.db.fontSize) or 20, "OUTLINE")
end

-------------------------------------------------
-- Update
-------------------------------------------------
function CombatTime:Update()
    if not self.db or self.db.enabled == false then return end
    if not self.frame or not self.textFS then return end

    if not self.inCombat or not self.combatStart then
        self.textFS:SetText("00:00")
        self.frame:Hide()
        -- Cancel the repeating timer using AceTimer
        if self.combatTimer then
            self:CancelTimer(self.combatTimer)
            self.combatTimer = nil
        end
        return
    end

    local now = GetTime()
    local seconds = now - self.combatStart
    if seconds < 0 then seconds = 0 end

    self.textFS:SetText(FormatMMSS(seconds))
    self.frame:Show()
end

-------------------------------------------------
-- Ace3 Timer
-------------------------------------------------
function CombatTime:StartTicker()
    -- Cancel existing timer if any
    if self.combatTimer then
        self:CancelTimer(self.combatTimer)
        self.combatTimer = nil
    end

    -- ScheduleRepeatingTimer expects (func, delay, ...) NOT (delay, func, ...)
    local interval = tonumber(self.db.updateInterval) or self.defaults.updateInterval
    self.combatTimer = self:ScheduleRepeatingTimer("Update", interval)
end

-------------------------------------------------
-- Combat transitions
-------------------------------------------------
function CombatTime:EnterCombat()
    if self.inCombat then return end
    if not self.db or self.db.enabled == false then return end

    self.inCombat = true
    self.combatStart = GetTime()

    if self.frame then self.frame:Show() end
    self:StartTicker()
    self:Update()
end

function CombatTime:LeaveCombat()
    if not self.inCombat then return end

    local now = GetTime()
    local duration = 0
    if self.combatStart then
        duration = now - self.combatStart
        if duration < 0 then duration = 0 end
    end

    -- Persist total (optional)
    if self.db and self.db.persistTotal then
        self.totalSeconds = (self.totalSeconds or 0) + duration
        self.db.totalSeconds = self.totalSeconds
    end

    -- Reset combat state
    self.inCombat = false
    self.combatStart = nil

    -- Reset UI to 00:00 and hide
    if self.textFS then
        self.textFS:SetText("00:00")
    end

    -- Cancel timer using AceTimer
    if self.combatTimer then
        self:CancelTimer(self.combatTimer)
        self.combatTimer = nil
    end

    if self.frame then self.frame:Hide() end
end

-------------------------------------------------
-- Ace3 Lifecycle Callbacks
-------------------------------------------------

function CombatTime:OnInitialize()
    -- This is called when the addon is loaded
    -- Initialize the database using AceDB
    self.db = BS.DB:EnsureDB(self.name, self.defaults)
    self.enabled = (self.db.enabled ~= false)

    -- Load persistent total
    self.db.totalSeconds = tonumber(self.db.totalSeconds) or 0
    self.totalSeconds = self.db.totalSeconds
end

function CombatTime:OnEnable()
    -- This is called on PLAYER_LOGIN when module is enabled
    self:OnInitialize()

    EnsureUI(self)
    ApplyPosition(self)
    ApplyFont(self)

    -- Register with movers
    if BS.Movers then
        BS.Movers:Register(self.frame, self.name, "Combat Time")
    end

    if not self.enabled then
        self.frame:Hide()
        return
    end

    -- Sync state on load/reload
    if UnitAffectingCombat("player") then
        self.inCombat = true
        self.combatStart = GetTime()
        self.frame:Show()
        self:StartTicker()
        self:Update()
    else
        self.inCombat = false
        self.combatStart = nil
        self.textFS:SetText("00:00")
        self.frame:Hide()
    end

    -- Register events using AceEvent (embedded library)
    self:RegisterEvent("PLAYER_REGEN_DISABLED", "EnterCombat")
    self:RegisterEvent("PLAYER_REGEN_ENABLED", "LeaveCombat")
    self:RegisterEvent("PLAYER_ENTERING_WORLD", "OnPlayerEnteringWorld")
end

function CombatTime:OnDisable()
    -- Refresh db, force disable, persist state
    self.db = BS.DB:EnsureDB(self.name, self.defaults)
    self.enabled = false
    if self.db then self.db.enabled = false end

    -- Reset runtime combat state
    self.inCombat = false
    self.combatStart = nil

    -- Cancel timer using AceTimer
    if self.combatTimer then
        self:CancelTimer(self.combatTimer)
        self.combatTimer = nil
    end

    -- Unregister all events (AceEvent handles this automatically)
    -- No need to manually unregister

    -- Hide UI
    if self.textFS then
        self.textFS:SetText("00:00")
    end
    if self.frame then
        self.frame:Hide()
    end
end

-------------------------------------------------
-- Event Handlers (AceEvent style)
-------------------------------------------------
function CombatTime:OnPlayerEnteringWorld()
    if not self.db or self.db.enabled == false then return end

    -- Safety sync on zoning/reload
    if UnitAffectingCombat("player") then
        if not self.inCombat then
            self:EnterCombat()
            return
        end
    else
        if self.inCombat then
            self:LeaveCombat()
            return
        end
    end

    self:Update()
end

-------------------------------------------------
-- ApplyOptions (for Config panel)
-------------------------------------------------
function CombatTime:ApplyOptions()
    self.db = BS.DB:EnsureDB(self.name, self.defaults)
    -- Update behavior and UI with new config

    ApplyPosition(self)
    ApplyFont(self)

    -- Restart ticker with new interval if enabled
    if self.enabled and self.inCombat then
        self:StartTicker()
    end

    self:Update()
end
