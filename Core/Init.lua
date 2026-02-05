-- Core/Init.lua
-- BlackSignal - Main Addon with Ace3 Integration
-- @module BlackSignal
-- @alias BlackSignal

-- Embed Ace3 libraries
local AceAddon = LibStub("AceAddon-3.0")
local AceEvent = LibStub("AceEvent-3.0")
local AceTimer = LibStub("AceTimer-3.0")
local AceConsole = LibStub("AceConsole-3.0")

-- Create the main addon object with Ace3
local BlackSignal = AceAddon:NewAddon("BlackSignal", "AceEvent-3.0", "AceTimer-3.0", "AceConsole-3.0")

-- Store the addon in the global namespace for backward compatibility
local _, BS = ...
BS = BS or {}

-- Make BS reference the addon object
setmetatable(BS, {__index = BlackSignal})

-- Core module references (will be populated by other files)
BS.API = {}
BS.DB = {}
BS.Events = CreateFrame("Frame")  -- Backward compatibility frame
BS.Tickers = {}
BS.Movers = {}
BS.UI = {}
BS.Utils = {}
BS.MinimapButton = {}
BS.MainPanel = {}
BS.Button = {}
BS.CheckButton = {}
BS.EditBox = {}
BS.ColorPicker = {}
BS.Colors = {}

-- Store the main addon object
BS.Addon = BlackSignal

-------------------------------------------------
-- OnInitialize: Called when addon is loaded
-------------------------------------------------
function BlackSignal:OnInitialize()
    -- Initialize the database system
    -- Note: The actual DB initialization happens in Core/DB.lua
    -- This is just a placeholder for AceAddon's lifecycle
end

-------------------------------------------------
-- OnEnable: Called when addon is enabled (PLAYER_LOGIN)
-------------------------------------------------
function BlackSignal:OnEnable()
    -- The module loading happens via BS.API:Load()
    -- which is called by the Core/Events.lua system
    DEFAULT_CHAT_FRAME:AddMessage("|cff7f3fbfBlackSignal|r loaded. Type /bs for options.")
end

-------------------------------------------------
-- OnDisable: Called when addon is disabled
-------------------------------------------------
function BlackSignal:OnDisable()
    -- Cleanup when addon is disabled
    -- Note: This is rarely used in WoW addons
end

-------------------------------------------------
-- Slash Commands
-------------------------------------------------
-- Register slash commands with AceConsole
-- Note: The actual command handling happens in Core/Config.lua
-- This is just a registration point for AceConsole

-------------------------------------------------
-- Module Management (Backward Compatibility)
-------------------------------------------------
-- These functions provide backward compatibility with the old API
-- while allowing modules to work with the new Ace3-based system

--- Register a module with the BlackSignal API
-- This function provides backward compatibility with the old registration system
-- @param module table The module to register
function BlackSignal:RegisterModule(module)
    if BS.API and BS.API.Register then
        BS.API:Register(module)
    end
end

--- Load all registered modules
-- This function provides backward compatibility with the old loading system
function BlackSignal:LoadModules()
    if BS.API and BS.API.Load then
        BS.API:Load()
    end
end

-------------------------------------------------
-- Event System Integration
-------------------------------------------------
-- BlackSignal uses a custom event dispatching system in Core/Events.lua
-- AceEvent is embedded and available for modules that want to use it directly
-- The custom system provides additional features like unit event filtering

-------------------------------------------------
-- Timer System Integration
-------------------------------------------------
-- BlackSignal uses a custom ticker system in Core/Tickers.lua
-- AceTimer is embedded and available for modules that want to use it directly
-- The custom system provides a simpler API for module-specific tickers

-- Store the addon object globally for external access
_G.BlackSignal = BlackSignal
_G.BS = BS

return BlackSignal
