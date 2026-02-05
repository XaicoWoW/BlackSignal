-- Modules/FocusCastTracker/FocusCastTracker.lua
-- @module FocusCastTracker
-- @alias FocusCastTracker

local BS = _G.BS

-------------------------------------------------
-- Create as an Ace3 Module
-------------------------------------------------
local FocusCastTracker = BS.Addon:NewModule("FocusCastTracker", "AceEvent-3.0", "AceTimer-3.0")

-------------------------------------------------
-- Module Metadata (for BS.API compatibility)
-------------------------------------------------
FocusCastTracker.name = "BS_FCT"
FocusCastTracker.label = "Focus Cast Tracker"
FocusCastTracker.enabled = true
FocusCastTracker.defaults = {
    enabled = true,
    x = 0,
    y = 200,
    fontSize = 16,
    font = "Fonts\\FRIZQT__.TTF",
    text = "Interrupt",
    updateInterval = 0.05,
    onlyShowIfKickReady = true,
}

-------------------------------------------------
-- Register with BS.API (for Config panel compatibility)
-------------------------------------------------
BS.API:Register(FocusCastTracker)

-------------------------------------------------
-- Constants / Locals
-------------------------------------------------
local FONT = "Fonts\\FRIZQT__.TTF"
local GetSpellCooldown = C_Spell.GetSpellCooldown

local KICK_BY_CLASS = {
    WARRIOR = 6552,
    ROGUE = 1766,
    MAGE = 2139,
    HUNTER = 147362,
    SHAMAN = 57994,
    DRUID = 106839,
    PALADIN = 96231,
    DEATHKNIGHT = 47528,
    DEMONHUNTER = 183752,
    MONK = 116705,
    WARLOCK = 19647,
    EVOKER = 351338,
}

local RAID_CLASS_COLORS = RAID_CLASS_COLORS

local function ColorizeText(text, color)
    if not text or not color then return text end
    if color.colorStr then
        return "|c" .. color.colorStr .. text .. "|r"
    end
    local r = math.floor((color.r or 1) * 255 + 0.5)
    local g = math.floor((color.g or 1) * 255 + 0.5)
    local b = math.floor((color.b or 1) * 255 + 0.5)
    return string.format("|cff%02x%02x%02x%s|r", r, g, b, text)
end

local function GetUnitNameColoredByClass(unit)
    if not UnitExists(unit) then return nil end
    local name = UnitName(unit)
    if not name then return nil end

    local _, classTag = UnitClass(unit)
    if classTag and RAID_CLASS_COLORS and RAID_CLASS_COLORS[classTag] then
        return ColorizeText(name, RAID_CLASS_COLORS[classTag])
    end

    return name
end

local function GetFocusTargetName()
    if UnitExists("focustarget") then
        return GetUnitNameColoredByClass("focustarget")
    end
    return nil
end

local function GetKickId()
    local _, class = UnitClass("player")
    return class and KICK_BY_CLASS[class] or nil
end

local function IsKickReady(spellID)
    local cdInfo = GetSpellCooldown(spellID)
    local isOnGCD = cdInfo and cdInfo.isOnGCD
    return isOnGCD
end

-------------------------------------------------
-- UI
-------------------------------------------------
local function EnsureUI(self)
    if self.frame and self.text and not self.db then return end
    local fontPath = self.db.font or FONT
    local fontSize = tonumber(self.db.fontSize) or 16
    local kickText = "Interrupt"

    if self.db.text and self.db.text ~= "" then
        kickText = self.db.text
    end

    local f = CreateFrame("Frame", "BS_FocusCastTrackerDisplay", UIParent)
    f:SetSize(380, 30)
    f:SetFrameStrata("LOW")
    f:Hide()

    local t = f:CreateFontString(nil, "OVERLAY")
    t:SetPoint("CENTER")
    t:SetJustifyH("CENTER")
    t:SetTextColor(1, 1, 1, 1)

    local warn = CreateFrame("Frame", nil, f, "BackdropTemplate")
    warn:SetSize(18, 18)
    warn:SetPoint("CENTER", f, "CENTER", 0, -fontSize)

    local wt = warn:CreateFontString(nil, "OVERLAY")
    wt:SetPoint("CENTER", warn, "CENTER", 0, -1)
    wt:SetFont(fontPath, fontSize, "OUTLINE")
    wt:SetTextColor(1.00, 0.15, 0.15, 1.00)
    wt:SetText(kickText)

    self.frame = f
    self.text = t
    self.warnFrame = warn
end

local function ApplyPosition(self)
    if not self.frame or not self.db then return end
    self.frame:ClearAllPoints()
    self.frame:SetPoint("CENTER", UIParent, "CENTER", self.db.x or 0, self.db.y or -120)
end

local function ApplyFont(self)
    if not self.text or not self.db then return end
    local fontPath = self.db.font or FONT
    self.text:SetFont(fontPath, tonumber(self.db.fontSize) or 16, "OUTLINE")
end

-------------------------------------------------
-- Spell selection
-------------------------------------------------
function FocusCastTracker:ResolveSpell()
    local kickId = GetKickId()
    if not kickId then
        self.spellID = nil
        return
    end

    if C_SpellBook and C_SpellBook.IsSpellKnown then
        if C_SpellBook.IsSpellKnown(kickId) then
            self.spellID = kickId
        else
            self.spellID = nil
        end
    else
        self.spellID = kickId
    end
end

-------------------------------------------------
-- Cast state
-------------------------------------------------
function FocusCastTracker:ReadFocusCast()
    if not UnitExists("focus") then
        self.castInfo = nil
        return nil
    end

    local name, _, _, _, _, _, _, notInterruptible, spellId = UnitCastingInfo("focus")

    if not name then
        name, _, _, _, _, _, _, _, notInterruptible, spellId = UnitChannelInfo("focus")
    end

    if not name then
        self.castInfo = nil
        return nil
    end

    local info = {
        name = name,
        spellId = spellId,
        notInterruptible = notInterruptible,
        targetName = GetFocusTargetName(),
    }

    self.castInfo = info
    return info
end

function FocusCastTracker:ClearCast()
    self.castInfo = nil
    if self.text then
        self.text:SetText("")
    end
end

function FocusCastTracker:PLAYER_FOCUS_CHANGED()
    self:ClearCast()
    self:Update()
end

-------------------------------------------------
-- Update
-------------------------------------------------
function FocusCastTracker:Update()
    if not self.db or self.db.enabled == false then return end
    if not self.frame or not self.text then return end

    if not self.castInfo or not self.castInfo.name then
        self.frame:SetAlpha(0)
        return
    end

    local kickReady = IsKickReady(self.spellID)

    if self.db.onlyShowIfKickReady then
        self.frame:SetAlphaFromBoolean(kickReady ~= false, 1, 0)
    else
        self.frame:SetAlpha(1)
    end

    if self.warnFrame then
        self.warnFrame:SetAlphaFromBoolean(self.castInfo.notInterruptible, 0, 1)
    end

    local msg = self.castInfo.name
    if self.castInfo.targetName then
        msg = msg .. " >> " .. self.castInfo.targetName
    end

    self.text:SetText(msg)
end

-------------------------------------------------
-- Ace3 Timer
-------------------------------------------------
function FocusCastTracker:StartTicker()
    if self.updateTimer then
        self:CancelTimer(self.updateTimer)
        self.updateTimer = nil
    end

    -- ScheduleRepeatingTimer expects (func, delay, ...) NOT (delay, func, ...)
    local interval = tonumber(self.db.updateInterval) or 0.05
    self.updateTimer = self:ScheduleRepeatingTimer("TickerUpdate", interval)
end

function FocusCastTracker:TickerUpdate()
    self:ReadFocusCast()
    self:Update()
end

-------------------------------------------------
-- Event Handlers (AceEvent style)
-------------------------------------------------
function FocusCastTracker:OnFocusCastEvent(unit)
    if unit ~= "focus" then return end
    if not self.enabled then return end

    local info = self:ReadFocusCast()
    if info then
        self:StartTicker()
    else
        if self.updateTimer then
            self:CancelTimer(self.updateTimer)
            self.updateTimer = nil
        end
        self:ClearCast()
    end

    self:Update()
end

local function TalentUpdate(self)
    C_Timer.After(0.5, function()
        self:ResolveSpell()
    end)
    C_Timer.After(0.6, function()
        if self.enabled then
            self:ReadFocusCast()
            if self.castInfo then
                self:StartTicker()
            else
                if self.updateTimer then
                    self:CancelTimer(self.updateTimer)
                    self.updateTimer = nil
                end
            end
            self:Update()
        end
    end)
end

-------------------------------------------------
-- Ace3 Lifecycle Callbacks
-------------------------------------------------
function FocusCastTracker:OnInitialize()
    self.db = BS.DB:EnsureDB(self.name, self.defaults)
    self.enabled = (self.db.enabled ~= false)
end

function FocusCastTracker:OnEnable()
    self:OnInitialize()

    EnsureUI(self)
    ApplyPosition(self)
    ApplyFont(self)

    if BS.Movers then
        BS.Movers:Register(self.frame, self.name, "Focus Cast Tracker")
    end

    self:ResolveSpell()
    self:ReadFocusCast()
    self.frame:SetShown(self.enabled)

    if self.enabled and self.castInfo then
        self:StartTicker()
    end

    self:Update()

    -- Register events using AceEvent
    self:RegisterEvent("SPELL_UPDATE_COOLDOWN", "Update")
    self:RegisterEvent("PLAYER_FOCUS_CHANGED")
    self:RegisterEvent("UNIT_SPELLCAST_START", "OnFocusCastEvent")
    self:RegisterEvent("UNIT_SPELLCAST_STOP", "OnFocusCastEvent")
    self:RegisterEvent("UNIT_SPELLCAST_FAILED", "OnFocusCastEvent")
    self:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED", "OnFocusCastEvent")
    self:RegisterEvent("UNIT_SPELLCAST_DELAYED", "OnFocusCastEvent")
    self:RegisterEvent("UNIT_SPELLCAST_CHANNEL_START", "OnFocusCastEvent")
    self:RegisterEvent("UNIT_SPELLCAST_CHANNEL_STOP", "OnFocusCastEvent")
    self:RegisterEvent("UNIT_SPELLCAST_CHANNEL_UPDATE", "OnFocusCastEvent")
    self:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED", "OnTalentChanged")
    self:RegisterEvent("TRAIT_CONFIG_UPDATED", "OnTalentChanged")
    self:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED", "OnTalentChanged")
end

function FocusCastTracker:OnDisable()
    self.db = BS.DB:EnsureDB(self.name, self.defaults)
    self.enabled = false
    if self.db then self.db.enabled = false end

    if self.updateTimer then
        self:CancelTimer(self.updateTimer)
        self.updateTimer = nil
    end

    self.castInfo = nil
    self.focusGUID = nil
    self.focusName = nil

    if self.frame then
        self.frame:Hide()
    end

    -- AceEvent automatically unregisters all events
end

function FocusCastTracker:OnTalentChanged()
    TalentUpdate(self)
end

-------------------------------------------------
-- ApplyOptions (for Config panel)
-------------------------------------------------
function FocusCastTracker:ApplyOptions()
    EnsureUI(self)
    ApplyPosition(self)
    ApplyFont(self)

    self.enabled = (self.db and self.db.enabled ~= false)
    self.frame:SetShown(self.enabled)

    if not self.enabled then
        if self.updateTimer then
            self:CancelTimer(self.updateTimer)
            self.updateTimer = nil
        end
        self:ClearCast()
        return
    end

    self:ResolveSpell()
    self:ReadFocusCast()

    if self.castInfo then
        self:StartTicker()
    end

    self:Update()
end
