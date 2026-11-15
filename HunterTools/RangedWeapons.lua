local _,F=...
function F.RangedWeaponSourceLabel(w)
    if w.sourceType=='crafted' then return 'Crafted','ffcc77' end
    if w.sourceType=='instance' then return 'Instance drop','bbaaff' end
    if w.sourceType=='vendor' then
        return w.vendorCategory=='pvp' and 'Vendor: PvP' or w.vendorCategory=='reputation' and 'Vendor: reputation' or 'Vendor','66ddff'
    end
    return 'Source unverified','aaaaaa'
end
local function color(hex,value) return '|cff'..hex..value..'|r' end
function F.RangedWeaponStatsText(stats)
    local lines={}
    for line in stats:gmatch('[^\r\n]+') do
        local tint=line:find('Requires Level',1,true) and 'ffdd66'
            or line:find('damage per second',1,true) and '66ee88'
            or line:find('Damage',1,true) and '77ddff'
            or line:match('^Requires') and 'ffbb77'
            or (line:match('^Durability') or line:match('^Binds') or line:match('^Item Level')) and 'aaaaaa'
        lines[#lines+1]=tint and color(tint,line) or line
    end
    return table.concat(lines,'\n')
end
function F.RangedWeaponSourceText(source)
    local lines={}
    for line in source:gmatch('[^\r\n]+') do
        local name,place,rest=line:match('^(.-) — ([^;]+)(.*)$')
        if name then lines[#lines+1]=color('66ddff',name)..' — '..color('ffdd88',place)..color('cccccc',rest)
        else lines[#lines+1]=color('66ddff',line) end
    end
    return table.concat(lines,'\n\n')
end
function F.RangedWeaponSettings()
    F.db.rangedWeapons=type(F.db.rangedWeapons)=='table' and F.db.rangedWeapons or {}
    return F.db.rangedWeapons
end
function F.FilterRangedWeapons(kind,source,query,minLevel,maxLevel,faction)
    local result={};query=(query or ''):lower()
    for _,w in ipairs(F.rangedWeaponCatalog) do
        if (not kind or kind=='all' or w.kind==kind) and (not source or source=='all' or w.sourceType==source or w.vendorCategory==source)
            and w.level>=(minLevel or 1) and w.level<=(maxLevel or 100)
            and (not faction or not w.side or w.side=='Both' or w.side==faction)
            and (w.name..' '..w.source):lower():find(query,1,true) then result[#result+1]=w end
    end
    table.sort(result,function(a,b)
        if a.kind~=b.kind then return a.kind<b.kind end
        if a.level~=b.level then return a.level<b.level end
        if a.name~=b.name then return a.name<b.name end
        return a.id<b.id
    end)
    return result
end
function F.EquippedRangedWeaponKind()
    local link=GetInventoryItemLink and GetInventoryItemLink('player',18)
    if not link then return end
    local info=C_Item and C_Item.GetItemInfoInstant or GetItemInfoInstant
    if type(info)=='function' then
        local ok,_,_,_,_,_,class,subclass=pcall(info,link)
        if ok and (not issecretvalue or (not issecretvalue(class) and not issecretvalue(subclass))) and class==2 then
            return ({[2]='bows',[3]='guns',[18]='crossbows'})[subclass]
        end
    end
    local weapon=F.ReadComparisonWeapon and F.ReadComparisonWeapon(link)
    if weapon then return ({[2]='bows',[3]='guns',[18]='crossbows'})[weapon.subclass] end
end
function F.SuggestRangedWeapon(level,kind,source,query,faction)
    if type(level)~='number' or (issecretvalue and issecretvalue(level)) then return end
    local best,score
    for _,w in ipairs(F.FilterRangedWeapons(kind,source,query,1,level)) do
        if w.speed>0 and (not w.side or w.side=='Both' or not faction or w.side==faction) then
            local dps=(w.min+w.max)/2/w.speed
            if not score or dps>score or (dps==score and (w.level<best.level or w.level==best.level and w.id<best.id)) then best=w;score=dps end
        end
    end
    return best,score
end
function F.RangedWeaponBaseComparison(w,base)
    if not base or not base.speed or base.speed<=0 or w.speed<=0 then return end
    return (w.min+w.max-base.min-base.max)/2,(w.min+w.max)/2/w.speed-(base.min+base.max)/2/base.speed
end
local function hunter() local _,class=UnitClass('player');return class=='HUNTER' end
local function showAlert(items)
    if #items==0 then return end
    if not F.rangedWeaponAlert then
        local p=CreateFrame('Frame','HunterToolsRangedWeaponAlert',UIParent,'BackdropTemplate');F.rangedWeaponAlert=p
        p:SetSize(420,190);p:SetPoint('CENTER',0,160);p:SetFrameStrata('DIALOG')
        CreateFrame('Button',nil,p,'UIPanelCloseButton'):SetPoint('TOPRIGHT',-3,-3)
        p.message=F.MenuText(p,'',22,-30,375);p.message:SetHeight(100)
        local b=CreateFrame('Button',nil,p,'UIPanelButtonTemplate');b:SetSize(230,26);b:SetPoint('BOTTOM',0,22);b:SetText('Browse newly usable weapons')
        p.browseButton=b
        b:SetScript('OnClick',function()
            p:Hide();F.OpenRangedWeapons()
            local browser=F.rangedWeaponsPanel;local s=F.RangedWeaponSettings()
            if browser then
                browser.minLevel=p.minLevel;browser.maxLevel=p.maxLevel
                browser.kind=s.alertKind;browser.source=s.alertSource;browser.search:SetText('');browser.offset=0
                browser:Refresh()
            end
        end)
        table.insert(UISpecialFrames,'HunterToolsRangedWeaponAlert');F.FinishMenu(p,420,190)
    end
    local p=F.rangedWeaponAlert;p.minLevel=items[1].level;p.maxLevel=items[1].level
    local names={}
    for i,w in ipairs(items) do p.minLevel=math.min(p.minLevel,w.level);p.maxLevel=math.max(p.maxLevel,w.level);if i<=3 then names[#names+1]=w.name end end
    p.message:SetText('New ranged weapon options: '..#items..'\n'..table.concat(names,'\n')..'\nRequired level reached; source access is separate.');p:Show()
end
function F.CheckRangedWeaponLevel(level)
    if not F.db or not hunter() or type(level)~='number' or (issecretvalue and issecretvalue(level)) then return end
    local s=F.RangedWeaponSettings();local previous=F.rangedWeaponLastLevel
    F.rangedWeaponLastLevel=level
    if not previous or level<=previous or not s.alerts then return end
    local items=F.FilterRangedWeapons(s.alertKind,s.alertSource,nil,previous+1,level)
    for _,w in ipairs(items) do F.rangedWeaponPending=F.rangedWeaponPending or {};F.rangedWeaponPending[#F.rangedWeaponPending+1]=w end
    if not InCombatLockdown() and F.rangedWeaponPending then showAlert(F.rangedWeaponPending);F.rangedWeaponPending=nil end
end
local function comparison(w)
    local lines={};local equipped=GetInventoryItemLink('player',18)
    local base=F.ReadComparisonWeapon(equipped)
    local candidate=F.ReadComparisonWeapon('item:'..w.id)
    local shot,dps=F.RangedWeaponBaseComparison(candidate or w,base)
    if shot then lines[#lines+1]=('Base vs equipped: %+.1f average damage / %+.2f weapon DPS'):format(shot,dps)
    else lines[#lines+1]='Base comparison: equip a ranged weapon; item data may still be loading.' end
    local r,reason=F.BuildWeaponComparison('item:'..w.id)
    if r then
        lines[#lines+1]=('Estimated Auto Shot: %.1f–%.1f; %.2f DPS\nVs equipped: %+.1f average/shot; %+.2f DPS'):format(r.min,r.max,r.dps,r.shotDelta,r.dpsDelta)
        lines[#lines+1]='Scope: '..r.scope.name..'; current ammo DPS held equal.'
    else lines[#lines+1]='Auto Shot: '..(reason or 'Item data is loading.') end
    lines[#lines+1]='Experimental estimate: before armor, misses and crit. Procs, stat multipliers, weapon talents, proficiency and quiver changes are not simulated. Check compatible ammo when changing weapon type.'
    return table.concat(lines,'\n\n')
end
function F.OpenRangedWeapons(minLevel,maxLevel)
    if InCombatLockdown() then F.Print('Open the weapon catalog after combat.');return end
    F.HideConfigPages()
    if not F.rangedWeaponsPanel then
        local p=CreateFrame('Frame','HunterToolsRangedWeapons',UIParent,'BackdropTemplate');F.rangedWeaponsPanel=p
        p:SetSize(740,625);p:SetPoint('CENTER');p:SetFrameStrata('DIALOG');p:EnableMouse(true)
        CreateFrame('Button',nil,p,'UIPanelCloseButton'):SetPoint('TOPRIGHT',-3,-3)
        table.insert(UISpecialFrames,'HunterToolsRangedWeapons')
        F.MenuText(p,'Ranged weapon catalog & suggestions',22,-22,680,'GameFontNormalLarge')
        F.MenuText(p,'List: type, level, name. Suggestion: highest base DPS for your equipped type.',22,-51,690)
        local function button(label,x,y,width,fn)
            local b=CreateFrame('Button',nil,p,'UIPanelButtonTemplate');b:SetSize(width,25);b:SetPoint('TOPLEFT',x,y);b:SetText(label);b:SetScript('OnClick',fn);return b
        end
        for i,spec in ipairs({{'All','all'},{'Guns','guns'},{'Bows','bows'},{'Crossbows','crossbows'}}) do
            local key=spec[2];button(spec[1],22+(i-1)*101,-78,96,function() p.kind=key;p.offset=0;p:Refresh() end)
        end
        for i,spec in ipairs({{'All sources','all'},{'Crafted','crafted'},{'Instances','instance'},{'Vendors','vendor'},{'Reputation','reputation'},{'PvP','pvp'}}) do
            local key=spec[2];button(spec[1],22+(i-1)*116,-109,110,function() p.source=key;p.offset=0;p:Refresh() end)
        end
        p.search=CreateFrame('EditBox',nil,p,'InputBoxTemplate');p.search:SetSize(270,24);p.search:SetPoint('TOPLEFT',438,-80);p.search:SetAutoFocus(false)
        p.search:SetScript('OnTextChanged',function() p.offset=0;p:Refresh() end)
        p.search:SetScript('OnEscapePressed',function(self) self:ClearFocus() end)
        p.search:SetScript('OnEnterPressed',function(self) self:ClearFocus() end)
        p.summary=F.MenuText(p,'',22,-146,325)
        F.MenuText(p,'Level',519,-146,40)
        p.level=CreateFrame('EditBox',nil,p,'InputBoxTemplate');p.level:SetSize(45,24);p.level:SetPoint('TOPLEFT',561,-140);p.level:SetAutoFocus(false);p.level:SetNumeric(true);p.level:SetMaxLetters(2)
        p.level:SetScript('OnEscapePressed',function(self) self:ClearFocus() end)
        p.suggest=button('Suggested',356,-140,150,function()
            local level=tonumber(p.level:GetText())
            if not level or level~=math.floor(level) or level<1 or level>60 then F.Print('Enter a whole weapon-preview level from 1 to 60.');return end
            p.level:ClearFocus()
            local equippedKind=F.EquippedRangedWeaponKind()
            if equippedKind then p.kind=equippedKind
            else F.Print('Equipped ranged type is unavailable; using the current type filter.') end
            local faction=UnitFactionGroup and UnitFactionGroup('player')
            p.minLevel=1;p.maxLevel=level;p.levelFiltered=true;p.offset=0;p.selected=nil;p:Refresh()
            local w,dps=F.SuggestRangedWeapon(level,p.kind,p.source,p.search:GetText(),faction)
            if not w then F.Print('No catalog weapon matches your level, faction and filters.');return end
            p.selected=w;p:Refresh()
            for i,item in ipairs(p.items) do if item.id==w.id then p.offset=math.floor((i-1)/9)*9;break end end
            p:Refresh();F.Print(('Level-based suggestion: %s (%.2f base weapon DPS). Check the listed purchase/source requirements; this is not a full gear simulation.'):format(w.name,dps))
        end)
        p.level:SetScript('OnEnterPressed',function() p.suggest:GetScript('OnClick')() end)
        p.fullList=button('Full list',615,-140,94,function()
            p.minLevel=nil;p.maxLevel=nil;p.levelFiltered=nil;p.offset=0;p.selected=nil
            p.search:SetText('');p:Refresh()
        end)
        p.rows={}
        for i=1,9 do
            local b=button('',22,-173-(i-1)*32,298,function(self) p.selected=self.weapon;p:Details() end);b:SetHeight(30);p.rows[i]=b
            b:SetScript('OnEnter',function(self) if self.weapon then GameTooltip:SetOwner(self,'ANCHOR_RIGHT');GameTooltip:SetHyperlink('item:'..self.weapon.id);GameTooltip:Show() end end)
            b:SetScript('OnLeave',function() GameTooltip:Hide() end)
        end
        button('Previous',22,-466,95,function() p.offset=math.max(0,(p.offset or 0)-9);p:Refresh() end)
        button('Next',124,-466,95,function() if (p.offset or 0)+9<#p.items then p.offset=(p.offset or 0)+9;p:Refresh() end end)
        button('All levels',226,-466,95,function() p.minLevel=nil;p.maxLevel=nil;p.levelFiltered=nil;p.offset=0;p:Refresh() end)
        local scroll=CreateFrame('ScrollFrame',nil,p,'UIPanelScrollFrameTemplate');scroll:SetPoint('TOPLEFT',338,-173);scroll:SetSize(350,319)
        local body=CreateFrame('Frame',nil,scroll);body:SetSize(345,1);scroll:SetScrollChild(body)
        p.detail=F.MenuText(body,'Select a weapon.',0,0,340);p.detail:SetJustifyH('LEFT')
        p.alerts=CreateFrame('CheckButton',nil,p,'UICheckButtonTemplate');p.alerts:SetPoint('TOPLEFT',19,-512)
        F.MenuText(p,'Pop up at newly usable levels (uses the alert filters below)',55,-521,650)
        p.alerts:SetScript('OnClick',function(self) F.RangedWeaponSettings().alerts=self:GetChecked() and true or false end)
        button('Use current type/source for alerts',22,-552,298,function() local s=F.RangedWeaponSettings();s.alertKind=p.kind or 'all';s.alertSource=p.source or 'all';p:Refresh() end)
        p.alertLabel=F.MenuText(p,'',338,-559,370)
        F.MenuText(p,'Edition-specific source snapshot. Level means usable, not guaranteed dungeon or recipe access.',22,-593,690)
        function p:Details()
            local w=self.selected;if not w then self.detail:SetText('Select a weapon.');return end
            local help=w.sourceType=='vendor' and ('Purchase requirements:\n'..(w.requirements or 'Check current vendor requirements.')..'\nPrices/stock are a snapshot; discounts and availability may change. Level alone does not unlock reputation or PvP purchases.')
                or w.sourceType=='crafted' and 'Ask an engineer; binding and profession requirements shown above still apply.'
                or 'Named NPC/chest or zone drop as listed. Zone/boss-drop records without a name have no verified specific mob or chest.'
            local source,tint=F.RangedWeaponSourceLabel(w)
            self.detail:SetText(color(tint,'Source: '..source)..'\n\n'..color('aaaaaa','Catalog stats (snapshot; hover for live item):')..'\n'..F.RangedWeaponStatsText(w.stats)..'\n\n'..color('ffdd66','Where to get it')..'\n'..F.RangedWeaponSourceText(w.source)..'\n\n'..color(w.sourceType=='vendor' and 'ffbb77' or 'aaaaaa',help)..'\n\n'..color('ffdd66','Equipped weapon comparison')..'\n'..comparison(w))
            self.detail:SetHeight(self.detail:GetStringHeight()+8);body:SetHeight(math.max(320,self.detail:GetHeight()))
        end
        function p:Refresh()
            if not F.db then return end
            local faction=self.levelFiltered and UnitFactionGroup and UnitFactionGroup('player') or nil
            self.items=F.FilterRangedWeapons(self.kind,self.source,self.search:GetText(),self.minLevel,self.maxLevel,faction)
            self.summary:SetText(('%d weapons | %s | %s%s'):format(#self.items,self.kind or 'all',self.source or 'all',self.minLevel and (' | levels '..self.minLevel..'–'..self.maxLevel) or ''))
            for i,b in ipairs(self.rows) do
                local w=self.items[(self.offset or 0)+i];b.weapon=w
                if w then local source,tint=F.RangedWeaponSourceLabel(w);b:SetText(('|cffffdd66L%d|r %s\n|cff%s%s|r'):format(w.level,w.name,tint,source));b:Show() else b:Hide() end
            end
            local s=F.RangedWeaponSettings();self.alerts:SetChecked(s.alerts==true)
            self.alertLabel:SetText('Alerts: '..(s.alertKind or 'all')..' / '..(s.alertSource or 'all'))
            self:Details()
        end
        p:RegisterEvent('GET_ITEM_INFO_RECEIVED');p:RegisterEvent('PLAYER_EQUIPMENT_CHANGED')
        p:SetScript('OnEvent',function(_,event,id)
            if not p:IsShown() or not p.selected then return end
            if event=='GET_ITEM_INFO_RECEIVED' and id~=p.selected.id and (not GetInventoryItemID or id~=GetInventoryItemID('player',18)) then return end
            if event=='PLAYER_EQUIPMENT_CHANGED' and id~=18 and id~=0 then return end
            if p.detailRefreshPending then return end
            p.detailRefreshPending=true
            local function refresh() p.detailRefreshPending=nil;if p:IsShown() then p:Details() end end
            if C_Timer and C_Timer.After then C_Timer.After(0,refresh) else refresh() end
        end)
        F.FinishMenu(p,740,625)
    end
    local p=F.rangedWeaponsPanel;p.minLevel=minLevel;p.maxLevel=maxLevel;p.levelFiltered=nil;p.offset=0
    local level=UnitLevel('player');if type(level)=='number' and (not issecretvalue or not issecretvalue(level)) then p.level:SetText(tostring(level)) end
    p:Show();p:Refresh()
end
local events=CreateFrame('Frame')
for _,event in ipairs({'PLAYER_ENTERING_WORLD','PLAYER_LEVEL_UP','PLAYER_REGEN_ENABLED'}) do events:RegisterEvent(event) end
events:SetScript('OnEvent',function(_,event,level)
    if event=='PLAYER_ENTERING_WORLD' then F.rangedWeaponLastLevel=UnitLevel('player')
    elseif event=='PLAYER_LEVEL_UP' then F.CheckRangedWeaponLevel(level)
    elseif F.db and F.rangedWeaponPending and not InCombatLockdown() then
        if F.RangedWeaponSettings().alerts then showAlert(F.rangedWeaponPending) end
        F.rangedWeaponPending=nil
    end
end)
