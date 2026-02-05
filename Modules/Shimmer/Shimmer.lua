-- Modules/Shimmer/Shimmer.lua
-- @module Shimmer
-- @alias Shimmer

local BS = _G.BS

-------------------------------------------------
-- Create as an Ace3 Module
-------------------------------------------------
local Shimmer = BS.Addon:NewModule("Shimmer", "AceEvent-3.0", "AceTimer-3.0")

-------------------------------------------------
-- Module Metadata (for BS.API compatibility)
-------------------------------------------------
Shimmer.name = "BS_S"
Shimmer.label = "Movement Warnings"
Shimmer.enabled = true
Shimmer.defaults = {
    enabled = true,
    x = 0,
    y = 18,
    font = "Fonts\\FRIZQT__.TTF",
    fontSize = 20,
    outline = "OUTLINE",
    autoSelect = true,
    selectedKey = nil,
}

-------------------------------------------------
-- Register with BS.API (for Config panel compatibility)
-------------------------------------------------
BS.API:Register(Shimmer)

-------------------------------------------------
-- Spell (by class)
-------------------------------------------------
local CLASS_SPELLS = {
    MAGE = {
        { key = "blink", label = "Blink/Shimmer", spellIds = { 212653, 1953 } },
    },
    HUNTER = {
        { key = "disengage", label = "Disengage", spellIds = { 781 } },
    },
    ROGUE = {
        { key = "step", label = "Shadowstep", spellIds = { 36554 } },
    },
    WARLOCK = {
        { key = "circle", label = "Demonic Circle", spellIds = { 48020 } },
    },
    WARRIOR = {
        { key = "charge", label = "Charge", spellIds = { 100 } },
    },
    PALADIN = {
        { key = "steed", label = "Divine Steed", spellIds = { 190784 } },
    },
    MONK = {
        { key = "roll", label = "Roll/Chi Torpedo", spellIds = { 109132, 115008 } },
    },
    DRUID = {
        { key = "dash", label = "Dash", spellIds = { 1850 } },
    },
    SHAMAN = {
        { key = "gust_winds", label = "Gust of Winds", spellIds = { 192063 } },
    },
    PRIEST = {
        { key = "feather", label = "Angelic Feather", spellIds = { 121536 } },
    },
    DEATHKNIGHT = {
        { key = "deaths_advance", label = "Death's Advance", spellIds = { 48265 } },
    },
    DEMONHUNTER = {
        { key = "felrush", label = "Fel Rush", spellIds = { 195072 } },
        { key = "infernal_strike", label = "Infernal Strike", spellIds = { 189110 } },
        { key = "shift", label = "Shift", spellIds = { 1234796 } },
    },
    EVOKER = {
        { key = "hover", label = "Hover", spellIds = { 358267 } },
    },
}

-------------------------------------------------
-- Locals / helpers
-------------------------------------------------
local IsSpellKnown = C_SpellBook and C_SpellBook.IsSpellKnown
local GetSpellCooldown = C_Spell.GetSpellCooldown
local GetSpellCooldownDuration = C_Spell.GetSpellCooldownDuration

local function GetPlayerClass()
    local _, class = UnitClass("player")
    return class
end

local function FirstKnownSpellId(spellIds)
    if type(spellIds) ~= "table" then return nil end
    for _, id in ipairs(spellIds) do
        if id and IsSpellKnown and IsSpellKnown(id) then
            return id
        end
    end
    return nil
end

-------------------------------------------------
-- UI
-------------------------------------------------
local function EnsureUI(self)
    if self.frame and self.text then return end

    local f = CreateFrame("Frame", "BS_ShimmerDisplay", UIParent)
    f:SetSize(400, 30)
    f:SetFrameStrata("LOW")
    f:Show()

    local t = f:CreateFontString(nil, "OVERLAY")
    t:SetPoint("CENTER")
    t:SetJustifyH("CENTER")
    t:SetTextColor(1, 1, 1, 1)

    self.frame = f
    self.text = t
end

local function ApplyPosition(self)
    if not self.frame or not self.db then return end
    self.frame:ClearAllPoints()
    self.frame:SetPoint("CENTER", UIParent, "CENTER", self.db.x or 0, self.db.y or 18)
end

local function ApplyFont(self)
    if not self.text or not self.db then return end
    local font = self.db.font or self.defaults.font
    local size = tonumber(self.db.fontSize) or self.defaults.fontSize
    local outline = self.db.outline or self.defaults.outline
    self.text:SetFont(font, size, outline)
end

-------------------------------------------------
-- Spell resolution
-------------------------------------------------
function Shimmer:ResolveSpell()
    self.spellKey = nil
    self.spellID = nil

    local class = GetPlayerClass()
    if not class then return end

    local list = CLASS_SPELLS[class]
    if type(list) ~= "table" then return end

    local wanted = self.db and self.db.selectedKey
    if wanted then
        for _, entry in ipairs(list) do
            if entry and entry.key == wanted then
                local id = FirstKnownSpellId(entry.spellIds)
                if id then
                    self.spellKey = entry.key
                    self.spellID = id
                    self.spellLabel = entry.label
                    return
                end
            end
        end
    end

    if self.db and self.db.autoSelect == false then return end

    for _, entry in ipairs(list) do
        local id = entry and FirstKnownSpellId(entry.spellIds)
        if id then
            self.spellKey = entry.key
            self.spellID = id
            self.spellLabel = entry.label
            return
        end
    end
end

-------------------------------------------------
-- Update
-------------------------------------------------
function Shimmer:Update()
    if not self.db or self.db.enabled == false then return end
    if not self.spellID or not self.frame or not self.text then return end

    local durationObject = GetSpellCooldownDuration(self.spellID)
    if not durationObject or not durationObject.GetRemainingDuration then return end

    local actualCooldown = durationObject:GetRemainingDuration(1)

    local cdInfo = GetSpellCooldown(self.spellID)
    local isOnGCD = cdInfo and cdInfo.isOnGCD

    if self.frame.SetAlphaFromBoolean then
        self.frame:SetAlphaFromBoolean(isOnGCD ~= false, 0, 1)
    else
        self.frame:SetAlpha((isOnGCD ~= false) and 1 or 0)
    end

    local spell = C_Spell.GetSpellInfo(self.spellID)
    local spellName = (spell and spell.name) or "Movement"

    self.text:SetText(string.format("No %s: %.1f", spellName, actualCooldown))
end

-------------------------------------------------
-- Ace3 Timer
-------------------------------------------------
function Shimmer:StartTicker()
    -- Cancel existing timer
    if self.updateTimer then
        self:CancelTimer(self.updateTimer)
        self.updateTimer = nil
    end

    -- Capture self in closure for the timer callback
    local updateFunc = function() self:Update() end
    self.updateTimer = self:ScheduleRepeatingTimer(updateFunc, 0.1)
end

-------------------------------------------------
-- Talent/spec changes
-------------------------------------------------
local function TalentUpdate(self)
    C_Timer.After(0.35, function()
        self:ResolveSpell()
    end)
    C_Timer.After(0.45, function()
        if self.enabled then
            self:Update()
        end
    end)
end

-------------------------------------------------
-- Ace3 Lifecycle Callbacks
-------------------------------------------------
function Shimmer:OnInitialize()
    self.db = BS.DB:EnsureDB(self.name, self.defaults)
    self.enabled = (self.db.enabled ~= false)
end

function Shimmer:OnEnable()
    self:OnInitialize()

    EnsureUI(self)
    ApplyPosition(self)
    ApplyFont(self)

    if BS.Movers then
        BS.Movers:Register(self.frame, self.name, self.label)
    end

    self:ResolveSpell()
    self.frame:SetShown(self.enabled)

    if self.enabled then
        self:StartTicker()
        self:Update()
    else
        if self.updateTimer then
            self:CancelTimer(self.updateTimer)
            self.updateTimer = nil
        end
    end

    -- Register events using AceEvent
    self:RegisterEvent("SPELL_UPDATE_COOLDOWN", "Update")
    self:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED", "OnTalentChanged")
    self:RegisterEvent("TRAIT_CONFIG_UPDATED", "OnTalentChanged")
    self:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED", "OnTalentChanged")
end

function Shimmer:OnDisable()
    self.db = BS.DB:EnsureDB(self.name, self.defaults)
    self.enabled = false
    if self.db then self.db.enabled = false end

    -- Cancel timer using AceTimer
    if self.updateTimer then
        self:CancelTimer(self.updateTimer)
        self.updateTimer = nil
    end

    -- AceEvent automatically unregisters all events

    if self.frame then
        self.frame:Hide()
    end
end

-------------------------------------------------
-- Event Handlers (AceEvent style)
-------------------------------------------------
function Shimmer:OnTalentChanged()
    TalentUpdate(self)
end

-------------------------------------------------
-- ApplyOptions (for Config panel)
-------------------------------------------------
function Shimmer:ApplyOptions()
    self.db = BS.DB:EnsureDB(self.name, self.defaults)

    ApplyPosition(self)
    ApplyFont(self)

    -- Restart ticker with new settings if enabled
    if self.enabled then
        self:StartTicker()
    end

    self:Update()
end
