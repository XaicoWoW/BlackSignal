-- Core/UI.lua
-- UI helpers + reusable styles

local BS = _G.BS or {}
_G.BS = BS

local UI = {}
BS.UI = UI

-------------------------------------------------
-- Basic creators
-------------------------------------------------
function UI:CreateText(parent, text, point, rel, relPoint, x, y, template)
    local fs = parent:CreateFontString(nil, "ARTWORK", template or "GameFontNormal")
    fs:SetPoint(point, rel, relPoint, x, y)
    fs:SetText(text or "")
    return fs
end

function UI:CreateButton(parent, text, w, h, point, rel, relPoint, x, y, styleOpts)
    local btn = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    btn:SetSize(w, h)
    btn:SetPoint(point, rel, relPoint, x, y)
    btn:SetText(text or "")

    for _, region in ipairs({ btn:GetRegions() }) do
        if region:IsObjectType("Texture") then
            region:SetTexture(nil)
        end
    end

    if self.ApplyNavButtonStyle then
        self:ApplyNavButtonStyle(btn, styleOpts)
    end

    return btn
end

function UI:CreateEditBox(parent, w, h, point, rel, relPoint, x, y, styleOpts)
    local eb = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")
    eb:SetSize(w, h)
    eb:SetPoint(point, rel, relPoint, x, y)
    eb:SetAutoFocus(false)

    if self.ApplyEditBoxStyle then
        self:ApplyEditBoxStyle(eb, styleOpts)
    end

    return eb
end

function UI:CreateCheck(parent, label, point, rel, relPoint, x, y)
    local cb = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    cb:SetPoint(point, rel, relPoint, x, y)
    cb.text:SetText(label)
    return cb
end

function UI:ShowColorPicker(r, g, b, a, callback)
    r = tonumber(r) or 1
    g = tonumber(g) or 1
    b = tonumber(b) or 1
    a = tonumber(a) or 1

    local function fire(newR, newG, newB, newA)
        if callback then callback(newR, newG, newB, newA) end
    end

    -- Retail API moderno
    if ColorPickerFrame and ColorPickerFrame.SetupColorPickerAndShow then
        local info = {
            r = r,
            g = g,
            b = b,
            opacity = 1 - a,
            hasOpacity = true,
            swatchFunc = function()
                local nr, ng, nb = ColorPickerFrame:GetColorRGB()
                local na = 1 - (OpacitySliderFrame and OpacitySliderFrame:GetValue() or 0)
                fire(nr, ng, nb, na)
            end,
            opacityFunc = function()
                local nr, ng, nb = ColorPickerFrame:GetColorRGB()
                local na = 1 - (OpacitySliderFrame and OpacitySliderFrame:GetValue() or 0)
                fire(nr, ng, nb, na)
            end,
            cancelFunc = function(prev)
                if prev then
                    local na = 1 - (prev.opacity or 0)
                    fire(prev.r, prev.g, prev.b, na)
                else
                    fire(r, g, b, a)
                end
            end,
        }
        ColorPickerFrame:SetupColorPickerAndShow(info)
        return
    end

    -- Fallback clásico
    ColorPickerFrame:SetColorRGB(r, g, b)
    ColorPickerFrame.hasOpacity = true
    ColorPickerFrame.opacity = 1 - a

    ColorPickerFrame.func = function()
        local nr, ng, nb = ColorPickerFrame:GetColorRGB()
        local na = 1 - (OpacitySliderFrame and OpacitySliderFrame:GetValue() or 0)
        fire(nr, ng, nb, na)
    end
    ColorPickerFrame.opacityFunc = ColorPickerFrame.func
    ColorPickerFrame.cancelFunc = function()
        fire(r, g, b, a)
    end

    ColorPickerFrame:Show()
end

-------------------------------------------------
-- Panel style
-------------------------------------------------
function UI:ApplyPanelStyle(frame, bgAlpha, borderSize)
    local edge = borderSize or 1

    frame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        tile = false,
        edgeSize = edge,
        insets = { left = edge, right = edge, top = edge, bottom = edge },
    })

    frame:SetBackdropColor(0, 0, 0, bgAlpha or 0.85)
    frame:SetBackdropBorderColor(0, 0, 0, 1)
end

-------------------------------------------------
-- Left-list button style (BackdropTemplate)
-------------------------------------------------
function UI:ApplyNavButtonStyle(btn, opts)
    opts           = opts or {}
    local bgA      = opts.bgA or 1
    local hoverA   = opts.hoverA or 0.55
    local activeA  = opts.activeA or 0.75
    local borderA  = opts.borderA or 1
    local edgeSize = opts.edgeSize or 1
    local paddingX = opts.paddingX or 10
    local GRAY     = 0.16

    btn:SetNormalFontObject("GameFontHighlightSmall")
    btn:SetHighlightFontObject("GameFontHighlightSmall")
    btn:SetDisabledFontObject("GameFontDisableSmall")

    -- Kill UIPanelButtonTemplate textures (Left/Middle/Right etc.)
    if btn.Left then btn.Left:Hide() end
    if btn.Middle then btn.Middle:Hide() end
    if btn.Right then btn.Right:Hide() end
    for _, region in ipairs({ btn:GetRegions() }) do
        if region and region:IsObjectType("Texture") then
            region:SetTexture(nil)
        end
    end

    -- -------------------------
    -- Background (texture-based)
    -- -------------------------
    btn._bs = btn._bs or {}

    if not btn._bs.bgTex then
        local bg = btn:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints(btn)
        btn._bs.bgTex = bg
    end
    btn._bs.bgTex:SetColorTexture(GRAY, GRAY, GRAY, bgA)

    -- -------------------------
    -- Border (4 textures)
    -- -------------------------
    if not btn._bs.border then
        local b = {}
        b.top = btn:CreateTexture(nil, "BORDER")
        b.bottom = btn:CreateTexture(nil, "BORDER")
        b.left = btn:CreateTexture(nil, "BORDER")
        b.right = btn:CreateTexture(nil, "BORDER")

        btn._bs.border = b
    end

    local b = btn._bs.border
    local es = edgeSize

    b.top:SetPoint("TOPLEFT", btn, "TOPLEFT", 0, 0)
    b.top:SetPoint("TOPRIGHT", btn, "TOPRIGHT", 0, 0)
    b.top:SetHeight(es)

    b.bottom:SetPoint("BOTTOMLEFT", btn, "BOTTOMLEFT", 0, 0)
    b.bottom:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", 0, 0)
    b.bottom:SetHeight(es)

    b.left:SetPoint("TOPLEFT", btn, "TOPLEFT", 0, 0)
    b.left:SetPoint("BOTTOMLEFT", btn, "BOTTOMLEFT", 0, 0)
    b.left:SetWidth(es)

    b.right:SetPoint("TOPRIGHT", btn, "TOPRIGHT", 0, 0)
    b.right:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", 0, 0)
    b.right:SetWidth(es)

    for _, t in pairs(b) do
        t:SetColorTexture(0, 0, 0, borderA)
        t:Show()
    end

    -- Text alignment / padding
    local fs = btn:GetFontString()
    if fs then
        fs:SetJustifyH("LEFT")
        fs:ClearAllPoints()
        fs:SetPoint("LEFT", btn, "LEFT", paddingX, 0)
        fs:SetTextColor(1, 1, 1, 1)
    end

    btn._bs.bgA = bgA
    btn._bs.hoverA = hoverA
    btn._bs.activeA = activeA

    btn:SetScript("OnEnter", function(self)
        if not self._bsActive then
            self._bs.bgTex:SetColorTexture(0, 0, 0, self._bs.hoverA)
        end
    end)

    btn:SetScript("OnLeave", function(self)
        if not self._bsActive then
            self._bs.bgTex:SetColorTexture(GRAY, GRAY, GRAY, self._bs.bgA)
        end
    end)

    function btn:SetBSActive(active)
        self._bsActive = active and true or false
        if self._bsActive then
            self._bs.bgTex:SetColorTexture(0, 0, 0, self._bs.activeA)
        else
            self._bs.bgTex:SetColorTexture(GRAY, GRAY, GRAY, self._bs.bgA)
        end
    end
end

function UI:ApplyEditBoxStyle(eb, opts)
    opts           = opts or {}

    local bgA      = opts.bgA or 0.85
    local focusA   = opts.focusA or 1
    local borderA  = opts.borderA or 1
    local edgeSize = opts.edgeSize or 1
    local paddingX = opts.paddingX or 6
    local paddingY = opts.paddingY or 0
    local GRAY     = 0.16

    eb:SetFontObject("GameFontHighlightSmall")
    eb:SetTextInsets(paddingX, paddingX, paddingY, paddingY)

    -- Kill InputBoxTemplate textures
    if eb.Left then eb.Left:Hide() end
    if eb.Middle then eb.Middle:Hide() end
    if eb.Right then eb.Right:Hide() end
    for _, region in ipairs({ eb:GetRegions() }) do
        if region and region:IsObjectType("Texture") then
            region:SetTexture(nil)
        end
    end

    eb._bs = eb._bs or {}

    -- -------------------------
    -- Background
    -- -------------------------
    if not eb._bs.bgTex then
        local bg = eb:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints(eb)
        eb._bs.bgTex = bg
    end
    eb._bs.bgTex:SetColorTexture(GRAY, GRAY, GRAY, bgA)

    -- -------------------------
    -- Border
    -- -------------------------
    if not eb._bs.border then
        local b = {}
        b.top = eb:CreateTexture(nil, "BORDER")
        b.bottom = eb:CreateTexture(nil, "BORDER")
        b.left = eb:CreateTexture(nil, "BORDER")
        b.right = eb:CreateTexture(nil, "BORDER")
        eb._bs.border = b
    end

    local b = eb._bs.border
    local es = edgeSize

    b.top:SetPoint("TOPLEFT", eb, "TOPLEFT", 0, 0)
    b.top:SetPoint("TOPRIGHT", eb, "TOPRIGHT", 0, 0)
    b.top:SetHeight(es)

    b.bottom:SetPoint("BOTTOMLEFT", eb, "BOTTOMLEFT", 0, 0)
    b.bottom:SetPoint("BOTTOMRIGHT", eb, "BOTTOMRIGHT", 0, 0)
    b.bottom:SetHeight(es)

    b.left:SetPoint("TOPLEFT", eb, "TOPLEFT", 0, 0)
    b.left:SetPoint("BOTTOMLEFT", eb, "BOTTOMLEFT", 0, 0)
    b.left:SetWidth(es)

    b.right:SetPoint("TOPRIGHT", eb, "TOPRIGHT", 0, 0)
    b.right:SetPoint("BOTTOMRIGHT", eb, "BOTTOMRIGHT", 0, 0)
    b.right:SetWidth(es)

    for _, t in pairs(b) do
        t:SetColorTexture(0, 0, 0, borderA)
        t:Show()
    end

    -- -------------------------
    -- Focus handling
    -- -------------------------
    eb:SetScript("OnEditFocusGained", function(self)
        self._bs.bgTex:SetColorTexture(0, 0, 0, focusA)
    end)

    eb:SetScript("OnEditFocusLost", function(self)
        self._bs.bgTex:SetColorTexture(GRAY, GRAY, GRAY, bgA)
    end)
end

-------------------------------------------------
-- Minimal checkbox style (custom box + mark)
-------------------------------------------------
function UI:ApplyMinimalCheckStyle(check)
    local bg = check:GetNormalTexture()
    if bg then bg:SetTexture(nil) end

    local pushed = check:GetPushedTexture()
    if pushed then pushed:SetTexture(nil) end

    local highlight = check:GetHighlightTexture()
    if highlight then highlight:SetTexture(nil) end

    local checked = check:GetCheckedTexture()
    if checked then checked:SetTexture(nil) end

    for _, region in ipairs({ check:GetRegions() }) do
        if region:IsObjectType("Texture") then
            region:SetTexture(nil)
        end
    end

    local box = check._box
    if not box then
        box = CreateFrame("Frame", nil, check, "BackdropTemplate")
        box:SetSize(14, 14)
        box:SetPoint("LEFT", check, "LEFT", 0, 0)

        box:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Buttons\\WHITE8X8",
            tile = false,
            edgeSize = 1,
            insets = { left = 1, right = 1, top = 1, bottom = 1 },
        })
        box:SetBackdropBorderColor(0, 0, 0, 1)
        box:SetBackdropColor(0.12, 0.12, 0.12, 1)

        local mark = box:CreateTexture(nil, "OVERLAY")
        mark:SetPoint("CENTER")
        mark:SetSize(12, 12)
        mark:SetTexture("Interface\\Buttons\\WHITE8X8")
        mark:SetVertexColor(1, 1, 1, 1)
        mark:Hide()

        check._box = box
        check._mark = mark
    end

    local text = check.Text or check.text or check:GetFontString()
    if text then
        text:SetTextColor(1, 1, 1, 1)
        text:SetJustifyH("LEFT")
        text:ClearAllPoints()
        text:SetPoint("LEFT", check._box, "RIGHT", 8, 0)
    end

    if not check._sized then
        check:SetHeight(20)
        check._sized = true
    end

    local function Sync()
        local isOn = check:GetChecked() and true or false
        check._mark:SetShown(isOn)
        if isOn then
            check._box:SetBackdropColor(0.16, 0.16, 0.16, 1)
        else
            check._box:SetBackdropColor(0.12, 0.12, 0.12, 1)
        end
    end

    check:SetScript("OnEnter", function()
        check._box:SetBackdropColor(0.18, 0.18, 0.18, 1)
    end)

    check:SetScript("OnLeave", function()
        Sync()
    end)

    check._bsSync = Sync
    Sync()
end

-------------------------------------------------
-- ColorPickerFrame
-------------------------------------------------
function UI:CreateColorPicker(parent, w, h, point, relativeTo, relativePoint, x, y, getFunc, setFunc, tooltipText)
    local btn = CreateFrame("Button", nil, parent, "BackdropTemplate")
    btn:SetSize(w or 26, h or 26)
    btn:SetPoint(point or "TOPLEFT", relativeTo or parent, relativePoint or "TOPLEFT", x or 0, y or 0)
    btn:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        tile = false,
        edgeSize = 1,
        insets = { left = 1, right = 1, top = 1, bottom = 1 },
    })
    btn:SetBackdropBorderColor(0, 0, 0, 1)

    local function Refresh()
        local r, g, b, a = 1, 1, 1, 1
        if getFunc then
            r, g, b, a = getFunc()
        end
        btn:SetBackdropColor(r or 1, g or 1, b or 1, 1)
        btn.__alpha = a or 1
    end

    btn:SetScript("OnClick", function()
        local r, g, b, a = 1, 1, 1, 1
        if getFunc then r, g, b, a = getFunc() end

        UI:ShowColorPicker(r, g, b, a, function(nr, ng, nb, na)
            if setFunc then setFunc(nr, ng, nb, na) end
            Refresh()
        end)
    end)

    if tooltipText then
        btn:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText(tooltipText)
            GameTooltip:Show()
        end)
        btn:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)
    end

    btn.Refresh = Refresh
    Refresh()
    return btn
end

return UI
