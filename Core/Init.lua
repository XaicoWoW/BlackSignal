-- Core/Init.lua
local ADDON_NAME = "|cff7f3fbfBlackSignal|r"
local BS_COLOR_HEX = "7f3fbf"
local BS_COLOR_RGB = { r = 0.498, g = 0.247, b = 0.749 }
_G.BS = _G.BS or {}
local BS = _G.BS

BS.name = ADDON_NAME
BS.colorHex = BS_COLOR_HEX
BS.colorRGB = BS_COLOR_RGB
BS.modules = BS.modules or {}
BS.tickers = BS.tickers or {}

_G.BS_DB = _G.BS_DB or { profile = { modules = {} } }

DEFAULT_CHAT_FRAME:AddMessage(ADDON_NAME .. " loaded. Type /bs for options.")