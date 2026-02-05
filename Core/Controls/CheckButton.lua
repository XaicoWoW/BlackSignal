local BS = _G.BS;

-- Use the table created by Init.lua, don't create a new one
local CheckButton = BS.CheckButton;

local function ApplyStyle(check, opts)
    opts             = opts or {}

    local size       = opts.size or 14
    local markSize   = opts.markSize or (size - 2)
    local edgeSize   = opts.edgeSize or 1

    local gap        = opts.gap or 8       -- gap between box and main label
    local infoGap    = opts.infoGap or 12  -- gap between label and info text
    local rightPad   = opts.rightPad or 6

    local bgOff      = opts.bgOff or BS.Colors.CheckButton.boxBg or { 0.12, 0.12, 0.12, 1 }
    local bgOn       = opts.bgOn or BS.Colors.CheckButton.mark or { 0.16, 0.16, 0.16, 1 }
    local border     = opts.border or BS.Colors.CheckButton.boxBorder or { 0, 0, 0, 1 }
    local markColor  = opts.markColor or BS.Colors.CheckButton.mark or { 1, 1, 1, 1 }

    local infoColor  = opts.infoColor or BS.Colors.Text and BS.Colors.Text.muted or { 0.70, 0.70, 0.70, 1 }
    local labelColor = opts.labelColor or { 1, 1, 1, 1 }

    local function KillTexturesOnce()
        if check._bsTexturesKilled then return end
        check._bsTexturesKilled = true

        local t = check.GetNormalTexture and check:GetNormalTexture()
        if t then t:SetTexture(nil) end
        t = check.GetPushedTexture and check:GetPushedTexture()
        if t then t:SetTexture(nil) end
        t = check.GetHighlightTexture and check:GetHighlightTexture()
        if t then t:SetTexture(nil) end
        t = check.GetCheckedTexture and check:GetCheckedTexture()
        if t then t:SetTexture(nil) end

        for _, region in ipairs({ check:GetRegions() }) do
            if region and region.IsObjectType and region:IsObjectType("Texture") then
                region:SetTexture(nil)
            end
        end
    end

    local function EnsureBox()
        if check._box and check._mark then return end

        local box = CreateFrame("Frame", nil, check, "BackdropTemplate")
        box:SetSize(size, size)
        box:SetPoint("LEFT", check, "LEFT", 0, 0)
        box:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Buttons\\WHITE8X8",
            tile = false,
            edgeSize = edgeSize,
            insets = { left = 1, right = 1, top = 1, bottom = 1 },
        })
        box:SetBackdropBorderColor(unpack(border))
        box:SetBackdropColor(unpack(bgOff))

        local mark = box:CreateTexture(nil, "OVERLAY")
        mark:SetPoint("CENTER")
        mark:SetSize(markSize, markSize)
        mark:SetTexture("Interface\\Buttons\\WHITE8X8")
        mark:SetVertexColor(unpack(markColor))
        mark:Hide()

        check._box  = box
        check._mark = mark
    end

    local function EnsureText()
        -- Blizzard template text can be: cb.Text, cb.text, or GetFontString()
        local label = check.Text or check.text or (check.GetFontString and check:GetFontString())
        if not label then
            label = check:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
            check.Text = label
        end

        label:SetTextColor(unpack(labelColor))
        label:SetJustifyH("LEFT")
        label:ClearAllPoints()
        label:SetPoint("LEFT", check._box, "RIGHT", gap, 0)

        check._label = label
    end

    local function EnsureInfo()
        if check._info then return end

        local info = check:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
        info:SetTextColor(unpack(infoColor))
        info:SetJustifyH("LEFT")
        info:SetJustifyV("MIDDLE")

        -- Position like the screenshot: to the RIGHT of the main label
        info:ClearAllPoints()
        info:SetPoint("LEFT", check._label, "RIGHT", infoGap, 0)
        info:SetPoint("RIGHT", check, "RIGHT", -rightPad, 0)
        info:SetWordWrap(true)

        check._info = info
    end

    local function EnsureSizing()
        if check._bsSized then return end
        check._bsSized = true

        -- Control height (layout)
        check:SetHeight(math.max(20, size + 6))

        -- Hit rect: ONLY the checkbox square (box)
        -- Default: make it as wide as the box, plus a tiny padding
        local hitPad = tonumber(opts.hitPad) or 2

        -- We need the row width to compute how much to shrink on the right
        check:HookScript("OnSizeChanged", function(self)
            if not self._box then return end

            local w = self:GetWidth() or 0
            local hitW = (self._box:GetWidth() or size) + (hitPad * 2)

            -- shrink everything except the first hitW pixels from the left
            local rightInset = math.max(0, w - hitW)

            -- leftInset=0 keeps left edge at frame left
            -- rightInset cuts clickable area from the right side
            self:SetHitRectInsets(0, rightInset, hitPad, hitPad)
        end)

        -- run once immediately (in case size is already known)
        local w = check:GetWidth() or 0
        local hitW = size + (hitPad * 2)
        local rightInset = math.max(0, w - hitW)
        check:SetHitRectInsets(0, rightInset, hitPad, hitPad)
    end


    local function Sync()
        if not check._box or not check._mark then return end
        local isOn = not not check:GetChecked()
        check._mark:SetShown(isOn)
        check._box:SetBackdropColor(unpack(isOn and bgOn or bgOff))
    end

    KillTexturesOnce()
    EnsureBox()
    EnsureText()
    EnsureInfo()
    EnsureSizing()

    if not check._bsHooked then
        check._bsHooked = true

        check:HookScript("OnLeave", function() Sync() end)
        check:HookScript("OnClick", function() Sync() end)
        check:HookScript("OnShow", function() Sync() end)
    end

    check._bsSync = Sync
    Sync()
end

--- Set label + info text (safe to call anytime)
function CheckButton:SetTexts(cb, labelText, infoText)
    if cb._label then cb._label:SetText(labelText or "") end
    if cb._info then
        cb._info:SetText(infoText or "")
        cb._info:SetShown(infoText and infoText ~= "")
    end
end

--- Create a styled CheckButton control with optional info text
--- @return CheckButton cb
function CheckButton:Create(name, parent, _, height, text, infoText, point, relativeTo, relativePoint, xOfs, yOfs, opts)
    opts = opts or {}

    local cb = CreateFrame("CheckButton", name, parent, "UICheckButtonTemplate")
    cb:SetHeight(height)

    local padLeft  = tonumber(opts.padLeft) or 0
    local padRight = tonumber(opts.padRight) or 0

    -- Anchor vertical/primary position as requested
    cb:SetPoint(point, relativeTo, relativePoint, xOfs + padLeft, yOfs)

    -- Force full width of the parent
    cb:ClearAllPoints()
    cb:SetPoint(point, relativeTo, relativePoint, xOfs, yOfs)
    cb:SetPoint("LEFT", parent, "LEFT", padLeft, 0)
    cb:SetPoint("RIGHT", parent, "RIGHT", -padRight, 0)

    ApplyStyle(cb, opts)

    -- Use our internal label reference to avoid template inconsistencies
    self:SetTexts(cb, text, infoText)

    return cb
end
