-- Modules/BuffTracker/Data.lua
-- @module BuffTracker.Data
--
-- Holds the static buff definitions + a few small helpers used by the engine.
-- NOTE: This file intentionally keeps "data" concerns separated from UI/logic.

local _, BS = ...

local Data = {}
BS.BuffTrackerData = Data

-------------------------------------------------
-- Buff definitions
-- (Same gameplay behavior as before; formatting and helpers are rewritten.)
-------------------------------------------------

Data.RaidBuffs = {
    { spellIDs = 1459,   key = "intellect",   name = "Arcane Intellect",        class = "MAGE" },
    { spellIDs = 6673,   key = "attackPower", name = "Battle Shout",            class = "WARRIOR" },
    {
        spellIDs = {
            381732, 381741, 381746, 381748, 381749, 381750, 381751,
            381752, 381753, 381754, 381756, 381757, 381758,
        },
        key = "bronze",
        name = "Blessing of the Bronze",
        class = "EVOKER",
    },
    { spellIDs = 1126,   key = "versatility", name = "Mark of the Wild",        class = "DRUID" },
    { spellIDs = 21562,  key = "stamina",     name = "Power Word: Fortitude",   class = "PRIEST" },
    { spellIDs = 462854, key = "skyfury",     name = "Skyfury",                 class = "SHAMAN" },
}

Data.PresenceBuffs = {
    { spellIDs = 381637, key = "atrophicPoison", name = "Atrophic Poison", class = "ROGUE",   missingText = "NO\nPOISON" },
    { spellIDs = 465,    key = "devotionAura",   name = "Devotion Aura",   class = "PALADIN", missingText = "NO\nAURA" },
    {
        spellIDs = 20707,
        key = "soulstone",
        name = "Soulstone",
        class = "WARLOCK",
        missingText = "NO\nSTONE",
        infoTooltip = "Ready Check Only|This buff is only shown during ready checks.",
    },
}

Data.PersonalBuffs = {
    -- Paladin beacons
    { spellIDs = 156910, key = "beaconOfFaith", name = "Beacon of Faith", class = "PALADIN", missingText = "NO\nFAITH", groupId = "beacons" },
    {
        spellIDs = 53563,
        key = "beaconOfLight",
        name = "Beacon of Light",
        class = "PALADIN",
        missingText = "NO\nLIGHT",
        groupId = "beacons",
        excludeTalentSpellID = 200025, -- hide when Beacon of Virtue is known
        iconOverride = 236247,         -- force original icon
    },

    -- Shaman Earth Shield (cast on others)
    {
        spellIDs = 974,
        key = "earthShieldOthers",
        name = "Earth Shield",
        class = "SHAMAN",
        missingText = "NO\nES",
        infoTooltip =
            "May Show Extra Icon|Until you cast this, you might see both this and the Water/Lightning Shield reminder.",
    },

    -- Evoker
    {
        spellIDs = 369459,
        key = "sourceOfMagic",
        name = "Source of Magic",
        class = "EVOKER",
        beneficiaryRole = "HEALER",
        missingText = "NO\nSOURCE",
    },

    -- Druid
    {
        spellIDs = 474750,
        key = "symbioticRelationship",
        name = "Symbiotic Relationship",
        class = "DRUID",
        missingText = "NO\nLINK",
    },
}

Data.SelfBuffs = {
    -- Paladin weapon rites
    {
        spellIDs = 433583,
        key = "riteOfAdjuration",
        name = "Rite of Adjuration",
        class = "PALADIN",
        missingText = "NO\nRITE",
        enchantID = 7144,
        groupId = "paladinRites",
    },
    {
        spellIDs = 433568,
        key = "riteOfSanctification",
        name = "Rite of Sanctification",
        class = "PALADIN",
        missingText = "NO\nRITE",
        enchantID = 7143,
        groupId = "paladinRites",
    },

    -- Priest
    { spellIDs = 232698, key = "shadowform", name = "Shadowform", class = "PRIEST", missingText = "NO\nFORM" },

    -- Shaman weapon imbues
    {
        spellIDs = 382021,
        key = "earthlivingWeapon",
        name = "Earthliving Weapon",
        class = "SHAMAN",
        missingText = "NO\nEL",
        enchantID = 6498,
        groupId = "shamanImbues",
    },
    {
        spellIDs = 318038,
        key = "flametongueWeapon",
        name = "Flametongue Weapon",
        class = "SHAMAN",
        missingText = "NO\nFT",
        enchantID = 5400,
        groupId = "shamanImbues",
    },
    {
        spellIDs = 33757,
        key = "windfuryWeapon",
        name = "Windfury Weapon",
        class = "SHAMAN",
        missingText = "NO\nWF",
        enchantID = 5401,
        groupId = "shamanImbues",
    },

    -- Shaman shields (elemental orbit talent)
    {
        spellIDs = 974,             -- spell (icon and spell check)
        buffIdOverride = 383648,    -- passive self-buff to check
        key = "earthShieldSelfEO",
        name = "Earth Shield (Self)",
        class = "SHAMAN",
        missingText = "NO\nSELF ES",
        requiresTalentSpellID = 383010,
        groupId = "shamanShields",
    },
    {
        spellIDs = { 192106, 52127 },
        key = "waterLightningShieldEO",
        name = "Water/Lightning Shield",
        class = "SHAMAN",
        missingText = "NO\nSHIELD",
        requiresTalentSpellID = 383010,
        groupId = "shamanShields",
        iconByRole = { HEALER = 52127, DAMAGER = 192106, TANK = 192106 },
    },
    {
        spellIDs = { 974, 192106, 52127 },
        key = "shamanShieldBasic",
        name = "Shield (No Talent)",
        class = "SHAMAN",
        missingText = "NO\nSHIELD",
        excludeTalentSpellID = 383010,
        groupId = "shamanShields",
        iconByRole = { HEALER = 52127, DAMAGER = 192106, TANK = 192106 },
    },
}

Data.BuffGroups = {
    beacons = { displayName = "Beacons", missingText = "NO\nBEACONS" },
    shamanImbues = { displayName = "Shaman Imbues" },
    paladinRites = { displayName = "Paladin Rites" },
    shamanShields = { displayName = "Shaman Shields" },
}

-- nil => everyone benefits. If table => only listed classes counted.
Data.BuffBeneficiaries = {
    intellect = {
        MAGE = true, WARLOCK = true, PRIEST = true, DRUID = true, SHAMAN = true, MONK = true, EVOKER = true, PALADIN = true,
        DEMONHUNTER = true,
    },
    attackPower = {
        WARRIOR = true, ROGUE = true, HUNTER = true, DEATHKNIGHT = true, PALADIN = true, MONK = true, DRUID = true, DEMONHUNTER = true,
        SHAMAN = true,
    },
}

-------------------------------------------------
-- Helpers used by the engine
-------------------------------------------------

Data.IconOverrides = Data.IconOverrides or {}

local function AsArray(v)
    if type(v) == "table" then return v end
    if type(v) == "number" then return { v } end
    return {}
end

--- Rebuild the "spellID -> iconID" override map for talent-replaced spells.
function Data:BuildIconOverrides()
    wipe(self.IconOverrides)
    local sources = { self.PresenceBuffs, self.PersonalBuffs, self.SelfBuffs }
    for i = 1, #sources do
        local list = sources[i]
        for j = 1, #list do
            local buff = list[j]
            local override = buff and buff.iconOverride
            if override then
                local ids = AsArray(buff.spellIDs)
                for k = 1, #ids do
                    self.IconOverrides[ids[k]] = override
                end
            end
        end
    end
end

--- Normalize input to a numeric array. Engine calls this frequently.
function Data:NormalizeSpellIDs(spellIDs)
    return AsArray(spellIDs)
end

--- Returns the DB toggle key for a buff (groupId merges multiple entries).
function Data:GetSettingKey(buff)
    return (buff and buff.groupId) or (buff and buff.key)
end

return Data
