local _, BS = ...
BS.MainPanel = {}

local MainPanel = BS.MainPanel

local ConfigFrame;

local UI = BS.UI

local PANEL_W, PANEL_H = 840, 535

function MainPanel:Toggle()
    local menu = ConfigFrame or MainPanel:CreateMenu()
    menu:SetShown(not menu:IsShown())
end

function MainPanel:CreateMenu()
    ConfigFrame = CreateFrame("Frame", "BSConfigFrame", UIParent, "BackdropTemplate")
    ConfigFrame:SetSize(PANEL_W, PANEL_H)
    ConfigFrame:SetPoint("CENTER");
    ConfigFrame:SetMovable(true);
    ConfigFrame:EnableMouse(true);
    ConfigFrame:RegisterForDrag("LeftButton");
    ConfigFrame:SetScript("OnDragStart", ConfigFrame.StartMoving);
    ConfigFrame:SetScript("OnDragStop", ConfigFrame.StopMovingOrSizing);

    ConfigFrame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        tile = false,
        edgeSize = 1,
        insets = { left = 1, right = 1, top = 1, bottom = 1 },
    });

    ConfigFrame:SetBackdropColor(unpack(BS.Colors.Backdrop.background));
    ConfigFrame:SetBackdropBorderColor(unpack(BS.Colors.Backdrop.border));

    -- Title + Icon Centered with the left panel
    local iconPath = "Interface\\AddOns\\BlackSignal\\Media\\icon_64.tga"
    local icon = ConfigFrame:CreateTexture(nil, "ARTWORK")
    icon:SetSize(32, 32)
    icon:SetTexture(iconPath)
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    icon:SetPoint("TOPLEFT", ConfigFrame, "TOPLEFT", 60, -14)

    local title = UI:CreateText(ConfigFrame, "BlackSignal", "LEFT", icon, "RIGHT", 6, 0, "GameFontNormalLarge")
    title:SetTextColor(unpack(BS.Colors.Text.normal))

    -- Close
    local close = CreateFrame("Button", nil, ConfigFrame)
    close:SetSize(32, 32)
    close:SetPoint("TOPRIGHT", ConfigFrame, "TOPRIGHT", -8, -8)
    close:SetNormalFontObject("GameFontHighlight")
    close:SetText("X")
    close:GetFontString():SetTextColor(1, 1, 1, 1)

    close:SetScript("OnClick", function() ConfigFrame:Hide() end)
    close:SetScript("OnEnter", function(self) self:GetFontString():SetTextColor(1, 0.3, 0.3, 1) end)
    close:SetScript("OnLeave", function(self) self:GetFontString():SetTextColor(1, 1, 1, 1) end)

    -- Movers toggle button on the left of close button
    local movers = BS.Button:Create("BSConfigMoversButton", ConfigFrame, 80, 25, "Movers", "RIGHT", close, "LEFT", -6, 0)
    movers:SetScript("OnClick", function() BS.Movers:Toggle() end)

    -- Left panel
    local left = BS.LeftPanel:Create(ConfigFrame)

    -- Right panel
    local right = CreateFrame("Frame", nil, ConfigFrame, "BackdropTemplate")
    right:SetPoint("TOPLEFT", left, "TOPRIGHT", 12, 0)
    right:SetPoint("BOTTOMRIGHT", ConfigFrame, "BOTTOMRIGHT", -14, 14)
    UI:ApplyPanelStyle(right, 0.20, 1)

    ConfigFrame:Hide()
    return ConfigFrame
end