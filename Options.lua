ComfyCC = ComfyCC or {}
local CC = ComfyCC

local controls = {}
local sliderIndex = 0

local function SetLabel(check, text)
    local label = check.Text or check.text
    if not label then
        label = check:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        label:SetPoint("LEFT", check, "RIGHT", 3, 1)
        check.Text = label
    end
    label:SetText(text)
end

local function CreateCheck(parent, text, x, y, getter, setter)
    local cb = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    cb:SetPoint("TOPLEFT", x, y)
    SetLabel(cb, text)
    cb:SetScript("OnClick", function(self)
        setter(self:GetChecked() and true or false)
        CC:RefreshOptions()
        if CC.RefreshAllCooldowns then CC:RefreshAllCooldowns() end
    end)
    cb._getter = getter
    table.insert(controls, cb)
    return cb
end

local function CreateButton(parent, text, x, y, width, func)
    local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    button:SetSize(width or 140, 24)
    button:SetPoint("TOPLEFT", x, y)
    button:SetText(text)
    button:SetScript("OnClick", func)
    return button
end

local function CreateSlider(parent, label, minValue, maxValue, step, x, y, getter, setter, formatter)
    sliderIndex = sliderIndex + 1
    local name = "ComfyCCSlider" .. sliderIndex
    local slider = CreateFrame("Slider", name, parent, "OptionsSliderTemplate")
    slider:SetPoint("TOPLEFT", x, y)
    slider:SetWidth(250)
    slider:SetMinMaxValues(minValue, maxValue)
    slider:SetValueStep(step)
    slider:SetObeyStepOnDrag(true)

    _G[name .. "Low"]:SetText(tostring(minValue))
    _G[name .. "High"]:SetText(tostring(maxValue))
    _G[name .. "Text"]:SetText(label)

    slider.valueText = parent:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    slider.valueText:SetPoint("LEFT", slider, "RIGHT", 12, 0)

    slider:SetScript("OnValueChanged", function(self, value)
        if self._refreshing then return end
        setter(value)
        self.valueText:SetText(formatter and formatter(value) or tostring(value))
        if CC.RefreshAllCooldowns then CC:RefreshAllCooldowns() end
    end)

    slider._getter = getter
    slider._format = formatter
    table.insert(controls, slider)
    return slider
end

local function SelectTab(index)
    local frame = CC.optionsFrame
    if not frame then return end
    for i, tab in ipairs(frame.tabs) do
        tab:SetEnabled(i ~= index)
        frame.pages[i]:SetShown(i == index)
    end
end

function CC:RefreshOptions()
    if not self.optionsFrame or not self.db then return end

    for _, control in ipairs(controls) do
        if control._getter then
            local value = control._getter()
            if control:GetObjectType() == "CheckButton" then
                control:SetChecked(value and true or false)
            elseif control:GetObjectType() == "Slider" then
                control._refreshing = true
                control:SetValue(value)
                control._refreshing = false
                if control.valueText then
                    control.valueText:SetText(control._format and control._format(value) or tostring(value))
                end
            end
        end
    end
end

function CC:InitializeOptions()
    if self.optionsFrame then return end

    local frame = CreateFrame("Frame", "ComfyCCOptions", UIParent, "BasicFrameTemplateWithInset")
    frame:SetSize(680, 540)

    local saved = self.db and self.db.optionsWindow or nil
    local point = saved and saved.point or "CENTER"
    local relativePoint = saved and saved.relativePoint or point
    frame:SetPoint(point, UIParent, relativePoint, saved and saved.x or 0, saved and saved.y or 0)

    frame:SetClampedToScreen(true)
    frame:SetFrameStrata("HIGH")
    frame:SetFrameLevel(20)
    if frame.SetToplevel then frame:SetToplevel(true) end
    frame:Hide()
    frame.TitleText:SetText("ComfyCC")
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")

    frame:SetScript("OnMouseDown", function(self) self:Raise() end)
    frame:SetScript("OnDragStart", function(self)
        self:Raise()
        self:StartMoving()
    end)
    frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local p, _, rp, x, y = self:GetPoint(1)
        if CC.db and p then
            CC.db.optionsWindow = CC.db.optionsWindow or {}
            CC.db.optionsWindow.point = p
            CC.db.optionsWindow.relativePoint = rp or p
            CC.db.optionsWindow.x = x or 0
            CC.db.optionsWindow.y = y or 0
        end
    end)

    table.insert(UISpecialFrames, frame:GetName())
    self.optionsFrame = frame

    frame.tabs = {}
    frame.pages = {}

    local tabNames = {self:T("TAB_GENERAL"), self:T("TAB_INFO")}
    for i, label in ipairs(tabNames) do
        local tab = CreateButton(frame, label, 18 + (i - 1) * 120, -35, 110, function() SelectTab(i) end)
        frame.tabs[i] = tab

        local page = CreateFrame("Frame", nil, frame)
        page:SetPoint("TOPLEFT", 12, -70)
        page:SetPoint("BOTTOMRIGHT", -12, 12)
        frame.pages[i] = page
    end

    local general = frame.pages[1]

    local title = general:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 20, -10)
    title:SetText(self:T("TAB_GENERAL"))

    CreateCheck(general, self:T("ENABLE"), 20, -50,
        function() return CC.db.enabled end,
        function(v) CC:SetEnabled(v) end)

    CreateCheck(general, self:T("SHOW_DECIMALS"), 20, -90,
        function() return CC.db.showDecimals end,
        function(v) CC.db.showDecimals = v end)

    local minSlider = CreateSlider(general, self:T("MIN_DURATION"), 0, 10, 0.5, 35, -155,
        function() return CC.db.minDuration or 2 end,
        function(v) CC.db.minDuration = math.floor(v * 10 + 0.5) / 10 end,
        function(v) return string.format("%.1f s", v) end)
    minSlider._format = function(v) return string.format("%.1f s", v) end

    local thresholdSlider = CreateSlider(general, self:T("DECIMAL_THRESHOLD"), 1, 20, 1, 35, -225,
        function() return CC.db.decimalThreshold or 10 end,
        function(v) CC.db.decimalThreshold = math.floor(v + 0.5) end,
        function(v) return string.format("%d s", v) end)
    thresholdSlider._format = function(v) return string.format("%d s", v) end

    local fontSlider = CreateSlider(general, self:T("FONT_SIZE"), 10, 30, 1, 35, -295,
        function() return CC.db.fontSize or 16 end,
        function(v) CC.db.fontSize = math.floor(v + 0.5) end,
        function(v) return tostring(math.floor(v + 0.5)) end)
    fontSlider._format = function(v) return tostring(math.floor(v + 0.5)) end

    local scaleSlider = CreateSlider(general, self:T("TEXT_SCALE"), 60, 150, 5, 35, -365,
        function() return math.floor((CC.db.textScale or 1) * 100 + 0.5) end,
        function(v) CC.db.textScale = v / 100 end,
        function(v) return string.format("%d%%", v) end)
    scaleSlider._format = function(v) return string.format("%d%%", v) end

    local commands = general:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    commands:SetPoint("TOPLEFT", 20, -440)
    commands:SetText("/comfycc  ·  /cc  ·  /cc on  ·  /cc off")

    local infoPage = frame.pages[2]

    local ititle = infoPage:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    ititle:SetPoint("TOPLEFT", 20, -10)
    ititle:SetText(self:T("INFO_TITLE"))

    local infoBox = CreateFrame("Frame", nil, infoPage, "BackdropTemplate")
    infoBox:SetPoint("TOPLEFT", 20, -52)
    infoBox:SetSize(600, 385)
    infoBox:SetBackdrop({
        bgFile = "Interface\DialogFrame\UI-DialogBox-Background",
        edgeFile = "Interface\DialogFrame\UI-DialogBox-Border",
        tile = true, tileSize = 32, edgeSize = 32,
        insets = {left = 8, right = 8, top = 8, bottom = 8},
    })

    local addonName = infoBox:CreateFontString(nil, "ARTWORK", "GameFontNormalHuge")
    addonName:SetPoint("TOPLEFT", 28, -26)
    addonName:SetText("ComfyCC")

    local tagline = infoBox:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    tagline:SetPoint("TOPLEFT", addonName, "BOTTOMLEFT", 0, -7)
    tagline:SetWidth(540)
    tagline:SetJustifyH("LEFT")
    tagline:SetText("Lightweight cooldown countdown numbers for WoW Forever.")

    local function InfoRow(label, value, y)
        local l = infoBox:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        l:SetPoint("TOPLEFT", 28, y)
        l:SetText(label)

        local v = infoBox:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
        v:SetPoint("TOPLEFT", 170, y)
        v:SetWidth(390)
        v:SetJustifyH("LEFT")
        v:SetText(value or "-")
        return l, v
    end

    local clientVersion, clientBuild, _, clientInterface = CC:GetClientBuildInfo()
    local compatible, compatibilityText = CC:GetCompatibilityStatus()

    InfoRow(self:T("INFO_VERSION"), CC.version, -100)
    InfoRow(self:T("INFO_BUILD_DATE"), CC.buildDate, -122)
    InfoRow(self:T("INFO_STATUS"), CC.status, -144)
    InfoRow(self:T("INFO_CLIENT"), "WoW Forever " .. tostring(clientVersion) .. " / Build " .. tostring(clientBuild) .. " / Interface " .. tostring(clientInterface or "?"), -166)
    InfoRow(self:T("INFO_TESTED_TARGET"), CC.gameVersion .. " / Build " .. CC.targetBuild .. " / Interface " .. tostring(CC.interface), -188)

    local _, compatValue = InfoRow(self:T("INFO_COMPAT_STATUS"), compatibilityText, -210)
    if compatible then
        compatValue:SetTextColor(0.20, 1.00, 0.20)
    else
        compatValue:SetTextColor(1.00, 0.35, 0.20)
    end

    InfoRow(self:T("INFO_AUTHOR"), CC.author, -232)

    local discordLabel = infoBox:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    discordLabel:SetPoint("TOPLEFT", 28, -257)
    discordLabel:SetText(self:T("INFO_DISCORD"))

    local discordBox = CreateFrame("EditBox", nil, infoBox, "InputBoxTemplate")
    discordBox:SetSize(250, 30)
    discordBox:SetPoint("TOPLEFT", 165, -248)
    discordBox:SetAutoFocus(false)
    discordBox:SetText(CC.discord)
    discordBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    discordBox:SetScript("OnEnterPressed", function(self) self:HighlightText() end)
    discordBox:SetScript("OnEditFocusGained", function(self) self:HighlightText() end)

    local copyHint = infoBox:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    copyHint:SetPoint("TOPLEFT", 430, -255)
    copyHint:SetWidth(135)
    copyHint:SetJustifyH("LEFT")
    copyHint:SetText(self:T("INFO_COPY"))

    InfoRow(self:T("INFO_COMMANDS"), "/comfycc  ·  /cc", -292)

    local notice = infoBox:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    notice:SetPoint("TOPLEFT", 28, -322)
    notice:SetWidth(540)
    notice:SetJustifyH("LEFT")
    notice:SetText(self:T("INFO_NOTICE"))

    local thanks = infoBox:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    thanks:SetPoint("BOTTOMLEFT", 28, 28)
    thanks:SetWidth(540)
    thanks:SetJustifyH("LEFT")
    thanks:SetText(self:T("INFO_THANKS"))

    frame:SetScript("OnShow", function()
        CC:RefreshOptions()
    end)

    SelectTab(1)

    if Settings and Settings.RegisterCanvasLayoutCategory and Settings.RegisterAddOnCategory then
        local canvas = CreateFrame("Frame")
        local info = canvas:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
        info:SetPoint("TOPLEFT", 16, -16)
        info:SetText("ComfyCC")

        local desc = canvas:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
        desc:SetPoint("TOPLEFT", info, "BOTTOMLEFT", 0, -12)
        desc:SetWidth(520)
        desc:SetJustifyH("LEFT")
        desc:SetText(self:T("SETTINGS_DESC"))

        CreateButton(canvas, self:T("SETTINGS_OPEN"), 16, -90, 220, function() CC:ShowOptions() end)
        local category = Settings.RegisterCanvasLayoutCategory(canvas, "ComfyCC")
        Settings.RegisterAddOnCategory(category)
        self.settingsCategory = category
    end
end

function CC:ShowOptions()
    if not self.optionsFrame then self:InitializeOptions() end
    self.optionsFrame:Show()
    self.optionsFrame:Raise()
    self:RefreshOptions()
end
