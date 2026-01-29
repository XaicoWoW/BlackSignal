-- Core/Ticker.lua
local BS = _G.BS

function BS:RegisterTicker(owner, interval, func)
  self:StopTicker(owner)
  self.tickers[owner] = C_Timer.NewTicker(interval, func)
end

function BS:StopTicker(owner)
  local t = self.tickers[owner]
  if t then
    t:Cancel()
    self.tickers[owner] = nil
  end
end