-- Core/DB.lua

local BS = _G.BS or {}
_G.BS = BS
BS.modules = BS.modules or {}

_G.BlackSignal = _G.BlackSignal or { profile = { modules = {} } }
local BlackSignal = _G.BlackSignal

local DB = {}
BS.DB = DB

local function EnsureProfile()
    BlackSignal.profile = BlackSignal.profile or {}
    BlackSignal.profile.modules = BlackSignal.profile.modules or {}
end

function DB:BuildDefaults(module)
    if type(module) ~= "table" then return {} end

    if type(module.BuildDefaults) == "function" then
        local ok, defs = pcall(module.BuildDefaults, module)
        if ok and type(defs) == "table" then
            return defs
        end
    end

    if type(module.defaults) == "table" then
        return module.defaults
    end

    return {
        enabled  = module.enabled ~= false,
        x        = 0,
        y        = 0,
        fontSize = 16,
        font     = "Fonts\\FRIZQT__.TTF",
        text     = "",
    }
end

function DB:EnsureModuleDB(moduleName, defaults)
    if not moduleName or moduleName == "" then
        return {}
    end

    EnsureProfile()

    BlackSignal.profile.modules[moduleName] = BlackSignal.profile.modules[moduleName] or {}
    local db = BlackSignal.profile.modules[moduleName]

    for k, v in pairs(defaults or {}) do
        if db[k] == nil then
            db[k] = v
        end
    end

    return db
end

function DB:EnsureModule(module)
    if type(module) ~= "table" or not module.name then return nil end
    local defaults = self:BuildDefaults(module)
    module.db = module.db or self:EnsureModuleDB(module.name, defaults)
    if module.enabled == nil then module.enabled = (module.db.enabled ~= false) end
    return module.db
end

function DB:ApplyModuleState(module)
    if type(module) ~= "table" then return end
    if not module.name then return end

    self:EnsureModule(module)

    if module.frame then
        module.frame:SetShown(module.enabled ~= false)
        if module.frame.ClearAllPoints and module.frame.SetPoint then
            module.frame:ClearAllPoints()
            module.frame:SetPoint("CENTER", UIParent, "CENTER", module.db.x or 0, module.db.y or 0)
        end
    end

    if module.text and module.text.SetFont then
        local size = tonumber(module.db.fontSize) or 16
        local font = module.db.font or "Fonts\\FRIZQT__.TTF"
        module.text:SetFont(font, size, "OUTLINE")
    end

    if module.Update then
        pcall(module.Update, module)
    end
end
