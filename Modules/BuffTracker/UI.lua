-- Modules/BuffTracker/UI.lua
-- @module BuffTracker.UI

local BS = _G.BS

local UI = {}
BS.BuffTrackerUI = UI

-------------------------------------------------
-- Frame helpers
-------------------------------------------------

local function CreateIconButton(parent)
    local btn = CreateFrame("Button", nil, parent)
    btn:SetSize(32, 32)

    btn.texture = btn:CreateTexture(nil, "ARTWORK")
    btn.texture:SetAllPoints(btn)

    -- Border (simple, consistent, no glow artifacts)
    btn.border = btn:CreateTexture(nil, "BORDER")
    btn.border:SetTexture("Interface\\Buttons\\WHITE8x8")
    btn.border:SetPoint("TOPLEFT", btn, "TOPLEFT", -1, 1)
    btn.border:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", 1, -1)
    btn.border:SetVertexColor(0, 0, 0, 1)
    btn.border:Show()


    -- Primary text inside the icon (supports multiline "NO\nBUFF" style)
    btn.centerText = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    btn.centerText:SetPoint("CENTER", btn, "CENTER", 0, 0)
    btn.centerText:SetJustifyH("CENTER")
    btn.centerText:SetJustifyV("MIDDLE")
    btn.centerText:SetTextColor(1, 1, 1)

    -- Optional label under the icon (disabled by default in layout via db.showText)
    btn.labelText = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    btn.labelText:SetPoint("TOP", btn, "BOTTOM", 0, -2)
    btn.labelText:SetTextColor(1, 1, 1)

    btn.expGlow = btn:CreateTexture(nil, "BACKGROUND")
    btn.expGlow:SetTexture("Interface\\Buttons\\WHITE8x8")
    btn.expGlow:SetPoint("TOPLEFT", -4, 4)
    btn.expGlow:SetPoint("BOTTOMRIGHT", 4, -4)
    btn.expGlow:SetVertexColor(1, 0.6, 0.1, 0.25)
    btn.expGlow:Hide()


    btn:Hide()
    return btn
end

local function FormatRemaining(seconds)
    if type(seconds) ~= "number" or seconds <= 0 then
        return ""
    end
    local mins = math.floor(seconds / 60)
    if mins > 0 then
        return mins .. "m"
    end
    return math.floor(seconds) .. "s"
end

-------------------------------------------------
-- Lifecycle
-------------------------------------------------

function UI:Ensure(module)
    if self._inited then return end
    self._inited = true

    local root = CreateFrame("Frame", "BS_BuffTrackerRoot", UIParent)
    root:SetSize(450, 124)
    root:Hide()

    self._root  = root
    self._icons = {}
end

function UI:GetRootFrame()
    return self._root
end

function UI:HideAll()
    if not self._root then return end
    self._root:Hide()
    if self._icons then
        for _, btn in ipairs(self._icons) do
            btn:Hide()
        end
    end
end

--- Best-effort lock: disables mouse on the root. Movers mode still controls actual dragging.
function UI:SetLocked(_, locked)
    if not self._root then return end
    self._root:EnableMouse(not locked)
end

-------------------------------------------------
-- Rendering
-------------------------------------------------

local function ApplyIconLayout(module, icons)
    local db = module.db
    local perRow   = tonumber(db.perRow) or 8
    local iconSize = tonumber(db.iconSize) or 32
    local spacing  = tonumber(db.spacing) or 2
    local scale    = tonumber(db.scale) or 1

    local shown = 0

    for i, btn in ipairs(icons) do
        if btn._visible then
            shown = shown + 1
            btn:Show()

            btn:SetSize(iconSize, iconSize)
            btn:SetScale(scale)

            -- Keep text readable across icon sizes
            local baseFont = math.max(8, math.floor(iconSize * 0.32))
            btn.centerText:SetFont(STANDARD_TEXT_FONT, baseFont, "OUTLINE")
            btn.centerText:SetWidth(iconSize - 4)
            btn.centerText:SetWordWrap(true)

            btn.labelText:SetFont(STANDARD_TEXT_FONT, math.max(8, math.floor(iconSize * 0.22)), "OUTLINE")

            btn:ClearAllPoints()
            local row = math.floor((shown - 1) / perRow)
            local col = (shown - 1) % perRow
            btn:SetPoint("TOPLEFT", module.UI._root, "TOPLEFT", col * (iconSize + spacing), -row * (iconSize + spacing))

            if db.showText then
                btn.labelText:Show()
            else
                btn.labelText:Hide()
            end
        else
            btn:Hide()
        end
    end

    local rows = math.max(1, math.ceil(shown / perRow))
    local cols = math.min(perRow, math.max(1, shown))

    module.UI._root:SetSize(cols * (iconSize + spacing) - spacing, rows * (iconSize + spacing) - spacing)
end

function UI:Render(module, viewModel)
    if not self._root then return end

    local items = viewModel and viewModel.items or {}
    if #items == 0 then
        self:HideAll()
        return
    end

    self._root:Show()

    -- Ensure enough icon frames
    for i = 1, #items do
        if not self._icons[i] then
            self._icons[i] = CreateIconButton(self._root)
        end
    end

    -- Populate
    for i, btn in ipairs(self._icons) do
        local item = items[i]
        if item then
            btn._visible = true

            btn.texture:SetTexture(item.icon)

            -- Text: prefer remaining-time when expiring; otherwise the provided text.
            local text = ""
            if item.expiringSoon and item.timeLeft then
                text = FormatRemaining(item.timeLeft)
            else
                text = item.text or ""
            end
            if text ~= "" then
                btn.centerText:SetText(text)
                btn.centerText:Show()
            else
                btn.centerText:SetText("")
                btn.centerText:Hide()
            end

            -- Label below icon is optional; by default we show a short category label for debugging.
            btn.labelText:SetText(item.label or item.shortLabel or "")

            if item.expiringSoon then
                btn.expGlow:Show()
            else
                btn.expGlow:Hide()
            end

            btn:SetScript("OnEnter", function()
                local spellID = item.tooltipSpellID
                if not spellID then return end
                GameTooltip:SetOwner(btn, "ANCHOR_RIGHT")
                GameTooltip:SetSpellByID(spellID)
                GameTooltip:Show()
            end)
            btn:SetScript("OnLeave", function() GameTooltip:Hide() end)
        else
            btn._visible = false
            btn:SetScript("OnEnter", nil)
            btn:SetScript("OnLeave", nil)
        end
    end

    ApplyIconLayout(module, self._icons)
end

BS.BuffTrackerUI = UI
return UI
