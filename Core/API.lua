-- Core/API.lua
local BS = _G.BS

function BS:RegisterModule(module)
  if type(module) ~= "table" or not module.name then return end
  self.modules[module.name] = module
end

function BS:LoadModules()
  local _, class = UnitClass("player")

  for _, module in pairs(self.modules) do
    if module.enabled ~= false then
      if not module.classes or module.classes == class then
        if module.OnInit and not module.__initialized then
          module.__initialized = true
          module:OnInit()
        elseif module.OnInit and module.__initialized and module.OnReload then
          module:OnReload()
        end
      end
    end
  end
end

function BS:RegisterEvent(event)
  if _G.BS_EventFrame then
    _G.BS_EventFrame:RegisterEvent(event)
  end
end