ComfyCC = ComfyCC or {}
local CC = ComfyCC

CC.cooldowns = CC.cooldowns or setmetatable({}, {__mode = "k"})
CC.hooksInstalled = CC.hooksInstalled or false

local DEFAULT_UPDATE_INTERVAL = 0.20
local FAST_UPDATE_INTERVAL = 0.05
local MEDIUM_UPDATE_INTERVAL = 0.10
local SLOW_UPDATE_INTERVAL = 0.25
local VERY_SLOW_UPDATE_INTERVAL = 0.50

local function IsSecretValue(value)
    if type(issecretvalue) == "function" then
        local ok, secret = pcall(issecretvalue, value)
        if ok then return secret and true or false end
    end
    if type(canaccessvalue) == "function" then
        local ok, accessible = pcall(canaccessvalue, value)
        if ok then return not accessible end
    end
    return false
end

local function AccessibleNumber(value)
    if value == nil or IsSecretValue(value) then return nil end
    local ok, number = pcall(tonumber, value)
    if not ok then return nil end
    return number
end

local function IsForbiddenFrame(frame)
    if not frame or type(frame.IsForbidden) ~= "function" then return false end
    local ok, forbidden = pcall(frame.IsForbidden, frame)
    return ok and forbidden and true or false
end

local function IsFrameShown(frame)
    if not frame or type(frame.IsShown) ~= "function" then return false end
    local ok, shown = pcall(frame.IsShown, frame)
    return ok and shown and true or false
end

local function Clamp(value, minValue, maxValue)
    value = AccessibleNumber(value) or minValue
    if value < minValue then return minValue end
    if value > maxValue then return maxValue end
    return value
end

local function NormalizeCountdownText(value)
    if type(value) ~= "string" then return "" end
    value = value:gsub("|c%x%x%x%x%x%x%x%x", "")
    value = value:gsub("|r", "")
    value = value:gsub("|T.-|t", "")
    value = value:gsub("^%s+", ""):gsub("%s+$", "")
    return value
end

local function LooksLikeCountdownText(value)
    value = NormalizeCountdownText(value)
    if value == "" then return false end
    if value:match("^%d+$") then return true end
    if value:match("^%d+%.%d+$") then return true end
    if value:match("^%d+[smhd]$") then return true end
    return false
end

function CC:FormatRemaining(remaining)
    remaining = AccessibleNumber(remaining)
    if not remaining then return nil end
    remaining = math.max(0, remaining)

    if remaining >= 3600 then
        return string.format("%dh", math.ceil(remaining / 3600))
    elseif remaining >= 60 then
        return string.format("%dm", math.ceil(remaining / 60))
    end

    local threshold = AccessibleNumber(self.db and self.db.decimalThreshold) or 10
    if self.db and self.db.showDecimals and remaining < threshold and remaining > 0 then
        return string.format("%.1f", remaining)
    end

    return tostring(math.ceil(remaining))
end

function CC:ApplyTextStyle(cooldown)
    if IsForbiddenFrame(cooldown) then return end

    local text = cooldown and cooldown.__ComfyCCText
    if not text or not self.db then return end

    local ok, fontPath, _, flags = pcall(text.GetFont, text)
    if ok and fontPath then
        pcall(text.SetFont, text, fontPath, Clamp(self.db.fontSize, 8, 40), flags)
    end
    pcall(text.SetScale, text, Clamp(self.db.textScale, 0.5, 2.0))
end

function CC:GetCooldownFrameSize(cooldown)
    if not cooldown or IsForbiddenFrame(cooldown) then return nil end

    local width, height
    if type(cooldown.GetWidth) == "function" then
        local ok, value = pcall(cooldown.GetWidth, cooldown)
        if ok then width = AccessibleNumber(value) end
    end
    if type(cooldown.GetHeight) == "function" then
        local ok, value = pcall(cooldown.GetHeight, cooldown)
        if ok then height = AccessibleNumber(value) end
    end

    if width and height then return math.min(width, height) end
    return width or height
end

function CC:HasExternalCountdownText(cooldown)
    if not self.db or self.db.avoidDuplicateText == false then return false end
    if not cooldown or IsForbiddenFrame(cooldown) or type(cooldown.GetRegions) ~= "function" then return false end

    local ok, regions = pcall(function()
        return {cooldown:GetRegions()}
    end)
    if not ok or type(regions) ~= "table" then return false end

    for _, region in ipairs(regions) do
        if region and region ~= cooldown.__ComfyCCText and type(region.GetObjectType) == "function" then
            local okType, objectType = pcall(region.GetObjectType, region)
            if okType and objectType == "FontString" and IsFrameShown(region) and type(region.GetText) == "function" then
                local okText, value = pcall(region.GetText, region)
                if okText and LooksLikeCountdownText(value) then
                    return true
                end
            end
        end
    end

    return false
end

function CC:GetUpdateInterval(remaining)
    remaining = AccessibleNumber(remaining)
    if not remaining then return DEFAULT_UPDATE_INTERVAL end

    local decimalThreshold = AccessibleNumber(self.db and self.db.decimalThreshold) or 10
    if self.db and self.db.showDecimals and remaining <= decimalThreshold then
        return FAST_UPDATE_INTERVAL
    elseif remaining <= 60 then
        return MEDIUM_UPDATE_INTERVAL
    elseif remaining <= 3600 then
        return SLOW_UPDATE_INTERVAL
    end
    return VERY_SLOW_UPDATE_INTERVAL
end

function CC:RegisterCooldown(cooldown)
    if not cooldown or type(cooldown) ~= "table" or IsForbiddenFrame(cooldown) then return end
    if self.cooldowns[cooldown] then
        self:ApplyTextStyle(cooldown)
        return
    end

    self.cooldowns[cooldown] = true

    local ok, text = pcall(cooldown.CreateFontString, cooldown, nil, "OVERLAY", "GameFontNormalLarge")
    if not ok or not text then
        self.cooldowns[cooldown] = nil
        return
    end

    text:SetPoint("CENTER", cooldown, "CENTER", 0, 0)
    text:SetJustifyH("CENTER")
    text:SetJustifyV("MIDDLE")
    text:SetTextColor(1, 1, 1, 1)
    text:SetShadowOffset(1, -1)
    text:Hide()

    cooldown.__ComfyCCText = text
    cooldown.__ComfyCCElapsed = 0
    cooldown.__ComfyCCNextInterval = DEFAULT_UPDATE_INTERVAL

    self:ApplyTextStyle(cooldown)

    cooldown:HookScript("OnUpdate", function(frame, elapsed)
        if not CC.db or IsForbiddenFrame(frame) then return end

        local safeElapsed = AccessibleNumber(elapsed) or 0
        frame.__ComfyCCElapsed = (frame.__ComfyCCElapsed or 0) + safeElapsed

        local interval = AccessibleNumber(frame.__ComfyCCNextInterval) or DEFAULT_UPDATE_INTERVAL
        if frame.__ComfyCCElapsed < interval then return end

        frame.__ComfyCCElapsed = 0
        CC:UpdateCooldownText(frame)
    end)

    cooldown:HookScript("OnHide", function(frame)
        if frame.__ComfyCCText then frame.__ComfyCCText:Hide() end
    end)
end

function CC:RecordCooldown(cooldown, startTime, duration, enable, modRate)
    if not cooldown or IsForbiddenFrame(cooldown) then return end
    self:RegisterCooldown(cooldown)
    if not cooldown.__ComfyCCText then return end

    local protected = IsSecretValue(startTime)
        or IsSecretValue(duration)
        or IsSecretValue(enable)
        or IsSecretValue(modRate)

    cooldown.__ComfyCCProtected = protected and true or false

    if protected then
        cooldown.__ComfyCCStart = nil
        cooldown.__ComfyCCDuration = nil
        cooldown.__ComfyCCEnable = nil
        cooldown.__ComfyCCModRate = nil
        cooldown.__ComfyCCNextInterval = DEFAULT_UPDATE_INTERVAL
        cooldown.__ComfyCCText:Hide()
        return
    end

    local start = AccessibleNumber(startTime)
    local length = AccessibleNumber(duration)

    local enabled
    if enable == nil then
        enabled = 1
    elseif type(enable) == "boolean" then
        enabled = enable and 1 or 0
    else
        enabled = AccessibleNumber(enable) or 0
    end

    local rate = AccessibleNumber(modRate) or 1
    if rate <= 0 then rate = 1 end

    cooldown.__ComfyCCStart = start or 0
    cooldown.__ComfyCCDuration = length or 0
    cooldown.__ComfyCCEnable = enabled
    cooldown.__ComfyCCModRate = rate

    self:UpdateCooldownText(cooldown)
end

function CC:ClearCooldown(cooldown)
    if not cooldown then return end
    cooldown.__ComfyCCStart = nil
    cooldown.__ComfyCCDuration = nil
    cooldown.__ComfyCCEnable = nil
    cooldown.__ComfyCCModRate = nil
    cooldown.__ComfyCCProtected = nil
    cooldown.__ComfyCCNextInterval = DEFAULT_UPDATE_INTERVAL
    if cooldown.__ComfyCCText then cooldown.__ComfyCCText:Hide() end
end

function CC:UpdateCooldownText(cooldown)
    if not cooldown or IsForbiddenFrame(cooldown) or not cooldown.__ComfyCCText or not self.db then return end

    local text = cooldown.__ComfyCCText

    if not self.db.enabled or not IsFrameShown(cooldown) or cooldown.__ComfyCCProtected then
        text:Hide()
        return
    end

    local startTime = AccessibleNumber(cooldown.__ComfyCCStart)
    local duration = AccessibleNumber(cooldown.__ComfyCCDuration)
    local enable = AccessibleNumber(cooldown.__ComfyCCEnable)
    local modRate = AccessibleNumber(cooldown.__ComfyCCModRate) or 1

    if not startTime or not duration or duration <= 0 or enable == 0 then
        text:Hide()
        return
    end

    if duration < (AccessibleNumber(self.db.minDuration) or 2.0) then
        text:Hide()
        return
    end

    local frameSize = self:GetCooldownFrameSize(cooldown)
    local minIconSize = AccessibleNumber(self.db.minIconSize) or 18
    if frameSize and frameSize < minIconSize then
        text:Hide()
        return
    end

    local now = type(GetTime) == "function" and AccessibleNumber(GetTime()) or 0
    local effectiveDuration = duration / math.max(0.01, modRate)
    local remaining = (startTime + effectiveDuration) - now

    cooldown.__ComfyCCNextInterval = self:GetUpdateInterval(remaining)

    if remaining <= 0 then
        text:Hide()
        return
    end

    if self.db.showOnlyFinal then
        local finalSeconds = AccessibleNumber(self.db.finalSeconds) or 30
        if remaining > finalSeconds then
            text:Hide()
            return
        end
    end

    if self:HasExternalCountdownText(cooldown) then
        text:Hide()
        return
    end

    local display = self:FormatRemaining(remaining)
    if not display or display == "" then
        text:Hide()
        return
    end

    self:ApplyTextStyle(cooldown)
    text:SetText(display)
    text:Show()
end

function CC:RefreshAllCooldowns()
    for cooldown in pairs(self.cooldowns) do
        if not IsForbiddenFrame(cooldown) then
            self:ApplyTextStyle(cooldown)
            self:UpdateCooldownText(cooldown)
        end
    end
end

function CC:ScanKnownCooldowns()
    local comfyBar = _G.ComfyBar
    if comfyBar and comfyBar.bars then
        for _, bar in pairs(comfyBar.bars) do
            if bar and bar.actionButtons then
                for _, button in ipairs(bar.actionButtons) do
                    if button and button.cooldown and not IsForbiddenFrame(button.cooldown) then
                        self:RegisterCooldown(button.cooldown)
                    end
                end
            end
        end
    end
end

function CC:InitializeCooldownHooks()
    if self.hooksInstalled then return end
    self.hooksInstalled = true

    if type(hooksecurefunc) == "function" and type(CooldownFrame_Set) == "function" then
        hooksecurefunc("CooldownFrame_Set", function(cooldown, startTime, duration, enable, drawEdge, modRate)
            if not IsForbiddenFrame(cooldown) then
                CC:RecordCooldown(cooldown, startTime, duration, enable, modRate)
            end
        end)
    end

    if type(hooksecurefunc) == "function" and CooldownFrameMixin then
        if type(CooldownFrameMixin.SetCooldown) == "function" then
            hooksecurefunc(CooldownFrameMixin, "SetCooldown", function(cooldown, startTime, duration, modRate)
                if not IsForbiddenFrame(cooldown) then
                    CC:RecordCooldown(cooldown, startTime, duration, 1, modRate)
                end
            end)
        end

        if type(CooldownFrameMixin.Clear) == "function" then
            hooksecurefunc(CooldownFrameMixin, "Clear", function(cooldown)
                if not IsForbiddenFrame(cooldown) then
                    CC:ClearCooldown(cooldown)
                end
            end)
        end
    end
end
