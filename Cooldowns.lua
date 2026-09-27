ComfyCC = ComfyCC or {}
local CC = ComfyCC

CC.cooldowns = CC.cooldowns or setmetatable({}, {__mode = "k"})
CC.hooksInstalled = CC.hooksInstalled or false

local UPDATE_INTERVAL = 0.05

local function IsNumber(value)
    return type(value) == "number"
end

local function Clamp(value, minValue, maxValue)
    value = tonumber(value) or minValue
    if value < minValue then return minValue end
    if value > maxValue then return maxValue end
    return value
end

function CC:FormatRemaining(remaining)
    remaining = math.max(0, tonumber(remaining) or 0)

    if remaining >= 3600 then
        return string.format("%dh", math.ceil(remaining / 3600))
    elseif remaining >= 60 then
        return string.format("%dm", math.ceil(remaining / 60))
    end

    local threshold = tonumber(self.db and self.db.decimalThreshold) or 10
    if self.db and self.db.showDecimals and remaining < threshold and remaining > 0 then
        return string.format("%.1f", remaining)
    end

    return tostring(math.ceil(remaining))
end

function CC:ApplyTextStyle(cooldown)
    local text = cooldown and cooldown.__ComfyCCText
    if not text or not self.db then return end

    local fontPath, _, flags = text:GetFont()
    if fontPath then
        text:SetFont(fontPath, Clamp(self.db.fontSize, 8, 40), flags)
    end
    text:SetScale(Clamp(self.db.textScale, 0.5, 2.0))
end

function CC:RegisterCooldown(cooldown)
    if not cooldown or type(cooldown) ~= "table" then return end
    if self.cooldowns[cooldown] then
        self:ApplyTextStyle(cooldown)
        return
    end

    self.cooldowns[cooldown] = true

    local text = cooldown:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    text:SetPoint("CENTER", cooldown, "CENTER", 0, 0)
    text:SetJustifyH("CENTER")
    text:SetJustifyV("MIDDLE")
    text:SetTextColor(1, 1, 1, 1)
    text:SetShadowOffset(1, -1)
    text:Hide()

    cooldown.__ComfyCCText = text
    cooldown.__ComfyCCElapsed = 0

    self:ApplyTextStyle(cooldown)

    cooldown:HookScript("OnUpdate", function(frame, elapsed)
        if not CC.db then return end
        frame.__ComfyCCElapsed = (frame.__ComfyCCElapsed or 0) + (elapsed or 0)
        if frame.__ComfyCCElapsed < UPDATE_INTERVAL then return end
        frame.__ComfyCCElapsed = 0
        CC:UpdateCooldownText(frame)
    end)

    cooldown:HookScript("OnHide", function(frame)
        if frame.__ComfyCCText then frame.__ComfyCCText:Hide() end
    end)
end

function CC:RecordCooldown(cooldown, startTime, duration, enable, modRate)
    if not cooldown then return end
    self:RegisterCooldown(cooldown)

    cooldown.__ComfyCCStart = IsNumber(startTime) and startTime or 0
    cooldown.__ComfyCCDuration = IsNumber(duration) and duration or 0
    cooldown.__ComfyCCEnable = enable == nil and 1 or enable
    cooldown.__ComfyCCModRate = (IsNumber(modRate) and modRate > 0) and modRate or 1

    self:UpdateCooldownText(cooldown)
end

function CC:ClearCooldown(cooldown)
    if not cooldown then return end
    cooldown.__ComfyCCStart = nil
    cooldown.__ComfyCCDuration = nil
    cooldown.__ComfyCCEnable = nil
    cooldown.__ComfyCCModRate = nil
    if cooldown.__ComfyCCText then cooldown.__ComfyCCText:Hide() end
end

function CC:UpdateCooldownText(cooldown)
    if not cooldown or not cooldown.__ComfyCCText or not self.db then return end

    local text = cooldown.__ComfyCCText

    if not self.db.enabled or not cooldown:IsShown() then
        text:Hide()
        return
    end

    local startTime = cooldown.__ComfyCCStart
    local duration = cooldown.__ComfyCCDuration
    local enable = cooldown.__ComfyCCEnable
    local modRate = cooldown.__ComfyCCModRate or 1

    if not IsNumber(startTime) or not IsNumber(duration) or duration <= 0 or enable == 0 then
        text:Hide()
        return
    end

    if duration < (tonumber(self.db.minDuration) or 2.0) then
        text:Hide()
        return
    end

    local now = GetTime and GetTime() or 0
    local effectiveDuration = duration / math.max(0.01, modRate)
    local remaining = (startTime + effectiveDuration) - now

    if remaining <= 0 then
        text:Hide()
        return
    end

    self:ApplyTextStyle(cooldown)
    text:SetText(self:FormatRemaining(remaining))
    text:Show()
end

function CC:RefreshAllCooldowns()
    for cooldown in pairs(self.cooldowns) do
        self:ApplyTextStyle(cooldown)
        self:UpdateCooldownText(cooldown)
    end
end

function CC:ScanKnownCooldowns()
    local comfyBar = _G.ComfyBar
    if comfyBar and comfyBar.bars then
        for _, bar in pairs(comfyBar.bars) do
            if bar and bar.actionButtons then
                for _, button in ipairs(bar.actionButtons) do
                    if button and button.cooldown then
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
            CC:RecordCooldown(cooldown, startTime, duration, enable, modRate)
        end)
    end

    if type(hooksecurefunc) == "function" and CooldownFrameMixin then
        if type(CooldownFrameMixin.SetCooldown) == "function" then
            hooksecurefunc(CooldownFrameMixin, "SetCooldown", function(cooldown, startTime, duration, modRate)
                CC:RecordCooldown(cooldown, startTime, duration, 1, modRate)
            end)
        end

        if type(CooldownFrameMixin.Clear) == "function" then
            hooksecurefunc(CooldownFrameMixin, "Clear", function(cooldown)
                CC:ClearCooldown(cooldown)
            end)
        end
    end
end
