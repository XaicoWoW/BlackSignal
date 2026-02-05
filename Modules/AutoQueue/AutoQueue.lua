-- Modules/AutoQueue.lua
-- @module AutoQueue
-- @alias AutoQueue

local BS = _G.BS

-------------------------------------------------
-- Create as an Ace3 Module
-------------------------------------------------
local AutoQueue = BS.Addon:NewModule("AutoQueue", "AceEvent-3.0")

-------------------------------------------------
-- Module Metadata (for BS.API compatibility)
-------------------------------------------------
AutoQueue.name = "BS_AQ"
AutoQueue.label = "Auto Queue"
AutoQueue.isQOLModule = true
AutoQueue.enabled = true
AutoQueue.defaults = {
    enabled = true,
    printOnAccept = true,
}

-------------------------------------------------
-- Register with BS.API (for Config panel compatibility)
-------------------------------------------------
BS.API:Register(AutoQueue)

-------------------------------------------------
-- Utils
-------------------------------------------------
local function Print(msg)
    DEFAULT_CHAT_FRAME:AddMessage("|cffb048f8BS AutoQueue:|r " .. tostring(msg))
end

-------------------------------------------------
-- Core: Role check accept
-------------------------------------------------
function AutoQueue:TryCompleteRoleCheck()
    print("Attempting to accept role check...")
    if not self.enabled then return end
    if not CompleteLFGRoleCheck then return end

    local ok, err = pcall(CompleteLFGRoleCheck, true)
    if ok then
        if self.db.printOnAccept then
            Print("Role check accepted.")
        end
    else
        Print("Role check accept failed: " .. tostring(err))
    end
end

-------------------------------------------------
-- Slash Commands
-------------------------------------------------
function AutoQueue:HandleSlash(arg)
    arg = (arg or ""):lower()

    if arg == "" or arg == "toggle" then
        self.db.enabled = not self.db.enabled
        Print("Auto Role Check: " .. (self.db.enabled and "ON" or "OFF"))
        return
    end

    if arg == "on" then
        self.db.enabled = true
        Print("Auto Role Check: ON")
        return
    end

    if arg == "off" then
        self.db.enabled = false
        Print("Auto Role Check: OFF")
        return
    end

    Print("Usage: /bs aq [toggle|on|off]")
end

-------------------------------------------------
-- Ace3 Lifecycle Callbacks
-------------------------------------------------
function AutoQueue:OnInitialize()
    self.db = BS.DB:EnsureDB(self.name, self.defaults)
    self.enabled = (self.db.enabled ~= false)
end

function AutoQueue:OnEnable()
    self:OnInitialize()

    -- Register event using AceEvent
    if self.enabled then
        self:RegisterEvent("LFG_ROLE_CHECK_SHOW", "TryCompleteRoleCheck")
    end
end

function AutoQueue:OnDisable()
    self.db = BS.DB:EnsureDB(self.name, self.defaults)
    self.enabled = false
    if self.db then self.db.enabled = false end

    -- AceEvent automatically unregisters all events on disable
end

-------------------------------------------------
-- ApplyOptions (for Config panel)
-------------------------------------------------
function AutoQueue:Apply()
    if not self.db then self.db = BS.DB:EnsureDB(self.name, self.defaults) end

    -- Re-register event if enabled
    if self.db.enabled then
        self:RegisterEvent("LFG_ROLE_CHECK_SHOW", "TryCompleteRoleCheck")
    end
end
