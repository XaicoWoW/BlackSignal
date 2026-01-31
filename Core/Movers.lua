-- Core/Movers.lua
local BS = _G.BS
if not BS then return end

BS.Movers = BS.Movers or {}
local Movers = BS.Movers

Movers._movers  = Movers._movers  or {}  -- key -> data
Movers._holders = Movers._holders or {}  -- key -> holder
Movers._shown   = Movers._shown   or false

-------------------------------------------------
-- DB helper (usa la misma raíz que tus módulos)
-------------------------------------------------
local function EnsureMoversDB()
  _G.BlackSignal = _G.BlackSignal or {}
  local db = _G.BlackSignal
  db.profile = db.profile or {}
  db.profile.movers = db.profile.movers or {}
  return db.profile.movers
end

local function GetDB()
  Movers.db = Movers.db or EnsureMoversDB()
  return Movers.db
end

-------------------------------------------------
-- Utils
-------------------------------------------------
local function SafePoint(p) return p or "CENTER" end
local function SafeRelPoint(p) return p or "CENTER" end

local function ApplyHolderPosition(key, holder)
  local db = GetDB()
  local t = db[key]
  if not t then return false end

  holder:ClearAllPoints()
  holder:SetPoint(
    SafePoint(t.point),
    UIParent,
    SafeRelPoint(t.relPoint),
    tonumber(t.x) or 0,
    tonumber(t.y) or 0
  )
  return true
end

local function SaveHolderPosition(key, holder)
  local db = GetDB()
  db[key] = db[key] or {}

  local point, _, relPoint, x, y = holder:GetPoint(1)
  if not point then return end

  db[key].point = point
  db[key].relPoint = relPoint
  db[key].x = x
  db[key].y = y
end

local function CreateHolder(key)
  local h = CreateFrame("Frame", "BS_MoverHolder_" .. key, UIParent)
  h:SetSize(10, 10)
  h:SetPoint("CENTER")
  h:SetClampedToScreen(true)
  h:SetMovable(true)
  h:EnableMouse(false)
  return h
end

local function CreateMoverOverlay(key, label, w, h)
  local m = CreateFrame("Button", "BS_Mover_" .. key, UIParent, "BackdropTemplate")
  m:SetSize(w or 160, h or 22)
  m:SetFrameStrata("TOOLTIP")
  m:SetClampedToScreen(true)

  m:SetBackdrop({
    bgFile   = "Interface\\Buttons\\WHITE8x8",
    edgeFile = "Interface\\Buttons\\WHITE8x8",
    edgeSize = 1,
    insets   = { left = 1, right = 1, top = 1, bottom = 1 },
  })
  m:SetBackdropColor(0, 0, 0, 0.55)
  m:SetBackdropBorderColor(BS.colorRGB["r"],BS.colorRGB["g"],BS.colorRGB["b"], 1)

  local txt = m:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  txt:SetPoint("CENTER")
  txt:SetText(label or key)
  txt:SetTextColor(BS.colorRGB["r"],BS.colorRGB["g"],BS.colorRGB["b"], 1)
  m.text = txt

  m:RegisterForDrag("LeftButton")
  m:SetMovable(true)
  m:EnableMouse(true)

  return m
end

-------------------------------------------------
-- Public API
-------------------------------------------------

function Movers:Register(frame, key, label, opts)
  if not frame or not key then return end
  opts = opts or {}

  -- Ya registrado → reaplica
  if self._movers[key] then
    self:Apply(key)
    return self._movers[key].mover
  end

  local holder = self._holders[key]
  if not holder then
    holder = CreateHolder(key)
    self._holders[key] = holder
  end

  local db = GetDB()

  -------------------------------------------------
  -- Default position: usa la posición ACTUAL del frame
  -------------------------------------------------
  if not db[key] then
    local cx, cy = frame:GetCenter()
    local ux, uy = UIParent:GetCenter()

    local x, y = 0, 0
    if cx and ux then
      x = math.floor((cx - ux) + 0.5)
      y = math.floor((cy - uy) + 0.5)
    end

    db[key] = {
      point = "CENTER",
      relPoint = "CENTER",
      x = x,
      y = y,
    }
  end

  -------------------------------------------------
  -- Aplica posición al holder
  -------------------------------------------------
  ApplyHolderPosition(key, holder)

  -------------------------------------------------
  -- Ancla frame real al holder
  -------------------------------------------------
  frame:ClearAllPoints()
  frame:SetPoint("CENTER", holder, "CENTER", 0, 0)

  -------------------------------------------------
  -- Tamaño del mover = tamaño real del frame
  -------------------------------------------------
  local w = frame:GetWidth()  or 160
  local h = frame:GetHeight() or 22

  -------------------------------------------------
  -- Mover overlay
  -------------------------------------------------
  local mover = CreateMoverOverlay(key, label or key, w, h)
  mover:ClearAllPoints()
  mover:SetPoint("CENTER", holder, "CENTER", 0, 0)
  mover:SetShown(self._shown)

  mover:SetScript("OnDragStart", function()
    if InCombatLockdown() then
      UIErrorsFrame:AddMessage("BlackSignal: no puedes mover en combate.", 1, 0.2, 0.2)
      return
    end
    holder:StartMoving()
  end)

  mover:SetScript("OnDragStop", function()
    holder:StopMovingOrSizing()
    SaveHolderPosition(key, holder)

    mover:ClearAllPoints()
    mover:SetPoint("CENTER", holder, "CENTER", 0, 0)

    frame:ClearAllPoints()
    frame:SetPoint("CENTER", holder, "CENTER", 0, 0)
  end)

  self._movers[key] = {
    key = key,
    frame = frame,
    holder = holder,
    mover = mover,
  }

  return mover
end


function Movers:Apply(key)
  local data = self._movers[key]
  if not data then return end

  ApplyHolderPosition(key, data.holder)

  data.mover:ClearAllPoints()
  data.mover:SetPoint("CENTER", data.holder, "CENTER", 0, 0)

  data.frame:ClearAllPoints()
  data.frame:SetPoint(data.ap, data.holder, data.arp, 0, 0)
end

function Movers:ApplyAll()
  for key in pairs(self._movers) do
    self:Apply(key)
  end
end

function Movers:Unlock()
  if InCombatLockdown() then
    UIErrorsFrame:AddMessage("BlackSignal: no puedes activar movers en combate.", 1, 0.2, 0.2)
    return
  end
  self._shown = true
  for _, data in pairs(self._movers) do
    data.mover:Show()
  end
end

function Movers:Lock()
  self._shown = false
  for _, data in pairs(self._movers) do
    data.mover:Hide()
  end
end

function Movers:Toggle()
  if self._shown then self:Lock() else self:Unlock() end
end

-- Extra: reset individual
function Movers:Reset(key)
  local db = GetDB()
  db[key] = nil
  self:Apply(key)
end

function Movers:ResetAll()
  local db = GetDB()
  wipe(db)
  self:ApplyAll()
end
