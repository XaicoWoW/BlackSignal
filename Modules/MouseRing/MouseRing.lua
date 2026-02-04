-- Modules/MouseRing/MouseRing.lua
--- MouseRing Module
-- Muestra 2 anillos concéntricos alrededor del cursor:
-- 1. Cursor Ring (anillo decorativo base, el más pequeño - dentro)
-- 2. GCD Spinner (arco creciente, tamaño medio)
--
-- Efecto: Arco creciente (swipe) desde vacío hasta lleno, horario, sin brillo
-- Orden: De dentro hacia fuera (Cursor Ring → GCD)
--
-- @module MouseRing
-- @alias MouseRing

local _, BS = ...
local DB     = BS.DB
local API    = BS.API
local Events = BS.Events

local MouseRing = {
    name    = "BS_CR",
    label   = "Cursor Ring",
    enabled = true,
    events  = {},
}

API:Register(MouseRing)

-------------------------------------------------
-- Constants / Locals
-------------------------------------------------
local GCD_SPELL_ID = 61304

local GetTime = GetTime
local GetSpellCooldown = (C_Spell and C_Spell.GetSpellCooldown) or GetSpellCooldown

-------------------------------------------------
-- Defaults
-------------------------------------------------
local defaults = {
    enabled = true,

    size        = 48,
    thickness   = 20,

    -- Color único para todos los anillos
    ringColorR  = 0,
    ringColorG  = 1,
    ringColorB  = 0,
    ringAlpha   = 0.9,
    colorPicker = true,

    x = 0,
    y = 0,

    -- GCD settings
    gcdEnabled      = true,
    gcdShowOnly     = false,
    gcdReverse      = true,  -- Invertido: true = normal, false = reverso
}

MouseRing.defaults = defaults

-------------------------------------------------
-- Helpers
-------------------------------------------------
local function HideCooldownText(cooldown)
    if not cooldown then return end
    for _, region in ipairs({ cooldown:GetRegions() }) do
        if region:GetObjectType() == "FontString" then
            region:SetAlpha(0)
            region:Hide()
            region:SetText("")
            break
        end
    end
end

local function SetupCooldownTextHiding(cooldown)
    if not cooldown then return end

    -- Hook SetCooldown para ocultar el texto cada vez que se actualiza
    hooksecurefunc(cooldown, "SetCooldown", function()
        HideCooldownText(cooldown)
    end)

    -- Ocultar texto inicial
    HideCooldownText(cooldown)
end

local function Clamp(v, a, b)
    if v < a then return a end
    if v > b then return b end
    return v
end

local function ToNumber(v, fallback)
    v = tonumber(v)
    if v == nil then return fallback end
    return v
end

local function Clamp01(v)
    return Clamp(ToNumber(v, 0), 0, 1)
end

local function NormalizeThickness(t)
    t = ToNumber(t, 20)
    if t ~= 10 and t ~= 20 and t ~= 30 and t ~= 40 then
        t = 20
    end
    return t
end

local function GetRingTexturePath(db)
    local t = NormalizeThickness(db.thickness)
    return ("Interface\\AddOns\\BlackSignal\\Media\\Ring_%dpx.tga"):format(t)
end

local function GetGCDCooldownInfo()
    local cd = GetSpellCooldown(GCD_SPELL_ID)
    if not cd then return false, 0, 0 end

    local start = cd.startTime or cd[1] or 0
    local dur   = cd.duration  or cd[2] or 0
    local en    = cd.isEnabled

    if en ~= nil and not en then return false, 0, 0 end
    if dur <= 0 or dur > 2.5 then return false, 0, 0 end
    if start <= 0 then return false, 0, 0 end
    if (start + dur) <= GetTime() then return false, 0, 0 end

    return true, start, dur
end

-------------------------------------------------
-- Core Layout
-------------------------------------------------

function MouseRing:CalculateSizes()
    local db = self.db
    local baseSize = Clamp(ToNumber(db.size, 48), 12, 256)

    local gcdSize = baseSize * 1.25
    local outset = gcdSize * 0.18
    local holderSize = gcdSize + (outset * 2)

    return baseSize, gcdSize, holderSize
end

function MouseRing:Layout()
    if not self.holder or not self.db then return end

    local baseSize, gcdSize, holderSize = self:CalculateSizes()

    self.holder:SetSize(holderSize, holderSize)

    -- Cursor Ring (DENTRO)
    self.ringFrame:SetSize(baseSize, baseSize)
    self.ringFrame:ClearAllPoints()
    self.ringFrame:SetPoint("CENTER", self.holder, "CENTER", 0, 0)

    -- GCD Cooldown Frame (MEDIO) - Verificar que existe
    if self.gcdCooldown then
        self.gcdCooldown:SetSize(gcdSize, gcdSize)
        self.gcdCooldown:ClearAllPoints()
        self.gcdCooldown:SetPoint("CENTER", self.holder, "CENTER", 0, 0)
    end
end

function MouseRing:ApplyRing()
    if not self.ringTex or not self.ringFrame or not self.db then return end
    local db = self.db

    self.ringTex:SetTexture(GetRingTexturePath(db))
    self.ringTex:SetVertexColor(
        Clamp01(db.ringColorR),
        Clamp01(db.ringColorG),
        Clamp01(db.ringColorB)
    )
    self.ringTex:SetAlpha(Clamp01(db.ringAlpha))

    self:Layout()
end

function MouseRing:ApplyGCDStyle()
    if not self.gcdCooldown or not self.db then return end
    local db = self.db

    local r, g, b, a = Clamp01(db.ringColorR), Clamp01(db.ringColorG), Clamp01(db.ringColorB), Clamp01(db.ringAlpha)

    self.gcdCooldown:SetSwipeTexture(GetRingTexturePath(db))
    self.gcdCooldown:SetSwipeColor(r, g, b, a)
    -- Invertir lógica: true = normal, false = reverso
    self.gcdCooldown:SetReverse(not (db.gcdReverse == true))
    self.gcdReverse = db.gcdReverse == true
end

-------------------------------------------------
-- Update Logic
-------------------------------------------------

function MouseRing:UpdateGCD()
    if not self.db or not self.gcdCooldown then return end
    local db = self.db

    if db.gcdEnabled == false then
        self.gcdCooldown:Hide()
        self._gcdActive = false
        self._gcdStart, self._gcdDur = nil, nil

        if db.gcdShowOnly == true and self.holder then
            self.holder:Hide()
        end
        return
    end

    local active, start, dur = GetGCDCooldownInfo()

    if not active then
        self.gcdCooldown:Hide()
        self._gcdActive = false
        self._gcdStart, self._gcdDur = nil, nil

        if db.gcdShowOnly == true and self.holder then
            self.holder:Hide()
        end
        return
    end

    self._gcdActive = true

    -- Solo resetear si es un GCD nuevo (anti-tirones)
    if self._gcdStart ~= start or self._gcdDur ~= dur then
        self._gcdStart = start
        self._gcdDur = dur
        self.gcdCooldown:SetCooldown(start, dur)
    end

    self.gcdCooldown:Show()

    if db.gcdShowOnly == true and self.holder then
        self.holder:Show()
    end
end

function MouseRing:Update(refreshLayout)
    if not self.holder or not self.db then return end
    local db = self.db

    local show = (db.enabled ~= false)

    if show and db.gcdShowOnly == true then
        local active = GetGCDCooldownInfo()
        show = active
    end

    self.holder:SetShown(show)

    if show then
        if refreshLayout then
            self:ApplyRing()
            self:ApplyGCDStyle()
            self:Layout()
        end

        self:UpdateGCD()
    else
        if self.gcdCooldown then self.gcdCooldown:Hide() end
        self._gcdActive = false
        self._gcdStart, self._gcdDur = nil, nil
    end
end

-------------------------------------------------
-- Events
-------------------------------------------------
MouseRing.events.PLAYER_ENTERING_WORLD = function(self)
    self:Update(true)
end

MouseRing.events.SPELL_UPDATE_COOLDOWN = function(self)
    self:UpdateGCD()
end

-------------------------------------------------
-- Options Application
-------------------------------------------------
function MouseRing:ApplyOptions()
    if not self.holder or not self.db then return end

    self.db = DB:EnsureDB(self.name, defaults)

    self:ApplyRing()
    self:ApplyGCDStyle()
    self:Layout()

    self:Update(true)
end

-------------------------------------------------
-- Lifecycle
-------------------------------------------------
function MouseRing:OnInit()
    self.db = DB:EnsureDB(self.name, defaults)
    self.enabled = (self.db.enabled ~= false)

    if self.__initialized and self.holder then
        self:Update(true)
        return
    end
    self.__initialized = true

    local holder = CreateFrame("Frame", "BS_MouseRingHolder", UIParent)
    holder:SetFrameStrata("TOOLTIP")
    holder:SetFrameLevel(200)
    holder:Hide()
    self.holder = holder

    -- Cursor Ring (DENTRO)
    local ringFrame = CreateFrame("Frame", "$parent_Ring", holder)
    ringFrame:SetFrameStrata("TOOLTIP")
    ringFrame:SetFrameLevel(holder:GetFrameLevel() + 1)
    self.ringFrame = ringFrame

    local ringTex = ringFrame:CreateTexture(nil, "BACKGROUND", nil, 0)
    ringTex:SetAllPoints(ringFrame)
    ringTex:SetBlendMode("BLEND")
    self.ringTex = ringTex

    -- GCD Cooldown Frame (MEDIO) - Efecto swipe de arco creciente
    local gcdCooldown = CreateFrame("Cooldown", "$parent_GCD", holder, "CooldownFrameTemplate")
    gcdCooldown:SetFrameStrata("TOOLTIP")
    gcdCooldown:SetFrameLevel(holder:GetFrameLevel() + 2)
    gcdCooldown:SetDrawEdge(false)
    gcdCooldown:SetDrawBling(false)
    gcdCooldown:SetDrawSwipe(true)
    gcdCooldown:SetSwipeTexture(GetRingTexturePath(self.db))
    gcdCooldown:Hide()
    SetupCooldownTextHiding(gcdCooldown)
    self.gcdCooldown = gcdCooldown

    self._gcdActive = false
    self._gcdStart, self._gcdDur = nil, nil
    self.gcdReverse = false

    Events:RegisterEvent("PLAYER_ENTERING_WORLD")
    Events:RegisterEvent("SPELL_UPDATE_COOLDOWN")

    local lastX, lastY

    holder:SetScript("OnUpdate", function()
        if not holder:IsShown() then return end

        local cx, cy = GetCursorPosition()

        if cx ~= lastX or cy ~= lastY then
            lastX, lastY = cx, cy

            local scale = UIParent:GetEffectiveScale()
            local ox = ToNumber(self.db.x, 0)
            local oy = ToNumber(self.db.y, 0)

            holder:ClearAllPoints()
            holder:SetPoint("CENTER", UIParent, "BOTTOMLEFT", (cx / scale) + ox, (cy / scale) + oy)
        end
    end)

    self:Update(true)
end

function MouseRing:OnDisabled()
    self.db = DB:EnsureDB(self.name, defaults)
    self.enabled = false
    if self.db then self.db.enabled = false end
    
    if BS.Tickers and BS.Tickers.Stop then
        BS.Tickers:Stop(self)
    end

    -- Hide UI immediately
    if self.frame then
        self.frame:Hide()
    end
    self._gcdActive = false
    self._gcdStart, self._gcdDur = nil, nil
end
