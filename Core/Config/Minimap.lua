-- Core/UI/MinimapButton.lua
-- Self-contained minimap button (no LibDBIcon)
-- Supports drag around minimap, show/hide, and click callbacks.

local _, BS = ...;

BS.MinimapButton = {}

local MB = BS.MinimapButton

local defaults = {
    enabled = true,
    radius  = 110, -- distance from minimap center
    angle   = 225, -- degrees
    lock    = false,
    tooltip = "Black Signal",
}

MB.defaults = defaults

local function Clamp(v, minV, maxV)
    if v < minV then return minV end
    if v > maxV then return maxV end
    return v
end

local function NormalizeAngle(deg)
    deg = deg % 360
    if deg < 0 then deg = deg + 360 end
    return deg
end

local function GetMinimapCenter()
    local mm = Minimap
    local cx, cy = mm:GetCenter()
    if not cx or not cy then
        -- fallback: approximate center using frame position
        local left, bottom = mm:GetLeft(), mm:GetBottom()
        if left and bottom then
            cx = left + (mm:GetWidth() / 2)
            cy = bottom + (mm:GetHeight() / 2)
        end
    end
    return cx, cy
end

function MB:ApplyPosition()
    if not self.frame or not self.db then return end

    local angle = NormalizeAngle(self.db.angle or defaults.angle)
    local radius = self.db.radius or defaults.radius

    -- Basic circle placement
    local rad = math.rad(angle)
    local x = math.cos(rad) * radius
    local y = math.sin(rad) * radius

    self.frame:ClearAllPoints()
    self.frame:SetPoint("CENTER", Minimap, "CENTER", x, y)
end

function MB:SetEnabled(enabled)
    if not self.frame or not self.db then return end
    self.db.enabled = not not enabled
    if self.db.enabled then
        self.frame:Show()
    else
        self.frame:Hide()
    end
end

function MB:Toggle()
    self:SetEnabled(not self.db.enabled)
end

function MB:Init(db, opts)
    opts = opts or {}

    self.db = db or {}
    for k, v in pairs(defaults) do
        if self.db[k] == nil then self.db[k] = v end
    end

    -- Allow override defaults at init time (non-destructive)
    for k, v in pairs(opts) do
        if self.db[k] == nil then self.db[k] = v end
    end

    if self.frame then
        -- Re-init safe
        self:ApplyPosition()
        self:SetEnabled(self.db.enabled)
        return self.frame
    end

    local btn = CreateFrame("Button", "BlackSignalMinimapButton", Minimap)
    btn:SetFrameStrata("MEDIUM")
    btn:SetSize(32, 32)
    btn:SetMovable(true)
    btn:EnableMouse(true)
    btn:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    btn:RegisterForDrag("LeftButton")
    btn:SetClampedToScreen(true)

    -- Ring
    local border = btn:CreateTexture(nil, "BORDER")
    border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    border:SetAllPoints(btn)

    -- Icon
    local icon = btn:CreateTexture(nil, "BACKGROUND")
    icon:SetTexture(opts.icon or "Interface\\AddOns\\BlackSignal\\Media\\icon_32.png")
    icon:SetAllPoints(btn)

    btn:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")

    -- Tooltip
    btn:SetScript("OnEnter", function()
        GameTooltip:SetOwner(btn, "ANCHOR_LEFT")
        GameTooltip:AddLine(self.db.tooltip or defaults.tooltip, 1, 1, 1)
        if not (self.db.lock) then
            GameTooltip:AddLine("Drag: move", 0.8, 0.8, 0.8)
        end
        GameTooltip:AddLine("Left-click: toggle config", 0.8, 0.8, 0.8)
        GameTooltip:Show()
    end)

    btn:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    -- Drag logic
    btn:SetScript("OnDragStart", function()
        if self.db.lock then return end
        btn.isDragging = true
        btn:SetScript("OnUpdate", function()
            local cx, cy = GetMinimapCenter()
            if not cx or not cy then return end

            local mx, my = GetCursorPosition()
            local scale = UIParent:GetScale()
            mx, my = mx / scale, my / scale

            local dx, dy = (mx - cx), (my - cy)
            local angle = math.deg(math.atan2(dy, dx))
            angle = NormalizeAngle(angle)

            -- Keep radius sane
            self.db.radius = Clamp(self.db.radius or defaults.radius, 50, 140)
            self.db.angle = angle

            self:ApplyPosition()
        end)
    end)

    btn:SetScript("OnDragStop", function()
        if not btn.isDragging then return end
        btn.isDragging = false
        btn:SetScript("OnUpdate", nil)
    end)

    -- Click callbacks
    btn:SetScript("OnClick", function(_, mouseButton)
        if mouseButton == "LeftButton" then
            if type(opts.onLeftClick) == "function" then
                opts.onLeftClick()
            elseif BS.MainPanel and BS.MainPanel.Toggle then
                BS.MainPanel:Toggle()
            end
        elseif mouseButton == "RightButton" then
            if type(opts.onRightClick) == "function" then
                opts.onRightClick()
            end
        end
    end)

    self.frame = btn
    self:ApplyPosition()
    self:SetEnabled(self.db.enabled)

    return btn
end
