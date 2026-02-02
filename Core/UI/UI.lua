-- Core/UI.lua
-- UI helpers + reusable styles
local _, BS = ...;
BS.UI = {}

local UI = BS.UI
local EB = BS.EditBox

-------------------------------------------------
-- Basic creators
-------------------------------------------------
function UI:CreateText(parent, text, point, rel, relPoint, x, y, template)
    local fs = parent:CreateFontString(nil, "ARTWORK", template or "GameFontNormal")
    fs:SetPoint(point, rel, relPoint, x, y)
    fs:SetText(text or "")
    return fs
end

function UI:CreateDropdown(parent, w, h, point, rel, relPoint, x, y, items, getFunc, setFunc, tooltipText, styleOpts)
    items = items or {}
    styleOpts = styleOpts or {}

    local GRAY = 0.16
    local ebBgA = styleOpts.bgA or 0.85
    local openA = styleOpts.focusA or 1

    -- Holder
    local holder = CreateFrame("Frame", nil, parent)
    holder:SetSize(w, h)
    holder:SetPoint(point, rel, relPoint, x, y)

    -- Display (EditBox look)
    local eb = EB:Create("EditBox", holder, 70, 20, "", "LEFT", holder, "RIGHT", 10, 0)
    eb:SetAllPoints(holder)
    eb:SetAutoFocus(false)
    eb:EnableKeyboard(false)
    eb:EnableMouse(true)

    -- Arrow texture: ArrowUp.tga (default rotated down; open -> up)
    local ARROW_TEX = "Interface\\AddOns\\BlackSignal\\Media\\ArrowUp.tga"
    local arrowTex = eb:CreateTexture(nil, "OVERLAY")
    arrowTex:SetSize(12, 12)
    arrowTex:SetPoint("RIGHT", eb, "RIGHT", -8, 0)
    arrowTex:SetTexture(ARROW_TEX)
    arrowTex:SetRotation(math.pi) -- down by default

    -- Fallback ASCII if texture missing
    if not arrowTex:GetTexture() then
        arrowTex:Hide()
        local arrow = eb:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        arrow:SetPoint("RIGHT", eb, "RIGHT", -8, 0)
        arrow:SetTextColor(1, 1, 1, 1)
        arrow:SetText("v")
        holder._arrowFS = arrow
    end

    -- Menu
    local menu = CreateFrame("Frame", nil, holder, "BackdropTemplate")
    menu:Hide()
    menu:SetPoint("TOPLEFT", holder, "BOTTOMLEFT", 0, -2)
    menu:SetPoint("TOPRIGHT", holder, "BOTTOMRIGHT", 0, -2)

    -- Menu background like EditBox (gray)
    if menu.SetBackdrop then
        menu:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Buttons\\WHITE8X8",
            tile = false,
            edgeSize = 1,
            insets = { left = 1, right = 1, top = 1, bottom = 1 },
        })
        menu:SetBackdropColor(GRAY, GRAY, GRAY, ebBgA)
        menu:SetBackdropBorderColor(0, 0, 0, 1)
    elseif self.ApplyPanelStyle then
        self:ApplyPanelStyle(menu, ebBgA, 1)
    end

    -- Click-out overlay (only while open)
    local overlay = CreateFrame("Frame", nil, UIParent)
    overlay:Hide()
    overlay:EnableMouse(true)
    overlay:SetAllPoints(UIParent)

    local buttons = {}
    local rowH = 22

    local function Refresh()
        local current = getFunc and getFunc() or nil
        local text = ""

        for _, it in ipairs(items) do
            if it[1] == current then
                text = it[2] or tostring(it[1])
                break
            end
        end
        if text == "" and current ~= nil then text = tostring(current) end
        eb:SetText(text)

        -- highlight selected if supported
        for _, b in ipairs(buttons) do
            if b.SetBSActive then
                b:SetBSActive(b._value == current)
            end
        end
    end

    local function CloseMenu()
        menu:Hide()
        overlay:Hide()
        holder._open = false

        -- arrow down
        if arrowTex and arrowTex.SetRotation then
            arrowTex:SetRotation(math.pi)
        elseif holder._arrowFS then
            holder._arrowFS:SetText("v")
        end

        -- restore editbox bg
        if eb._bs and eb._bs.bgTex then
            eb._bs.bgTex:SetColorTexture(GRAY, GRAY, GRAY, ebBgA)
        end
    end

    local function OpenMenu()
        if holder._open then return end

        -- Put menu above config panels
        menu:SetFrameStrata("DIALOG")
        menu:SetFrameLevel((holder:GetFrameLevel() or 0) + 50)

        -- Overlay under menu so buttons still clickable
        overlay:SetFrameStrata(menu:GetFrameStrata())
        overlay:SetFrameLevel(menu:GetFrameLevel() - 1)
        overlay:Show()

        -- arrow up
        if arrowTex and arrowTex.SetRotation then
            arrowTex:SetRotation(0)
        elseif holder._arrowFS then
            holder._arrowFS:SetText("^")
        end

        -- focus bg
        if eb._bs and eb._bs.bgTex then
            eb._bs.bgTex:SetColorTexture(0, 0, 0, openA)
        end

        menu:Show()
        holder._open = true
        Refresh()
    end

    local function ToggleMenu()
        if holder._open then CloseMenu() else OpenMenu() end
    end

    overlay:SetScript("OnMouseDown", CloseMenu)

    local function RebuildMenu()
        for _, b in ipairs(buttons) do
            b:Hide()
            b:SetParent(nil)
        end
        wipe(buttons)

        local totalH = 0

        for i, it in ipairs(items) do
            local value, label = it[1], it[2]

            local b = CreateFrame("Button", nil, menu, "UIPanelButtonTemplate")
            b:SetSize(w - 2, rowH)
            b:SetText(label or tostring(value))
            b._value = value

            if UI.ApplyNavButtonStyle then
                UI:ApplyNavButtonStyle(b, {
                    bgA = 0.35,
                    hoverA = 0.55,
                    activeA = 0.75,
                    borderA = 1,
                    edgeSize = 1,
                    paddingX = 10,
                })
            end

            -- ensure above overlay
            b:SetFrameLevel(menu:GetFrameLevel() + i)

            if i == 1 then
                b:SetPoint("TOPLEFT", menu, "TOPLEFT", 1, -1)
                b:SetPoint("TOPRIGHT", menu, "TOPRIGHT", -1, -1)
            else
                b:SetPoint("TOPLEFT", buttons[i-1], "BOTTOMLEFT", 0, -1)
                b:SetPoint("TOPRIGHT", buttons[i-1], "BOTTOMRIGHT", 0, -1)
            end

            b:SetScript("OnClick", function()
                if setFunc then setFunc(value) end
                Refresh()
                CloseMenu()
            end)

            buttons[i] = b
            totalH = totalH + rowH + 1
        end

        menu:SetHeight(math.max(1, totalH + 2))
        Refresh()
    end

    -- Tooltip
    if tooltipText then
        holder:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText(tooltipText)
            GameTooltip:Show()
        end)
        holder:SetScript("OnLeave", function() GameTooltip:Hide() end)
    end

    -- Click to toggle
    eb:SetScript("OnMouseDown", ToggleMenu)

    -- Avoid stuck open
    holder:HookScript("OnHide", CloseMenu)

    -- Public API
    holder.SetItems = function(self, newItems)
        items = newItems or {}
        RebuildMenu()
    end
    holder.Refresh = Refresh
    holder.CloseMenu = CloseMenu
    holder.OpenMenu = OpenMenu
    holder.EditBox = eb
    holder.Menu = menu

    -- Init
    RebuildMenu()
    Refresh()

    return holder
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


return UI
