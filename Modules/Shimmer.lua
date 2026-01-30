-- Modules/Shimmer.lua
local BS = _G.BS

local Shimmer = {
  name = "Shimmer",
  enabled = true,
  classes = "MAGE",
  events = {},
}

BS:RegisterModule(Shimmer)

-------------------------------------------------
-- Constants
-------------------------------------------------
local GetSpellCooldown = C_Spell.GetSpellCooldown
local BLINK_ID   = 1953
local SHIMMER_ID = 212653

local defaults = {
  enabled  = true,
  x        = 0,
  y        = 18,
  fontSize = 20,
  text     = "No Shimmer: ",
  font     = "Fonts\\FRIZQT__.TTF"
}

-------------------------------------------------
-- DB (Ensure + Migration)
-------------------------------------------------
local function EnsureDB()
  _G.BlackSignal = _G.BlackSignal or {}
  local db = _G.BlackSignal

  db.profile = db.profile or {}
  db.profile.modules = db.profile.modules or {}
  db.profile.modules.Shimmer = db.profile.modules.Shimmer or {}
  local mdb = db.profile.modules.Shimmer

  if db.modules and db.modules.Shimmer and type(db.modules.Shimmer) == "table" then
    for k, v in pairs(db.modules.Shimmer) do
      if mdb[k] == nil then
        mdb[k] = v
      end
    end
  end

  if mdb.enabled == nil and db.shimmercd_enabled ~= nil then mdb.enabled = db.shimmercd_enabled end
  if mdb.fontSize == nil and db.shimmercd_fontSize ~= nil then mdb.fontSize = db.shimmercd_fontSize end
  if mdb.x == nil and db.shimmercd_x ~= nil then mdb.x = db.shimmercd_x end
  if mdb.y == nil and db.shimmercd_y ~= nil then mdb.y = db.shimmercd_y end
  if mdb.text == nil and db.shimmercd_text ~= nil then mdb.text = db.shimmercd_text end
  if mdb.fontSize == nil and db.fontSize ~= nil then mdb.fontSize = db.fontSize end
  if mdb.text == nil and db.text ~= nil then mdb.text = db.text end

  -- Defaults
  for k, v in pairs(defaults) do
    if mdb[k] == nil then
      mdb[k] = v
    end
  end

  return mdb
end

-------------------------------------------------
-- UI
-------------------------------------------------
local function EnsureUI(self)
  if self.frame and self.text then return end

  local displayFrame = CreateFrame("Frame", "BS_ShimmerDisplay", UIParent)
  displayFrame:SetSize(400, 50)
  displayFrame:SetFrameStrata("LOW")
  displayFrame:Show()

  local statusText = displayFrame:CreateFontString(nil, "OVERLAY")
  statusText:SetPoint("CENTER")
  statusText:SetJustifyH("CENTER")
  statusText:SetTextColor(1, 1, 1, 1)

  self.frame = displayFrame
  self.text = statusText
end

local function ApplyPosition(self)
  if not self.frame or not self.db then return end
  self.frame:ClearAllPoints()
  self.frame:SetPoint("CENTER", UIParent, "CENTER", self.db.x or 0, self.db.y or 18)
end

local function ApplyFont(self)
  if not self.text or not self.db then return end
  self.text:SetFont(self.db.font, tonumber(self.db.fontSize) or 20, "OUTLINE")
end

-------------------------------------------------
-- Spell selection
-------------------------------------------------
function Shimmer:ResolveSpell()
  if C_SpellBook.IsSpellKnown(SHIMMER_ID) then
    self.spellID = SHIMMER_ID
  else
    self.spellID = BLINK_ID
  end
end

-------------------------------------------------
-- Update
-------------------------------------------------
function Shimmer:Update()
  if not self.db or self.db.enabled == false then return end
  if not self.spellID or not self.frame or not self.text then return end

  local durationObject = C_Spell.GetSpellCooldownDuration(self.spellID)
---@diagnostic disable-next-line: undefined-field
  if not durationObject or not durationObject.GetRemainingDuration then return end

---@diagnostic disable-next-line: undefined-field
  local actualCooldown = durationObject:GetRemainingDuration(1)

  local prefix = self.db.text or defaults.text

  local cdInfo = GetSpellCooldown(self.spellID)
  local isOnGCD = cdInfo and cdInfo.isOnGCD

  if self.frame.SetAlphaFromBoolean then
    self.frame:SetAlphaFromBoolean(isOnGCD ~= false, 0, 1)
  else
    self.frame:SetAlpha((isOnGCD ~= false) and 1 or 0)
  end

  self.text:SetText(string.format("%s%.1f", prefix, actualCooldown))
end

-------------------------------------------------
-- Ticker
-------------------------------------------------
function Shimmer:StartTicker()
  BS:StopTicker(self)
  BS:RegisterTicker(self, 0.1, function()
    self:Update()
  end)
end

function Shimmer:StopTicker()
  BS:StopTicker(self)
end

-------------------------------------------------
-- Init
-------------------------------------------------
function Shimmer:OnInit()
  self.db = EnsureDB()

  EnsureUI(self)
  ApplyPosition(self)
  ApplyFont(self)

  self:ResolveSpell()

  local enabled = self.db.enabled ~= false
  self.frame:SetShown(enabled)

  if enabled then
    self:StartTicker()
    self:Update()
  else
    self:StopTicker()
  end

  BS:RegisterEvent("SPELL_UPDATE_COOLDOWN")
end

-------------------------------------------------
-- Events
-------------------------------------------------
Shimmer.events.SPELL_UPDATE_COOLDOWN = function(self)
  self:Update()
end

local function TalentUpdate(self)
  C_Timer.After(0.5, function()
    self:ResolveSpell()
  end)
  C_Timer.After(0.6, function()
    if self.db and self.db.enabled ~= false then
      self:StartTicker()
      self:Update()
    end
  end)
end

Shimmer.events.PLAYER_SPECIALIZATION_CHANGED = TalentUpdate
Shimmer.events.TRAIT_CONFIG_UPDATED          = TalentUpdate
Shimmer.events.ACTIVE_TALENT_GROUP_CHANGED   = TalentUpdate