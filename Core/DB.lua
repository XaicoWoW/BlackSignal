-- Core/DB.lua
-- @module DB
-- @alias DB
-- Database system using AceDB-3.0 with backward compatibility layer

local BS = _G.BS
local AceDB = LibStub("AceDB-3.0")

-------------------------------------------------
-- AceDB-3.0 Integration
-------------------------------------------------

--- Default database structure for BlackSignal
-- This defines the default values for the entire addon database
local dbDefaults = {
    profile = {
        modules = {},
        minimap = {
            hide = false,
            minimapPos = 180,
            lock = false,
        }
    }
}

-------------------------------------------------
-- Initialize AceDB
-------------------------------------------------

--- The main database object (initialized on ADDON_LOADED)
local db = nil

--- Initialize the database system with AceDB
-- This is called when the addon is loaded
local function InitializeDB()
    if not db then
        -- Create the database using AceDB
        db = AceDB:New("BlackSignalDB", dbDefaults, true)

        if not db then
            error("BlackSignal: Failed to initialize database with AceDB-3.0")
        end
    end
    return db
end

-------------------------------------------------
-- Backward Compatibility API
-------------------------------------------------

-- Use the table created by Init.lua, don't create a new one
local DB = BS.DB

--- Store a reference to the AceDB object
-- Internal use only
DB._db = nil

--- Initialize the database structure (internal use)
--- @local
--- @return table DB The initialized database
local function Initialize()
    if not DB._db then
        DB._db = InitializeDB()
    end
    return DB._db.profile
end

--- Ensure the database for a specific module with defaults
-- This function provides backward compatibility with the old API
-- It uses AceDB namespaces internally
--- @param moduleName string The module name
--- @param defaults table The default values for the moduleName
--- @return table The ensured database for the moduleName
function DB:EnsureDB(moduleName, defaults)
    local profile = Initialize()

    -- Ensure the modules table exists
    profile.modules = profile.modules or {}
    profile.modules[moduleName] = profile.modules[moduleName] or {}

    local mdb = profile.modules[moduleName]

    -- Apply defaults for any missing values
    if defaults then
        for k, v in pairs(defaults) do
            if mdb[k] == nil then
                mdb[k] = v
            end
        end
    end

    return mdb
end

--- Get the database for the minimap button
--- @param defaults table The default values for the minimap
--- @return table The minimap database
function DB:MinimapDB(defaults)
    local profile = Initialize()

    -- Ensure the minimap table exists
    profile.minimap = profile.minimap or {}

    local mdb = profile.minimap

    -- Apply defaults for any missing values
    if defaults then
        for k, v in pairs(defaults) do
            if mdb[k] == nil then
                mdb[k] = v
            end
        end
    end

    return mdb
end

--- Get the raw AceDB object (for advanced usage)
--- @return table The AceDB database object
function DB:GetDB()
    if not DB._db then
        DB._db = InitializeDB()
    end
    return DB._db
end

--- Get the current profile
--- @return string The name of the current profile
function DB:GetCurrentProfile()
    local dbObj = DB:GetDB()
    return dbObj:GetCurrentProfile()
end

--- Set the current profile
--- @param name string The name of the profile to switch to
function DB:SetProfile(name)
    local dbObj = DB:GetDB()
    dbObj:SetProfile(name)
end

--- Get a list of all profiles
--- @return table A list of profile names
function DB:GetProfiles()
    local dbObj = DB:GetDB()
    return dbObj:GetProfiles()
end

--- Delete a profile
--- @param name string The name of the profile to delete
function DB:DeleteProfile(name)
    local dbObj = DB:GetDB()
    dbObj:DeleteProfile(name, true)
end

--- Copy settings from one profile to another
--- @param from string The source profile name
--- @param to string The destination profile name
function DB:CopyProfile(from, to)
    local dbObj = DB:GetDB()
    local currentProfile = dbObj:GetCurrentProfile()
    dbObj:SetProfile(to)
    dbObj:CopyProfile(from, true)
    dbObj:SetProfile(currentProfile)
end

--- Reset the current profile to defaults
function DB:ResetProfile()
    local dbObj = DB:GetDB()
    dbObj:ResetProfile(true)
end

-------------------------------------------------
-- Load the database from the saved variables
-------------------------------------------------

local eventFrame = CreateFrame("Frame")

--- Handle the ADDON_LOADED event to initialize the database
eventFrame:RegisterEvent("ADDON_LOADED")

--- Event handler for ADDON_LOADED
eventFrame:SetScript("OnEvent", function(_, event, arg1)
    if event == "ADDON_LOADED" and arg1 == "BlackSignal" then
        -- Initialize the database with AceDB
        InitializeDB()

        -- Unregister the event since we don't need it anymore
        eventFrame:UnregisterEvent("ADDON_LOADED")
    end
end)

-------------------------------------------------
-- AceDB Callbacks (optional)
-------------------------------------------------

--[[
You can register callbacks to be notified when the database changes:

db.RegisterCallback(self, "OnProfileChanged", "OnProfileChanged")
db.RegisterCallback(self, "OnProfileCopied", "OnProfileCopied")
db.RegisterCallback(self, "OnProfileReset", "OnProfileReset")
db.RegisterCallback(self, "OnDatabaseShutdown", "OnDatabaseShutdown")

Example:
function MyModule:OnProfileChanged(event, database)
    -- Reload settings when profile changes
    self:ApplyOptions()
end
]]

return DB
