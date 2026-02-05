-- Modules/BuffTracker/BuffTracker.lua
-- @module BuffTracker
-- @alias BuffTracker

local BS = _G.BS

-------------------------------------------------
-- Create as an Ace3 Module
-------------------------------------------------
local BuffTracker = BS.Addon:NewModule("BuffTracker", "AceEvent-3.0")

-------------------------------------------------
-- Module Metadata (for BS.API compatibility)
-------------------------------------------------
BuffTracker.name = "BS_BT"
BuffTracker.label = "Buff Tracker"
BuffTracker.enabled = true
BuffTracker.defaults = {
    enabled = true,
    locked = true,
    scale = 1,
    iconSize = 64,
    spacing = 8,
    perRow = 12,
    showText = true,
    x = 0,
    y = 500,
    showOptions = true,
    showOnlyInGroup = false,
    showOnlyInInstance = false,
    showOnlyPlayerClassBuff = false,
    showOnlyPlayerMissing = false,
    showOnlyOnReadyCheck = false,
    showExpirationGlow = true,
    expirationThreshold = 15,
    categories = {
        raid = true,
        presence = true,
        personal = true,
        self = true,
    },
}

-------------------------------------------------
-- Register with BS.API (for Config panel compatibility)
-------------------------------------------------
BS.API:Register(BuffTracker)

-------------------------------------------------
-- Constants
-------------------------------------------------
local READY_CHECK_DURATION = 15
local UPDATE_THROTTLE_SEC = 0.20

-------------------------------------------------
-- Internal helpers
-------------------------------------------------
local function EnsureDeps(self)
    self.Data = BS.BuffTrackerData
    self.Engine = BS.BuffTrackerEngine
    self.UI = BS.BuffTrackerUI
end

local function IsMythicPlusActive()
    return C_ChallengeMode and C_ChallengeMode.IsChallengeModeActive and C_ChallengeMode.IsChallengeModeActive()
end

local function UpdateChallengeState(self)
    self._inChallengeMode = IsMythicPlusActive() and true or false
end

local function ScheduleTalentRefresh(self)
    if self._talentTimer then
        self._talentTimer:Cancel()
        self._talentTimer = nil
    end
    self._talentTimer = C_Timer.NewTimer(0.25, function()
        self._talentTimer = nil
        self:RequestUpdate(true)
    end)
end

local function HideUI(self)
    if self and self.UI and self.UI.HideAll then
        self.UI:HideAll()
    end
end

-------------------------------------------------
-- Update
-------------------------------------------------
function BuffTracker:RequestUpdate(force)
    local now = GetTime()
    self._nextAllowed = self._nextAllowed or 0

    if not force and now < self._nextAllowed then
        return
    end

    self._nextAllowed = now + UPDATE_THROTTLE_SEC

    UpdateChallengeState(self)

    if self._inCombat or self._inChallengeMode then
        if self._readyCheckTimer then
            self._readyCheckTimer:Cancel()
            self._readyCheckTimer = nil
        end
        HideUI(self)
        return
    end

    local vm = self.Engine:BuildViewModel(self, force)
    self.UI:Render(self, vm)
end

function BuffTracker:Update()
    if not self.db or self.db.enabled == false then
        HideUI(self)
        return
    end
    self:RequestUpdate(true)
end

-------------------------------------------------
-- Event Handlers (AceEvent style)
-------------------------------------------------
function BuffTracker:OnPlayerEnteringWorld()
    self._inCombat = InCombatLockdown()
    self:RequestUpdate(true)
end

function BuffTracker:OnZoneChangedNewArea()
    UpdateChallengeState(self)
    self:RequestUpdate(true)
end

function BuffTracker:OnChallengeModeStart()
    UpdateChallengeState(self)
    if self._readyCheckTimer then
        self._readyCheckTimer:Cancel()
        self._readyCheckTimer = nil
    end
    HideUI(self)
end

function BuffTracker:OnChallengeModeReset()
    UpdateChallengeState(self)
    self:RequestUpdate(true)
end

function BuffTracker:OnChallengeModeCompleted()
    UpdateChallengeState(self)
    self:RequestUpdate(true)
end

function BuffTracker:OnGroupRosterUpdate()
    self:RequestUpdate(true)
end

function BuffTracker:OnUnitAura(unit)
    if unit ~= "player" then return end
    self:RequestUpdate(false)
end

function BuffTracker:OnPlayerRegenDisabled()
    self._inCombat = true
    if self._readyCheckTimer then
        self._readyCheckTimer:Cancel()
        self._readyCheckTimer = nil
    end
    HideUI(self)
end

function BuffTracker:OnPlayerRegenEnabled()
    self._inCombat = false
    self:RequestUpdate(true)
end

function BuffTracker:OnReadyCheck()
    if self._readyCheckTimer then
        self._readyCheckTimer:Cancel()
        self._readyCheckTimer = nil
    end

    self._inReadyCheck = true
    self:RequestUpdate(true)

    self._readyCheckTimer = C_Timer.NewTimer(READY_CHECK_DURATION, function()
        self._inReadyCheck = false
        self._readyCheckTimer = nil
        self:RequestUpdate(true)
    end)
end

function BuffTracker:OnTalentChanged()
    ScheduleTalentRefresh(self)
end

-------------------------------------------------
-- Ace3 Lifecycle Callbacks
-------------------------------------------------
function BuffTracker:OnInitialize()
    self.db = BS.DB:EnsureDB(self.name, self.defaults)
    self.enabled = (self.db.enabled ~= false)

    EnsureDeps(self)
    if not self.Engine or not self.UI then
        return
    end
    self.UI:Ensure(self)

    local root = self.UI:GetRootFrame()
    if root then
        BS.Movers:Register(root, self.name, "Buff Tracker")
    end

    -- State
    self._inCombat = InCombatLockdown()
    self._inChallengeMode = IsMythicPlusActive() and true or false
    self._inReadyCheck = false
    self._readyCheckTimer = nil
    self._talentTimer = nil
end

function BuffTracker:OnEnable()
    self:OnInitialize()

    self:Update()

    -- Register events using AceEvent
    self:RegisterEvent("PLAYER_ENTERING_WORLD", "OnPlayerEnteringWorld")
    self:RegisterEvent("ZONE_CHANGED_NEW_AREA", "OnZoneChangedNewArea")
    self:RegisterEvent("CHALLENGE_MODE_START", "OnChallengeModeStart")
    self:RegisterEvent("CHALLENGE_MODE_RESET", "OnChallengeModeReset")
    self:RegisterEvent("CHALLENGE_MODE_COMPLETED", "OnChallengeModeCompleted")
    self:RegisterEvent("GROUP_ROSTER_UPDATE", "OnGroupRosterUpdate")
    self:RegisterEvent("UNIT_AURA", "OnUnitAura")
    self:RegisterEvent("PLAYER_REGEN_ENABLED", "OnPlayerRegenEnabled")
    self:RegisterEvent("PLAYER_REGEN_DISABLED", "OnPlayerRegenDisabled")
    self:RegisterEvent("READY_CHECK", "OnReadyCheck")
    self:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED", "OnTalentChanged")
    self:RegisterEvent("TRAIT_CONFIG_UPDATED", "OnTalentChanged")
    self:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED", "OnTalentChanged")
end

function BuffTracker:OnDisable()
    self.db = BS.DB:EnsureDB(self.name, self.defaults)
    self.enabled = false
    if self.db then self.db.enabled = false end

    if self._readyCheckTimer then
        self._readyCheckTimer:Cancel()
        self._readyCheckTimer = nil
    end
    if self._talentTimer then
        self._talentTimer:Cancel()
        self._talentTimer = nil
    end

    self._inCombat = false
    self._inChallengeMode = false
    self._inReadyCheck = false

    -- AceEvent automatically unregisters all events

    if self.UI and self.UI.GetRootFrame then
        local root = self.UI:GetRootFrame()
        if root then
            root:Hide()

            if BS and BS.Movers and BS.Movers.Unregister then
                BS.Movers:Unregister(root, self.name)
            end
        end
    end
end

-------------------------------------------------
-- ApplyOptions (for Config panel)
-------------------------------------------------
function BuffTracker:ApplyOptions()
    self.db = BS.DB:EnsureDB(self.name, self.defaults)
    -- Update behavior and UI with new config

    if self.UI and self.UI.Refresh then
        self.UI:Refresh()
    end

    self:Update()
end
