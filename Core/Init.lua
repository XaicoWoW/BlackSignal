-- Core/Init.lua
local ADDON_NAME = "Black Signal"

_G.BS = _G.BS or {}
local BS = _G.BS

BS.name = ADDON_NAME
BS.modules = BS.modules or {}
BS.tickers = BS.tickers or {}

_G.BS_DB = _G.BS_DB or { profile = { modules = {} } }
