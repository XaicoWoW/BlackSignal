local _, BS = ...;
BS.LeftPanel = {}

local LeftPanel = BS.LeftPanel

local WIDTH = 235

local function OrderedModules(modulesTable)
    local list = {}

    for k, v in pairs(modulesTable) do
        if type(v) == "table" then
            local isHidden = false
            if (type(k) == "string" and k:match("^__")) then isHidden = true end
            if v.hidden then isHidden = true end

            if not isHidden then
                if v.name then
                    table.insert(list, v)
                elseif type(k) == "string" then
                    v.name = k
                    table.insert(list, v)
                end
            end
        end
    end

    table.sort(list, function(a, b) return (a.name or "") < (b.name or "") end)
    return list
end

function LeftPanel:Create(parent)
    local panel = CreateFrame("Frame", "BSLeftPanel", parent, "BackdropTemplate")
    panel:SetPoint("TOPLEFT", parent, "TOPLEFT", 14, -58)
    panel:SetPoint("BOTTOMLEFT", parent, "BOTTOMLEFT", 14, 14)
    panel:SetWidth(WIDTH)

    BS.UI:ApplyPanelStyle(panel, 0.20, 1)

    local y = -8
    local btnGap = 6
    local btnH = 26
    local btnPad = 5

    local modules = OrderedModules(BS.API.modules)

    for _, m in ipairs(modules) do
        m.db = m.db or BS.DB:EnsureDB(m.name, {
            enabled = true,
        })
        if m.enabled == nil then m.enabled = m.db.enabled end

        local btn = BS.Button:Create(nil, panel, 1, btnH, m.name, "TOPLEFT", panel, "TOPLEFT", btnPad, y)

        btn:SetPoint("TOPLEFT", panel, "TOPLEFT", btnPad, y)
        btn:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -btnPad, y)

        y = y - (btnH + btnGap)
    end

    return panel
end
