-- Modules/BuffTracker/Engine.lua
-- @module BuffTrackerEngine

local _, BS = ...

local Engine         = {}
BS.BuffTrackerEngine = Engine

local GetUnitAuraBySpellID = C_UnitAuras and C_UnitAuras.GetUnitAuraBySpellID
local GetSpellTexture      = C_Spell and C_Spell.GetSpellTexture

-------------------------------------------------
-- Constants
-------------------------------------------------
local EXPIRATION_THRESHOLD_SECONDS = 5 * 60 -- 5 minutes (fixed, not configurable)

-------------------------------------------------
-- Utils
-------------------------------------------------
local function GetPlayerClass()
  local class = UnitClassBase and UnitClassBase("player")
  if class then return class end
  local _, c = UnitClass("player")
  return c
end

local function GetPlayerRole()
  local spec = GetSpecialization()
  if spec then
    return GetSpecializationRole(spec)
  end
  return nil
end

local function IsValidGroupMember(unit)
  return UnitExists(unit)
      and not UnitIsDeadOrGhost(unit)
      and UnitIsConnected(unit)
      and UnitCanAssist("player", unit)
end

local function IterateGroupMembers(cb)
  local inRaid = IsInRaid()
  local groupSize = GetNumGroupMembers()

  if groupSize == 0 then
    cb("player")
    return
  end

  for i = 1, groupSize do
    local unit
    if inRaid then
      unit = "raid" .. i
    else
      unit = (i == 1) and "player" or ("party" .. (i - 1))
    end

    if IsValidGroupMember(unit) then
      cb(unit)
    end
  end
end

local function UnitHasBuff(unit, spellIDs)
  if not GetUnitAuraBySpellID then
    return false, nil, nil
  end

  if type(spellIDs) ~= "table" then spellIDs = { spellIDs } end

  for _, id in ipairs(spellIDs) do
    local auraData
    pcall(function()
      auraData = GetUnitAuraBySpellID(unit, id)
    end)

    if auraData then
      local remaining = nil
      if auraData.expirationTime and auraData.expirationTime > 0 then
        remaining = auraData.expirationTime - GetTime()
      end
      return true, remaining, auraData.sourceUnit
    end
  end

  return false, nil, nil
end

local function GetGroupClasses()
  local classes = {}

  if GetNumGroupMembers() == 0 then
    local pc = GetPlayerClass()
    if pc then classes[pc] = true end
    return classes
  end

  IterateGroupMembers(function(unit)
    local _, c = UnitClass(unit)
    if c then classes[c] = true end
  end)

  return classes
end

local function CountMissingBuff(spellIDs, buffKey, beneficiariesByKey, playerOnly, playerClass)
  local missing, total = 0, 0
  local minRemaining = nil
  local beneficiaries = beneficiariesByKey and beneficiariesByKey[buffKey]

  if playerOnly or GetNumGroupMembers() == 0 then
    if beneficiaries and not beneficiaries[playerClass] then
      return 0, 0, nil
    end

    total = 1
    local has, remaining = UnitHasBuff("player", spellIDs)
    if not has then
      missing = 1
    elseif type(remaining) == "number" then
      minRemaining = remaining
    end

    return missing, total, minRemaining
  end

  IterateGroupMembers(function(unit)
    local _, unitClass = UnitClass(unit)

    if (not beneficiaries) or (unitClass and beneficiaries[unitClass]) then
      total = total + 1

      local has, remaining = UnitHasBuff(unit, spellIDs)
      if not has then
        missing = missing + 1
      elseif type(remaining) == "number" then
        if (not minRemaining) or (remaining < minRemaining) then
          minRemaining = remaining
        end
      end
    end
  end)

  return missing, total, minRemaining
end

local function CountPresenceBuff(spellIDs, playerOnly)
  local found = 0
  local minRemaining = nil

  if playerOnly or GetNumGroupMembers() == 0 then
    local has, remaining = UnitHasBuff("player", spellIDs)
    if has then
      found = 1
      if type(remaining) == "number" then
        minRemaining = remaining
      end
    end
    return found, minRemaining
  end

  IterateGroupMembers(function(unit)
    local has, remaining = UnitHasBuff(unit, spellIDs)
    if has then
      found = found + 1

      if type(remaining) == "number" then
        if (not minRemaining) or (remaining < minRemaining) then
          minRemaining = remaining
        end
      end
    end
  end)

  return found, minRemaining
end

local function IsPlayerBuffActiveOnGroup(spellID, role)
  local found = false

  IterateGroupMembers(function(unit)
    if found then return end

    if (not role) or UnitGroupRolesAssigned(unit) == role then
      local has, _, sourceUnit = UnitHasBuff(unit, spellID)
      if has and sourceUnit and UnitIsUnit(sourceUnit, "player") then
        found = true
      end
    end
  end)

  return found
end

local function ShouldShowPersonalBuff(spellIDs, requiredClass, beneficiaryRole, playerClass)
  if playerClass ~= requiredClass then return nil end

  local spellID = (type(spellIDs) == "table") and spellIDs[1] or spellIDs
  if not IsPlayerSpell(spellID) then return nil end
  if GetNumGroupMembers() == 0 then return nil end

  return not IsPlayerBuffActiveOnGroup(spellID, beneficiaryRole)
end

local function ShouldShowSelfBuff(spellIDs, requiredClass, enchantID, requiresTalent, excludeTalent, buffIdOverride, playerClass)
  if playerClass ~= requiredClass then return nil end

  if requiresTalent and not IsPlayerSpell(requiresTalent) then return nil end
  if excludeTalent and IsPlayerSpell(excludeTalent) then return nil end

  local list = (type(spellIDs) == "table") and spellIDs or { spellIDs }
  local knowsAny = false
  for _, id in ipairs(list) do
    if IsPlayerSpell(id) then
      knowsAny = true
      break
    end
  end
  if not knowsAny then return nil end

  if enchantID then
    local _, _, _, mainEnchant, _, _, _, offEnchant = GetWeaponEnchantInfo()
    return (mainEnchant ~= enchantID) and (offEnchant ~= enchantID)
  end

  local has = UnitHasBuff("player", buffIdOverride or spellIDs)
  return not has
end

local function GetBuffTexture(data, spellIDs, iconByRole)
  local id

  if iconByRole then
    local role = GetPlayerRole()
    if role and iconByRole[role] then
      id = iconByRole[role]
    end
  end

  if not id then
    id = (type(spellIDs) == "table") and spellIDs[1] or spellIDs
  end

  if data.IconOverrides and data.IconOverrides[id] then
    return data.IconOverrides[id]
  end

  local tex
  pcall(function()
    tex = GetSpellTexture(id)
  end)
  return tex
end

local function FirstSpellID(spellIDs)
  if type(spellIDs) == "table" then
    return spellIDs[1]
  end
  return spellIDs
end

local function ReadyCheckOnly(buff)
  return buff.infoTooltip and buff.infoTooltip:match("^Ready Check Only")
end

-------------------------------------------------
-- View model builder
-------------------------------------------------
function Engine:BuildViewModel(module, force)
  local db = module.db
  local data = module.Data
  if not db or db.enabled == false or not data then
    return { items = {} }
  end

  if not data._overridesBuilt then
    data:BuildIconOverrides()
    data._overridesBuilt = true
  end

  -- Visibility gates
  if db.showOnlyInGroup and (GetNumGroupMembers() == 0) then
    return { items = {} }
  end
  if db.showOnlyInInstance and not IsInInstance() then
    return { items = {} }
  end
  if C_ChallengeMode and C_ChallengeMode.IsChallengeModeActive and C_ChallengeMode.IsChallengeModeActive() then
    return { items = {} }
  end
  if db.showOnlyOnReadyCheck and not module._inReadyCheck then
    return { items = {} }
  end

  local playerClass   = GetPlayerClass()
  local presentClasses = GetGroupClasses()
  local playerOnly    = (db.showOnlyPlayerMissing == true)

  local items = {}

  -------------------------------------------------
  -- RAID BUFFS
  -------------------------------------------------
  if db.categories and db.categories.raid ~= false then
    for _, buff in ipairs(data.RaidBuffs) do
      local showBuff =
          (not db.showOnlyPlayerClassBuff or buff.class == playerClass)
          and (presentClasses[buff.class] == true)

      if showBuff then
        local spellIDs = data:NormalizeSpellIDs(buff.spellIDs)
        local missing, total, minRemaining =
            CountMissingBuff(spellIDs, buff.key, data.BuffBeneficiaries, playerOnly, playerClass)

        local expiringSoon =
            (db.showExpirationGlow == true)
            and type(minRemaining) == "number"
            and minRemaining > 0
            and minRemaining < EXPIRATION_THRESHOLD_SECONDS

        if missing > 0 or expiringSoon then
          local text = ""
          if missing > 0 then
            text = playerOnly and "" or ((total - missing) .. "/" .. total)
          end

          items[#items + 1] = {
            key          = buff.key,
            category     = "raid",
            icon         = GetBuffTexture(data, spellIDs),
            text         = text,
            tooltipSpellID = FirstSpellID(spellIDs),
            timeLeft     = expiringSoon and minRemaining or nil,
            missing      = (missing > 0),
            expiringSoon = expiringSoon,
          }
        end
      end
    end
  end

  -------------------------------------------------
  -- PRESENCE BUFFS
  -------------------------------------------------
  if db.categories and db.categories.presence ~= false then
    for _, buff in ipairs(data.PresenceBuffs) do
      local readyCheckOnly = ReadyCheckOnly(buff)

      local spellForIsPlayerSpell = (type(buff.spellIDs) == "table") and buff.spellIDs[1] or buff.spellIDs
      local showBuff =
          (not readyCheckOnly or module._inReadyCheck)
          and (not db.showOnlyPlayerClassBuff or buff.class == playerClass)
          and (presentClasses[buff.class] == true)
          and IsPlayerSpell(spellForIsPlayerSpell)
          and (not buff.excludeTalentSpellID or not IsPlayerSpell(buff.excludeTalentSpellID))

      if showBuff then
        local spellIDs = data:NormalizeSpellIDs(buff.spellIDs)
        local count, minRemaining = CountPresenceBuff(spellIDs, playerOnly)

        local expiringSoon =
            (db.showExpirationGlow == true)
            and type(minRemaining) == "number"
            and minRemaining > 0
            and minRemaining < EXPIRATION_THRESHOLD_SECONDS

        if count == 0 or expiringSoon then
          items[#items + 1] = {
            key           = buff.key,
            category      = "presence",
            icon          = GetBuffTexture(data, spellIDs),
            text          = (count == 0) and (buff.missingText or "") or "",
            tooltipSpellID = FirstSpellID(spellIDs),
            timeLeft      = expiringSoon and minRemaining or nil,
            missing       = (count == 0),
            expiringSoon  = expiringSoon,
            tooltip       = buff.infoTooltip,
          }
        end
      end
    end
  end

  -------------------------------------------------
  -- PERSONAL BUFFS
  -------------------------------------------------
  if db.categories and db.categories.personal ~= false then
    local visibleGroups = {}

    for _, buff in ipairs(data.PersonalBuffs) do
      if not (buff.excludeTalentSpellID and IsPlayerSpell(buff.excludeTalentSpellID)) then
        local shouldShow = ShouldShowPersonalBuff(buff.spellIDs, buff.class, buff.beneficiaryRole, playerClass)
        if shouldShow then
          local spellIDs = data:NormalizeSpellIDs(buff.spellIDs)
          local icon = GetBuffTexture(data, spellIDs, buff.iconByRole)

          local it = {
            key           = buff.key,
            category      = "personal",
            groupId       = buff.groupId,
            icon          = icon,
            text          = buff.missingText or "",
            tooltipSpellID = FirstSpellID(spellIDs),
            missing       = true,
            tooltip       = buff.infoTooltip,
          }
          items[#items + 1] = it

          if buff.groupId then
            visibleGroups[buff.groupId] = visibleGroups[buff.groupId] or {}
            table.insert(visibleGroups[buff.groupId], it)
          end
        end
      end
    end

    -- Merge grouped buffs that are both visible
    for groupId, groupItems in pairs(visibleGroups) do
      if #groupItems >= 2 then
        local groupInfo = data.BuffGroups and data.BuffGroups[groupId]
        groupItems[1].text = (groupInfo and groupInfo.missingText) or groupItems[1].text
        for i = 2, #groupItems do
          groupItems[i]._hide = true
        end
      end
    end
  end

  -------------------------------------------------
  -- SELF BUFFS
  -------------------------------------------------
  if db.categories and db.categories.self ~= false then
    for _, buff in ipairs(data.SelfBuffs) do
      local shouldShow = ShouldShowSelfBuff(
        buff.spellIDs,
        buff.class,
        buff.enchantID,
        buff.requiresTalentSpellID,
        buff.excludeTalentSpellID,
        buff.buffIdOverride,
        playerClass
      )

      if shouldShow then
        local spellIDs = data:NormalizeSpellIDs(buff.spellIDs)
        local icon = GetBuffTexture(data, spellIDs, buff.iconByRole)

        items[#items + 1] = {
          key           = buff.key,
          category      = "self",
          groupId       = buff.groupId,
          icon          = icon,
          text          = buff.missingText or "",
          tooltipSpellID = FirstSpellID(spellIDs),
          missing       = true,
          tooltip       = buff.infoTooltip,
        }
      end
    end
  end

  -------------------------------------------------
  -- Filter hidden-from-merge
  -------------------------------------------------
  if #items > 0 then
    local filtered = {}
    for i = 1, #items do
      if not items[i]._hide then
        filtered[#filtered + 1] = items[i]
      end
    end
    items = filtered
  end

  return { items = items }
end
