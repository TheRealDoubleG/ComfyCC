ComfyCC = ComfyCC or {}
local CC = ComfyCC

CC.version = "0.7"
CC.buildDate = "04.10.2026"

local function IsSecret(value)
    if type(issecretvalue)=="function" then local ok,v=pcall(issecretvalue,value); if ok then return v and true or false end end
    if type(canaccessvalue)=="function" then local ok,v=pcall(canaccessvalue,value); if ok then return not v end end
    return false
end

local function EnsureDefaults()
    if not CC.db then return end
    CC.db.auras = CC.db.auras or {}
    local a=CC.db.auras
    local defaults={
        playerBuffs=true, playerDebuffs=true,
        targetBuffs=true, targetDebuffs=true,
        groupBuffs=true, groupDebuffs=true,
        raidBuffs=false, raidDebuffs=false,
        position="inside",
        autoFont=true,
    }
    for k,v in pairs(defaults) do if a[k]==nil then a[k]=v end end
end

local originalInitializeDB=CC.InitializeDB
function CC:InitializeDB(...)
    local r
    if originalInitializeDB then r=originalInitializeDB(self,...) end
    EnsureDefaults(); return r
end

local function FindCooldown(button)
    if not button then return nil end
    local candidates={button.Cooldown,button.cooldown,button.CooldownFrame,button.cooldownFrame}
    for _,c in pairs(candidates) do if c and type(c.SetCooldown)=="function" then return c end end
    local name=button.GetName and button:GetName()
    if name then
        for _,suffix in ipairs({"Cooldown","CooldownFrame"}) do
            local c=_G[name..suffix]; if c and type(c.SetCooldown)=="function" then return c end
        end
    end
    return nil
end

local function AuraData(unit,index,filter)
    if C_UnitAuras and type(C_UnitAuras.GetAuraDataByIndex)=="function" then
        local ok,a=pcall(C_UnitAuras.GetAuraDataByIndex,unit,index,filter)
        if ok and type(a)=="table" then return a.duration,a.expirationTime end
    end
    local fn=UnitAura
    if filter=="HELPFUL" and type(UnitBuff)=="function" then fn=UnitBuff elseif filter=="HARMFUL" and type(UnitDebuff)=="function" then fn=UnitDebuff end
    if type(fn)~="function" then return nil,nil end
    local values={pcall(fn,unit,index,filter)}
    if not values[1] or not values[2] then return nil,nil end
    return values[7],values[8]
end

local function MarkCooldown(cd,owner,kind,button)
    if not cd then return end
    cd.__ComfyCCAura=true
    cd.__ComfyCCAuraOwner=owner
    cd.__ComfyCCAuraKind=kind
    cd.__ComfyCCAuraButton=button
    CC:RegisterCooldown(cd)
end

local function RecordAuraButton(button,unit,index,filter,owner,kind)
    if not button or not button:IsShown() then return end
    local cd=FindCooldown(button); if not cd then return end
    MarkCooldown(cd,owner,kind,button)
    local duration,expiration=AuraData(unit,index,filter)
    if duration==nil or expiration==nil or IsSecret(duration) or IsSecret(expiration) then
        cd.__ComfyCCProtected=true
        if cd.__ComfyCCText then cd.__ComfyCCText:Hide() end
        return
    end
    duration,expiration=tonumber(duration),tonumber(expiration)
    if duration and expiration and duration>0 and expiration>0 then
        CC:RecordCooldown(cd,expiration-duration,duration,1,1)
    else
        CC:ClearCooldown(cd)
    end
end

local function ScanNamedSeries(prefix,count,unit,filter,owner,kind)
    for i=1,count do
        local b=_G[prefix..i]
        if b then RecordAuraButton(b,unit,i,filter,owner,kind) end
    end
end

local function MarkDescendantCooldowns(frame,owner,kind,depth)
    if not frame or (depth or 0)>5 then return end
    local cd=FindCooldown(frame)
    if cd then MarkCooldown(cd,owner,kind,frame) end
    if type(frame.GetChildren)=="function" then
        local children={frame:GetChildren()}
        for _,child in ipairs(children) do MarkDescendantCooldowns(child,owner,kind,(depth or 0)+1) end
    end
end

function CC:ScanAuraCooldowns()
    if not self.db or not self.db.enabled then return end
    EnsureDefaults()

    ScanNamedSeries("BuffButton",40,"player","HELPFUL","player","buff")
    ScanNamedSeries("DebuffButton",24,"player","HARMFUL","player","debuff")
    ScanNamedSeries("TargetFrameBuff",32,"target","HELPFUL","target","buff")
    ScanNamedSeries("TargetFrameDebuff",32,"target","HARMFUL","target","debuff")
    ScanNamedSeries("FocusFrameBuff",32,"focus","HELPFUL","target","buff")
    ScanNamedSeries("FocusFrameDebuff",32,"focus","HARMFUL","target","debuff")

    for party=1,4 do
        ScanNamedSeries("PartyMemberFrame"..party.."Buff",16,"party"..party,"HELPFUL","group","buff")
        ScanNamedSeries("PartyMemberFrame"..party.."Debuff",16,"party"..party,"HARMFUL","group","debuff")
        MarkDescendantCooldowns(_G["CompactPartyFrameMember"..party],"group",nil,0)
    end
    for raid=1,40 do
        MarkDescendantCooldowns(_G["CompactRaidFrame"..raid],"raid",nil,0)
    end
end

function CC:IsAuraCountdownEnabled(cd)
    if not cd or not cd.__ComfyCCAura then return true end
    EnsureDefaults(); local a=self.db.auras
    local owner,kind=cd.__ComfyCCAuraOwner,cd.__ComfyCCAuraKind
    if owner=="player" then return kind=="debuff" and a.playerDebuffs or a.playerBuffs end
    if owner=="target" then return kind=="debuff" and a.targetDebuffs or a.targetBuffs end
    if owner=="group" then
        if kind=="debuff" then return a.groupDebuffs end
        if kind=="buff" then return a.groupBuffs end
        return a.groupBuffs or a.groupDebuffs
    end
    if owner=="raid" then
        if kind=="debuff" then return a.raidDebuffs end
        if kind=="buff" then return a.raidBuffs end
        return a.raidBuffs or a.raidDebuffs
    end
    return true
end

local originalHasExternalCountdownText=CC.HasExternalCountdownText
function CC:HasExternalCountdownText(cooldown)
    if cooldown and cooldown.__ComfyCCAura then return false end
    return originalHasExternalCountdownText and originalHasExternalCountdownText(self,cooldown) or false
end

local originalApplyTextStyle=CC.ApplyTextStyle
function CC:ApplyTextStyle(cooldown)
    if originalApplyTextStyle then originalApplyTextStyle(self,cooldown) end
    if not cooldown or not cooldown.__ComfyCCAura or not cooldown.__ComfyCCText or not self.db then return end
    EnsureDefaults(); local text=cooldown.__ComfyCCText; local a=self.db.auras
    text:ClearAllPoints()
    if a.position=="below" then
        text:SetPoint("TOP",cooldown,"BOTTOM",0,-1)
    else
        text:SetPoint("CENTER",cooldown,"CENTER",0,0)
    end
    if a.autoFont and type(cooldown.GetWidth)=="function" then
        local ok,w=pcall(cooldown.GetWidth,cooldown); w=ok and tonumber(w) or nil
        if w then
            local font,_,flags=text:GetFont(); if font then text:SetFont(font,math.max(8,math.min(tonumber(self.db.fontSize) or 16,math.floor(w*.42+0.5))),flags) end
        end
    end
end

local originalUpdateCooldownText=CC.UpdateCooldownText
function CC:UpdateCooldownText(cooldown)
    if cooldown and cooldown.__ComfyCCAura then
        EnsureDefaults()
        if self.db.auras.position=="off" or not self:IsAuraCountdownEnabled(cooldown) then
            if cooldown.__ComfyCCText then cooldown.__ComfyCCText:Hide() end
            return
        end
    end
    if originalUpdateCooldownText then originalUpdateCooldownText(self,cooldown) end
end

local originalRefreshAllCooldowns=CC.RefreshAllCooldowns
function CC:RefreshAllCooldowns(...)
    if originalRefreshAllCooldowns then originalRefreshAllCooldowns(self,...) end
    self:ScanAuraCooldowns()
end

local originalScanKnownCooldowns=CC.ScanKnownCooldowns
function CC:ScanKnownCooldowns(...)
    if originalScanKnownCooldowns then originalScanKnownCooldowns(self,...) end
    self:ScanAuraCooldowns()
end

local function StartAuraScanner()
    if CC.auraScanner then return end
    local f=CreateFrame("Frame")
    for _,ev in ipairs({"UNIT_AURA","PLAYER_TARGET_CHANGED","PLAYER_FOCUS_CHANGED","GROUP_ROSTER_UPDATE","PLAYER_ENTERING_WORLD"}) do pcall(f.RegisterEvent,f,ev) end
    f:SetScript("OnEvent",function() CC:ScanAuraCooldowns(); CC:RefreshAllCooldowns() end)
    f:SetScript("OnUpdate",function(self,elapsed)
        self.elapsed=(self.elapsed or 0)+(tonumber(elapsed) or 0); if self.elapsed<0.50 then return end; self.elapsed=0; CC:ScanAuraCooldowns()
    end)
    CC.auraScanner=f
end

local originalInitializeCooldownHooks=CC.InitializeCooldownHooks
function CC:InitializeCooldownHooks(...)
    if originalInitializeCooldownHooks then originalInitializeCooldownHooks(self,...) end
    StartAuraScanner()
end

local function Check(parent,text,x,y,get,set)
    local c=CreateFrame("CheckButton",nil,parent,"UICheckButtonTemplate"); c:SetPoint("TOPLEFT",x,y); local t=c.Text or c.text; if t then t:SetText(text) end
    c:SetChecked(get() and true or false); c:SetScript("OnClick",function(self) set(self:GetChecked() and true or false); CC:ScanAuraCooldowns(); CC:RefreshAllCooldowns() end); return c
end
local function ModeButton(parent,text,x,y,value)
    local b=CreateFrame("Button",nil,parent,"UIPanelButtonTemplate"); b:SetSize(100,24); b:SetPoint("TOPLEFT",x,y); b:SetText(text)
    b:SetScript("OnClick",function() CC.db.auras.position=value; CC:RefreshAllCooldowns(); CC:RefreshAuraModeButtons() end); b._mode=value; return b
end
function CC:RefreshAuraModeButtons()
    if not self.auraModeButtons then return end
    local current=self.db and self.db.auras and self.db.auras.position or "inside"
    for _,b in ipairs(self.auraModeButtons) do if b.LockHighlight then if b._mode==current then b:LockHighlight() else b:UnlockHighlight() end end end
end

local originalInitializeOptions=CC.InitializeOptions
function CC:InitializeOptions(...)
    if originalInitializeOptions then originalInitializeOptions(self,...) end
    if self.__auraOptionsBuilt or not self.optionsFrame then return end
    self.__auraOptionsBuilt=true; EnsureDefaults()
    local page=self.optionsFrame.pages and self.optionsFrame.pages[1]; if not page then return end
    local a=self.db.auras
    local title=page:CreateFontString(nil,"ARTWORK","GameFontNormalLarge"); title:SetPoint("TOPLEFT",390,-15); title:SetText("Auren")
    Check(page,"Spieler Buffs",390,-50,function() return a.playerBuffs end,function(v) a.playerBuffs=v end)
    Check(page,"Spieler Debuffs",545,-50,function() return a.playerDebuffs end,function(v) a.playerDebuffs=v end)
    Check(page,"Ziel Buffs",390,-82,function() return a.targetBuffs end,function(v) a.targetBuffs=v end)
    Check(page,"Ziel Debuffs",545,-82,function() return a.targetDebuffs end,function(v) a.targetDebuffs=v end)
    Check(page,"Gruppe Buffs",390,-114,function() return a.groupBuffs end,function(v) a.groupBuffs=v end)
    Check(page,"Gruppe Debuffs",545,-114,function() return a.groupDebuffs end,function(v) a.groupDebuffs=v end)
    Check(page,"Raid Buffs",390,-146,function() return a.raidBuffs end,function(v) a.raidBuffs=v end)
    Check(page,"Raid Debuffs",545,-146,function() return a.raidDebuffs end,function(v) a.raidDebuffs=v end)
    Check(page,"Schrift automatisch skalieren",390,-180,function() return a.autoFont end,function(v) a.autoFont=v end)
    local p=page:CreateFontString(nil,"ARTWORK","GameFontNormal"); p:SetPoint("TOPLEFT",390,-225); p:SetText("Countdown-Position")
    self.auraModeButtons={ModeButton(page,"Im Icon",390,-250,"inside"),ModeButton(page,"Darunter",495,-250,"below"),ModeButton(page,"Aus",600,-250,"off")}
    self:RefreshAuraModeButtons()
end
