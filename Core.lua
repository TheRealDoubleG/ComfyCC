local ADDON_NAME = ...

ComfyCC = ComfyCC or {}
local CC = ComfyCC

CC.name = ADDON_NAME or "ComfyCC"
CC.version = "0.3"
CC.buildDate = "27.09.2026"
CC.status = "Beta"
CC.gameVersion = "WoW Forever 1.60.1"
CC.targetBuild = "70009"
CC.interface = 16001
CC.author = "TheRealDoubleG"
CC.discord = "the.real.double.g"
CC.github = "https://github.com/TheRealDoubleG/ComfyCC"

local defaults = {
    enabled = true,
    showDecimals = true,
    minDuration = 2.0,
    decimalThreshold = 10.0,
    fontSize = 16,
    textScale = 1.0,
    optionsWindow = {
        point = "CENTER",
        relativePoint = "CENTER",
        x = 0,
        y = 0,
    },
    ui = {
        windowLocked = false,
        windowOpacity = 100,
        showWindowBorder = true,
        backgroundAlpha = 92,
    },
}

local function CopyTable(src)
    if type(src) ~= "table" then return src end
    local dst = {}
    for k, v in pairs(src) do
        dst[k] = CopyTable(v)
    end
    return dst
end

local function ApplyDefaults(dst, src)
    for k, v in pairs(src) do
        if type(v) == "table" then
            if type(dst[k]) ~= "table" then dst[k] = {} end
            ApplyDefaults(dst[k], v)
        elseif dst[k] == nil then
            dst[k] = v
        end
    end
end

function CC:Print(msg)
    if DEFAULT_CHAT_FRAME then
        DEFAULT_CHAT_FRAME:AddMessage("|cffffd200ComfyCC:|r " .. tostring(msg))
    end
end

function CC:GetClientBuildInfo()
    if type(GetBuildInfo) ~= "function" then
        return "?", "?", "?", nil
    end
    local version, build, buildDate, interface = GetBuildInfo()
    return tostring(version or "?"), tostring(build or "?"), tostring(buildDate or "?"), tonumber(interface)
end

function CC:GetCompatibilityStatus()
    local _, _, _, clientInterface = self:GetClientBuildInfo()
    if clientInterface and tonumber(clientInterface) == tonumber(self.interface) then
        return true, self:T("COMPAT_MATCH")
    end
    return false, self:T("COMPAT_UPDATE_REQUIRED")
end

function CC:InitializeDB()
    if self.InitializeProfileStorage then
        self:InitializeProfileStorage(defaults, "ComfyCCDB")
    else
        if type(ComfyCCDB) ~= "table" then
            ComfyCCDB = CopyTable(defaults)
        else
            ApplyDefaults(ComfyCCDB, defaults)
        end
        self.db = ComfyCCDB
    end
end

function CC:SetEnabled(value)
    self.db.enabled = value and true or false
    if self.RefreshAllCooldowns then self:RefreshAllCooldowns() end
    if self.RefreshOptions then self:RefreshOptions() end
    self:Print(self.db.enabled and self:T("ENABLED_MSG") or self:T("DISABLED_MSG"))
end

function CC:ToggleEnabled()
    self:SetEnabled(not self.db.enabled)
end

function CC:OpenOptions()
    if self.ShowOptions then self:ShowOptions() end
end

SLASH_COMFYCC1 = "/comfycc"
SLASH_COMFYCC2 = "/cc"
SlashCmdList.COMFYCC = function(msg)
    msg = tostring(msg or ""):lower():match("^%s*(.-)%s*$")
    if msg == "on" then
        CC:SetEnabled(true)
    elseif msg == "off" then
        CC:SetEnabled(false)
    elseif msg == "toggle" then
        CC:ToggleEnabled()
    else
        CC:OpenOptions()
    end
end

local events = CreateFrame("Frame")
events:RegisterEvent("ADDON_LOADED")
events:RegisterEvent("PLAYER_LOGIN")

events:SetScript("OnEvent", function(_, event, arg1)
    if event == "ADDON_LOADED" and arg1 == CC.name then
        CC:InitializeDB()
        if CC.InitializeCooldownHooks then CC:InitializeCooldownHooks() end
        if CC.InitializeOptions then CC:InitializeOptions() end
    elseif event == "PLAYER_LOGIN" then
        if CC.ScanKnownCooldowns then CC:ScanKnownCooldowns() end
        if CC.RefreshAllCooldowns then CC:RefreshAllCooldowns() end
    end
end)
