-- Modules/EnemyCastList/EnemyCastList.lua
-- @module EnemyCastList
-- @alias EnemyCastList

local BS = _G.BS

-------------------------------------------------
-- Create as an Ace3 Module
-------------------------------------------------
local EnemyCastList = BS.Addon:NewModule("EnemyCastList", "AceEvent-3.0", "AceTimer-3.0")

-------------------------------------------------
-- Module Metadata (for BS.API compatibility)
-------------------------------------------------
EnemyCastList.name = "BS_ECL"
EnemyCastList.label = "Enemy Cast List"
EnemyCastList.enabled = true
EnemyCastList.defaults = {
    enabled = true,
    x = 0,
    y = -40,
    width = 460,
    maxLines = 10,
    fontSize = 14,
    font = "Fonts\\FRIZQT__.TTF",
    updateInterval = 0.05,
    channelHoldSeconds = 0.20,
    onlyTargetingMe = true,
    alphaTargetingMe = 1.0,
    alphaNotTargetingMe = 0.0,
    onlyWhilePlayerInCombat = true,
    onlyHostile = true,
    showChannels = true,
    debugAlwaysShow = false,
    noTargetText = "(sin target)",
}

-------------------------------------------------
-- Register with BS.API (for Config panel compatibility)
-------------------------------------------------
BS.API:Register(EnemyCastList)

-------------------------------------------------
-- Constants / Locals
-------------------------------------------------
local FONT = "Fonts\\FRIZQT__.TTF"

local GetSpellCooldown = C_Spell.GetSpellCooldown

local function HexFromRGB(r, g, b)
    r = math.floor((r or 1) * 255 + 0.5)
    g = math.floor((g or 1) * 255 + 0.5)
    b = math.floor((b or 1) * 255 + 0.5)
    return string.format("%02x%02x%02x", r, g, b)
end

local function Colorize(text, r, g, b)
    if not text then return "" end
    return "|cff" .. HexFromRGB(r, g, b) .. text .. "|r"
end

local function GetUnitFullName(unit)
    local name, _ = UnitName(unit)
    if not name then return nil end
    return name
end

local function GetColoredUnitName(unit)
    local name = GetUnitFullName(unit)
    if not name then return nil end

    if UnitIsPlayer(unit) then
        local _, classFile = UnitClass(unit)
        local c = classFile and RAID_CLASS_COLORS and RAID_CLASS_COLORS[classFile]
        if c then
            return Colorize(name, c.r, c.g, c.b)
        end
        return name
    end

    local reaction = UnitReaction(unit, "player")
    if reaction and FACTION_BAR_COLORS and FACTION_BAR_COLORS[reaction] then
        local c = FACTION_BAR_COLORS[reaction]
        return Colorize(name, c.r, c.g, c.b)
    end

    return name
end

local function IsUnitValidHostile(self, unit)
    if not UnitExists(unit) then return false end

    if self.db.onlyHostile then
        if not UnitCanAttack("player", unit) then
            return false
        end
    end

    return true
end

local function IsTargetingPlayer(unit)
    local tu = unit .. "target"
    return UnitExists(tu) and UnitIsUnit(tu, "player")
end

local function TryGetUnitTargetName(unit, noTargetText)
    local tu = unit .. "target"
    if UnitExists(tu) then
        return GetColoredUnitName(tu) or (noTargetText or "(sin target)")
    end
    return noTargetText or "(sin target)"
end

-------------------------------------------------
-- State
-------------------------------------------------
function EnemyCastList:Reset()
    self.units = {}
    self.casts = {}
end

-------------------------------------------------
-- UI
-------------------------------------------------
local function EnsureUI(self)
    if self.frame and self.lines then return end

    local f = CreateFrame("Frame", "BS_EnemyCastList", UIParent)
    f:SetFrameStrata("LOW")
    f:Hide()

    self.frame = f
    self.lines = {}
    for i = 1, (self.defaults.maxLines or 6) do
        local t = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        t:SetJustifyH("LEFT")
        t:SetTextColor(1, 1, 1, 1)
        t:Hide()
        self.lines[i] = t
    end
end

local function ApplyPosition(self)
    self.frame:ClearAllPoints()
    self.frame:SetPoint("CENTER", UIParent, "CENTER", self.db.x or 0, self.db.y or -40)
end

local function ApplySizeAndLayout(self)
    local w = tonumber(self.db.width) or self.defaults.width
    local maxLines = tonumber(self.db.maxLines) or self.defaults.maxLines
    if maxLines < 1 then maxLines = 1 end
    if maxLines > 20 then maxLines = 20 end

    local fs = tonumber(self.db.fontSize) or self.defaults.fontSize
    local lineH = fs + 2

    self.frame:SetSize(w, maxLines * lineH)

    for i = 1, maxLines do
        if not self.lines[i] then
            local t = self.frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            t:SetJustifyH("LEFT")
            t:SetTextColor(1, 1, 1, 1)
            t:Hide()
            self.lines[i] = t
        end
    end

    for i = 1, #self.lines do
        local t = self.lines[i]
        if t then
            t:ClearAllPoints()
            t:SetPoint("TOPLEFT", self.frame, "TOPLEFT", 0, -((i - 1) * lineH))
        end
    end
end

local function ApplyFont(self)
    local fontPath = self.db.font or FONT
    local fs = tonumber(self.db.fontSize) or self.defaults.fontSize
    local fallbackFont, fallbackSize, fallbackFlags = GameFontNormal:GetFont()

    for i = 1, #self.lines do
        local t = self.lines[i]
        if t then
            local ok = pcall(function()
                t:SetFont(fontPath, fs, "OUTLINE")
            end)
            if not ok then
                t:SetFont(fallbackFont, fs or fallbackSize or 14, fallbackFlags or "OUTLINE")
            end
        end
    end
end

-------------------------------------------------
-- Read Unit Cast
-------------------------------------------------
function EnemyCastList:ReadUnitCast(unit)
    if not UnitExists(unit) then return nil end

    local now = GetTime()

    local spellName, _, _, _, _, _ = UnitCastingInfo(unit)
    local isChannel = false

    if not spellName and (self.db.showChannels ~= false) then
        spellName, _, _, _, _, _ = UnitChannelInfo(unit)
        if spellName then isChannel = true end
    end

    if not spellName then return nil end

    local casterName = UnitName(unit) or unit
    local targetName = TryGetUnitTargetName(unit, self.db.noTargetText)

    local hold = tonumber(self.db.channelHoldSeconds) or tonumber(self.defaults.channelHoldSeconds) or 0.20

    return {
        unit = unit,
        casterName = casterName,
        spellName = spellName,
        targetName = targetName,
        isChannel = isChannel,
        targetingMe = IsTargetingPlayer(unit),
        holdUntil = now + (isChannel and hold or 0),
        lastSeen = now,
    }
end

function EnemyCastList:RefreshAll()
    local now = GetTime()

    for unit, _ in pairs(self.units) do
        if UnitExists(unit) and IsUnitValidHostile(self, unit) then
            local c = self:ReadUnitCast(unit)

            if c then
                self.casts[unit] = c
            else
                local prev = self.casts[unit]
                if prev and prev.isChannel and prev.holdUntil and now < prev.holdUntil then
                    prev.targetName = TryGetUnitTargetName(unit, self.db.noTargetText)
                    prev.targetingMe = IsTargetingPlayer(unit)
                    prev.lastSeen = now
                    self.casts[unit] = prev
                else
                    self.casts[unit] = nil
                end
            end
        else
            self.casts[unit] = nil
        end
    end
end

-------------------------------------------------
-- Rendering
-------------------------------------------------
function EnemyCastList:ShouldShow()
    if not self.db or self.db.enabled == false then return false end
    if self.db.onlyWhilePlayerInCombat and not UnitAffectingCombat("player") then
        return false
    end
    return true
end

function EnemyCastList:Update()
    if not self.frame or not self.lines then return end
    if not self.db or self.db.enabled == false then
        self.frame:Hide()
        return
    end

    if self:ShouldShow() ~= true then
        self.frame:Hide()
        return
    end

    local maxLines = tonumber(self.db.maxLines) or self.defaults.maxLines
    if maxLines < 1 then maxLines = 1 end
    if maxLines > 20 then maxLines = 20 end

    local list = {}
    for _, c in pairs(self.casts or {}) do
        if c then list[#list + 1] = c end
    end

    if #list == 0 then
        if self.db.debugAlwaysShow then
            self.frame:Show()
            local a1 = tonumber(self.db.alphaTargetingMe) or 1
            local a0 = tonumber(self.db.alphaNotTargetingMe) or 0
            local onlyMe = (self.db.onlyTargetingMe == true)

            for i = 1, maxLines do
                local t = self.lines[i]
                local c = list[i]
                if t and c then
                    local msg = (c.spellName or "Unknown") ..
                        " >> " .. (c.targetName or (self.db.noTargetText or "(sin target)"))
                    msg = msg .. "  |cffaaaaaa(" .. (c.casterName or "?") .. ")|r"
                    t:SetText(msg)

                    local showLine = (not onlyMe) or (c.targetingMe == true)

                    if t.SetAlphaFromBoolean then
                        t:SetAlphaFromBoolean(showLine, a1, a0)
                    else
                        t:SetAlpha(showLine and a1 or a0)
                    end

                    t:Show()
                elseif t then
                    t:SetText("")
                    t:SetAlpha(1)
                    t:Hide()
                end
            end
        else
            self.frame:Hide()
        end
        return
    end

    self.frame:Show()

    local a1 = tonumber(self.db.alphaTargetingMe) or 1
    local a0 = tonumber(self.db.alphaNotTargetingMe) or 0
    local onlyMe = (self.db.onlyTargetingMe == true)

    for i = 1, maxLines do
        local t = self.lines[i]
        local c = list[i]
        if t and c then
            local msg = (c.spellName or "Unknown") ..
                " >> " .. (c.targetName or (self.db.noTargetText or "(sin target)"))
            msg = msg .. "  |cffaaaaaa(" .. (c.casterName or "?") .. ")|r"
            t:SetText(msg)

            if onlyMe and t.SetAlphaFromBoolean then
                t:SetAlphaFromBoolean(c.targetingMe, a1, a0)
            else
                t:SetAlpha(c.targetingMe and a1 or a0)
            end

            t:Show()
        elseif t then
            t:SetText("")
            t:SetAlpha(1)
            t:Hide()
        end
    end
end

-------------------------------------------------
-- Ace3 Timer
-------------------------------------------------
function EnemyCastList:StartTicker()
    if self.updateTimer then
        self:CancelTimer(self.updateTimer)
        self.updateTimer = nil
    end

    local interval = tonumber(self.db and self.db.updateInterval) or self.defaults.updateInterval
    if interval < 0.02 then interval = 0.02 end

    -- ScheduleRepeatingTimer expects (func, delay, ...) NOT (delay, func, ...)
    self.updateTimer = self:ScheduleRepeatingTimer("TickerUpdate", interval)
end

function EnemyCastList:TickerUpdate()
    self:RefreshAll()
    self:Update()
end

-------------------------------------------------
-- Event Handlers (AceEvent style)
-------------------------------------------------
function EnemyCastList:OnNamePlateAdded(unit)
    if not self.enabled then return end
    if not unit then return end
    if not IsUnitValidHostile(self, unit) then return end

    self.units[unit] = true

    local c = self:ReadUnitCast(unit)
    if c then self.casts[unit] = c end

    self:Update()
end

function EnemyCastList:OnNamePlateRemoved(unit)
    if not self.enabled then return end
    if not unit then return end

    self.units[unit] = nil
    self.casts[unit] = nil

    self:Update()
end

-------------------------------------------------
-- Ace3 Lifecycle Callbacks
-------------------------------------------------
function EnemyCastList:OnInitialize()
    self.db = BS.DB:EnsureDB(self.name, self.defaults)
    self.enabled = (self.db.enabled ~= false)
end

function EnemyCastList:OnEnable()
    self:OnInitialize()

    EnsureUI(self)
    ApplyPosition(self)
    ApplySizeAndLayout(self)
    ApplyFont(self)

    if BS.Movers then
        BS.Movers:Register(self.frame, self.name, "Enemy Cast List")
    end

    self:Reset()

    self.frame:SetShown(self.enabled)

    if self.enabled then
        self:StartTicker()
        self:RefreshAll()
        self:Update()
    else
        self.frame:Hide()
        if self.updateTimer then
            self:CancelTimer(self.updateTimer)
            self.updateTimer = nil
        end
    end

    -- Register events using AceEvent
    self:RegisterEvent("NAME_PLATE_UNIT_ADDED", "OnNamePlateAdded")
    self:RegisterEvent("NAME_PLATE_UNIT_REMOVED", "OnNamePlateRemoved")
end

function EnemyCastList:OnDisable()
    self.db = BS.DB:EnsureDB(self.name, self.defaults)
    self.enabled = false
    if self.db then self.db.enabled = false end

    if self.updateTimer then
        self:CancelTimer(self.updateTimer)
        self.updateTimer = nil
    end

    if self.frame then
        self.frame:Hide()
    end
    self:Reset()

    -- AceEvent automatically unregisters all events
end

-------------------------------------------------
-- ApplyOptions (for Config panel)
-------------------------------------------------
function EnemyCastList:ApplyOptions()
    EnsureUI(self)
    ApplyPosition(self)
    ApplySizeAndLayout(self)
    ApplyFont(self)
    BS.Movers:Apply("EnemyCastList")

    if self.enabled then
        self:StartTicker()
        self:RefreshAll()
        self:Update()
    else
        if self.frame then self.frame:Hide() end
        if self.updateTimer then
            self:CancelTimer(self.updateTimer)
            self.updateTimer = nil
        end
    end
end
