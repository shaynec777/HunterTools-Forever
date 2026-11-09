local _,F=...
local function safe(v) return not issecretvalue or not issecretvalue(v) end
local function query(fn,...)
    if type(fn)~='function' then return end
    local ok,a,b,c=pcall(fn,...)
    if not ok then return end
    if not safe(a) then a=nil end
    if not safe(b) then b=nil end
    if not safe(c) then c=nil end
    return a,b,c
end
local function number(v) return type(v)=='number' and v==v and math.abs(v)<1e12 end
local function text(v) return type(v)=='string' and v:find('%S') and v or nil end
F.petStatusFields={
    {'identity','Level and family'},{'role','Pet role'},{'health','Health'},{'focus','Focus'},
    {'happiness','Happiness and damage modifier'},{'loyalty','Loyalty and trend'},
    {'training','Training points'},{'abilities','Learned abilities'},{'diet','Diet'},{'food','Food supply and next food'},
    {'feeding','Feeding status'},{'lastFeed','Last successful feeding'},
}
function F.PetStatusSettings()
    if type(F.db.petStatus)~='table' then F.db.petStatus={} end
    local s=F.db.petStatus
    for key,default in pairs({enabled=false,tooltipEnabled=true,locked=false}) do
        if type(s[key])~='boolean' then s[key]=default end
    end
    for key,default in pairs({x=270,y=-160}) do
        if not number(s[key]) or math.abs(s[key])>10000 then s[key]=default end
    end
    for _,surface in ipairs({'windowFields','tooltipFields'}) do
        if type(s[surface])~='table' then s[surface]={} end
        for _,field in ipairs(F.petStatusFields) do
            if type(s[surface][field[1]])~='boolean' then s[surface][field[1]]=true end
        end
    end
    return s
end
local function resource(current,maximum)
    if not number(current) or not number(maximum) or current<0 or maximum<=0 then return 'Unavailable' end
    return ('%d / %d (%d%%)'):format(current,maximum,math.floor(current/maximum*100+0.5))
end
function F.CurrentPetAbilities()
    if InCombatLockdown() then return 'Unavailable during combat' end
    if not query(UnitExists,'pet') then return 'No pet' end
    local book=F.ClassicSpellBook
    local count=query(book and book.HasPetSpells or HasPetSpells)
    if not number(count) or count<0 or count>200 or count~=math.floor(count) then return 'Pet spellbook unavailable; try again after it loads.' end
    if count==0 then return 'Pet spellbook loading; no abilities confirmed yet.' end
    local bank=Enum and Enum.SpellBookSpellBank and Enum.SpellBookSpellBank.Pet
    local abilities,seen={},{};local partial=false
    for i=1,count do
        local info=bank and query(book and book.GetSpellBookItemInfo,i,bank)
        local id=type(info)=='table' and safe(info.spellID) and info.spellID or nil
        if not number(id) and GetSpellBookItemInfo then local _,legacy=query(GetSpellBookItemInfo,i,'pet');id=legacy end
        local name,rank
        if number(id) and id>0 then
            name=text(query(F.ClassicSpell and F.ClassicSpell.GetSpellName,id))
            rank=text(query(F.ClassicSpell and F.ClassicSpell.GetSpellSubtext,id))
        end
        if not name then
            if bank and book and book.GetSpellBookItemName then name,rank=query(book.GetSpellBookItemName,i,bank)
            elseif GetSpellBookItemName then name,rank=query(GetSpellBookItemName,i,'pet') end
            name=text(name);rank=text(rank)
        end
        if name then
            local entry=name..(rank and (' ('..rank..')') or '')
            local key=number(id) and id or entry
            if not seen[key] then abilities[#abilities+1]=entry;seen[key]=true end
        else partial=true end
    end
    table.sort(abilities)
    local result=#abilities>0 and table.concat(abilities,'; ') or 'No readable abilities yet.'
    if partial then result=result..' (Partial list; spellbook data loading.)' end
    return result
end
function F.PetStatusData()
    -- Never inspect restricted unit values or inventory during combat.
    if InCombatLockdown() then return {name='Pet status',paused=true} end
    local exists=query(UnitExists,'pet')
    if not exists then return {name='No pet',missing=true} end
    local d={name=text(query(UnitName,'pet')) or 'Your pet',guid=query(UnitGUID,'pet')}
    local level=query(UnitLevel,'pet'); local family=text(query(UnitCreatureFamily,'pet'))
    d.identity=(number(level) and level>0 and ('Level '..level) or 'Level unavailable')..' - '..(family or 'Family unavailable')
    d.role=F.PetRole and F.PetRole(family) or 'Unknown'
    local hp,maxHP=query(UnitHealth,'pet'),query(UnitHealthMax,'pet')
    local focus,maxFocus=query(UnitPower,'pet',2),query(UnitPowerMax,'pet',2)
    d.health=resource(hp,maxHP);d.focus=resource(focus,maxFocus)
    d.hp=number(hp) and hp or nil;d.maxHP=number(maxHP) and maxHP>0 and maxHP or nil
    d.focusValue=number(focus) and focus or nil;d.maxFocus=number(maxFocus) and maxFocus>0 and maxFocus or nil
    local petInfo=F.ClassicPetInfo or {}
    local happiness,damage,rate=query(petInfo.GetPetHappiness)
    d.happiness=({[1]='Unhappy',[2]='Content',[3]='Happy'})[happiness] or 'Unavailable'
    if number(damage) then d.happiness=d.happiness..(' - %g%% damage'):format(damage) end
    d.happinessValue=happiness
    d.loyalty=text(query(petInfo.GetPetLoyalty)) or 'Unavailable'
    if number(rate) then d.loyalty=d.loyalty..' - '..(rate>0 and 'rising' or rate<0 and 'falling' or 'steady') end
    local total,used=query(petInfo.GetPetTrainingPoints)
    d.training=number(total) and number(used) and total>=used and ('%d available / %d total (%d spent)'):format(total-used,total,used) or 'Unavailable'
    d.diet=F.PetDietText and F.PetDietText():gsub('^Pet eats: ','') or 'Unavailable'
    local s=F.PetStatusSettings()
    if s.windowFields.abilities or (s.tooltipEnabled and s.tooltipFields.abilities) then
        local now=GetTime and GetTime() or 0
        local cache=F.petAbilitiesCache
        if not cache or F.petAbilitiesDirty or cache.guid~=d.guid or now-cache.at>=5 then
            cache={guid=d.guid,at=now,text=F.CurrentPetAbilities()};F.petAbilitiesCache=cache;F.petAbilitiesDirty=false
            -- Partial/unavailable spellbooks should retry on the next update.
            if cache.text:find('loading',1,true) or cache.text:find('unavailable',1,true) then F.petAbilitiesDirty=true end
        end
        d.abilities=cache.text
    end
    if s.windowFields.food or (s.tooltipEnabled and s.tooltipFields.food) then
        if d.guid~=F.petStatusFoodPet then
            F.bagsDirty=true; F.petStatusFoodPet=d.guid
        end
        if F.FindFood and (F.bagsDirty or F.foodCount==nil or F.foodEntryPending) then F.FindFood() end
    end
    if F.foodEntryPending or F.pendingItems or F.lockedFood or F.foodCount==nil then
        d.food='Inventory settling...'
    else
        d.food=('%d suitable item%s'):format(F.foodCount,F.foodCount==1 and '' or 's')
        if F.food and text(F.food.name) then d.food=d.food..' - Next: '..F.food.name end
    end
    local dead=query(UnitIsDeadOrGhost,'pet')
    local effect=F.FEED_EFFECT and query(F.ClassicSpell and F.ClassicSpell.GetSpellName,F.FEED_EFFECT)
    local aura=effect and query(F.ClassicAuras and F.ClassicAuras.GetAuraDataBySpellName,'pet',effect,'HELPFUL')
    d.feeding=dead and 'Pet is dead' or aura and 'Being fed' or happiness==3 and 'Happy - no feeding needed' or (happiness==1 or happiness==2) and 'Hungry' or 'Unavailable'
    local last=d.guid and type(F.db.petLastFeeds)=='table' and F.db.petLastFeeds[d.guid]
    d.lastFeed='Not recorded yet'
    if type(last)=='table' and type(last.food)=='string' and number(last.at) then
        local now=query(time)
        if number(now) and now>=last.at then
            local minutes=math.floor((now-last.at)/60)
            d.lastFeed=last.food..(minutes==0 and ' - just now' or (' - %d min ago'):format(minutes))
        end
    end
    return d
end
local labels={identity='Pet',role='Role',health='Health',focus='Focus',happiness='Happiness',loyalty='Loyalty',training='Training',abilities='Learned abilities',diet='Diet',food='Food',feeding='Feeding',lastFeed='Last fed'}
function F.PetStatusLines(data,fields)
    if data.paused then return {{'Combat','Updates paused until combat ends'}} end
    if data.missing then return {{'Pet','Summon a hunter pet to see its status'}} end
    local lines={}
    for _,field in ipairs(F.petStatusFields) do
        local key=field[1]
        if fields[key] then lines[#lines+1]={labels[key],data[key] or 'Unavailable',key} end
    end
    return lines
end
-- Tooltip-only colors: keep the underlying detail text usable by other views.
local function petTipLine(tooltip,label,value)
    local r,g,b=0.90,0.90,0.90
    local lower=(value or label):lower()
    if not value then r,g,b=0.45,0.78,1 end
    if label=='Pet' or label=='Role' or label=='Focus' or label=='Location' then r,g,b=0.45,0.78,1
    elseif label=='Diet' or label=='Eats' or label=='Food' or label=='In bags' or label=='Usable food (Classic estimate)' then r,g,b=0.55,0.90,0.65
    elseif label:find('reference',1,true) or label:find('baseline',1,true) then r,g,b=0.62,0.67,0.72 end
    if label=='Happiness' or label=='Feeding' or label=='Food' or label=='Combat' or label=='Partial count' then
        if lower:find('unhappy',1,true) or lower:find('dead',1,true) or lower:find('no suitable',1,true) or lower:match('^0 suitable') then r,g,b=1,0.35,0.35
        elseif lower:find('hungry',1,true) or lower:find('content',1,true) or label=='Combat' or label=='Partial count' then r,g,b=1,0.75,0.30
        elseif lower:find('happy',1,true) or lower:find('being fed',1,true) then r,g,b=0.40,1,0.50 end
    end
    local text=value and ('|cffffd580'..label..':|r '..value) or label
    tooltip:AddLine(text,r,g,b,true)
end
function F.AddPetStatusTip(tooltip,data,heading)
    if not F.db or not F.PetStatusSettings().tooltipEnabled then return end
    if tooltip.HunterToolsClassicPetTipAdded then return end
    tooltip.HunterToolsClassicPetTipAdded=true
    tooltip:AddLine(' ')
    tooltip:AddLine(heading or 'HunterTools Classic pet status',1,0.82,0)
    for _,line in ipairs(F.PetStatusLines(data or F.PetStatusData(),F.PetStatusSettings().tooltipFields)) do
        petTipLine(tooltip,line[1],line[2])
    end
end
local function unitTip(tooltip)
    if not F.db or InCombatLockdown() or not F.PetStatusSettings().tooltipEnabled then return end
    local _,unit=query(tooltip.GetUnit,tooltip)
    if type(unit)~='string' or not query(UnitIsUnit,unit,'pet') then return end
    local _,class=query(UnitClass,'player');if class~='HUNTER' then return end
    F.AddPetStatusTip(tooltip)
end
if GameTooltip and GameTooltip.HookScript then
    GameTooltip:HookScript('OnTooltipCleared',function(t) t.HunterToolsClassicPetTipAdded=nil end)
    if TooltipDataProcessor and TooltipDataProcessor.AddTooltipPostCall and Enum and Enum.TooltipDataType and Enum.TooltipDataType.Unit then
        TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Unit,unitTip)
    elseif GameTooltip.HasScript and GameTooltip:HasScript('OnTooltipSetUnit') then
        GameTooltip:HookScript('OnTooltipSetUnit',unitTip)
    end
end
function F.ResetPetStatusPosition()
    if InCombatLockdown() then return end
    local s=F.PetStatusSettings();s.x=270;s.y=-160
    if F.petStatusWindow then F.petStatusWindow:ClearAllPoints(); F.petStatusWindow:SetPoint('CENTER',UIParent,'CENTER',s.x,s.y) end
end
function F.UpdatePetStatusWindow()
    if not F.db then return end
    local s=F.PetStatusSettings()
    if InCombatLockdown() then
        if F.petStatusWindow and F.petStatusWindow:IsShown() then
            F.petStatusWindow.details:SetText('Combat: updates paused until combat ends')
            F.petStatusWindow.health:Hide();F.petStatusWindow.focus:Hide()
        end
        return
    end
    local _,class=query(UnitClass,'player')
    if class~='HUNTER' or not s.enabled then if F.petStatusWindow then F.petStatusWindow:Hide() end;return end
    if not F.petStatusWindow then
        local p=CreateFrame('Frame','HunterToolsClassicPetStatus',UIParent,'BackdropTemplate');F.petStatusWindow=p
        p:SetSize(310,300);p:SetPoint('CENTER',UIParent,'CENTER',s.x,s.y)
        p:SetMovable(true);p:EnableMouse(true);p:SetClampedToScreen(true);p:RegisterForDrag('LeftButton')
        p:SetBackdrop({bgFile='Interface\\DialogFrame\\UI-DialogBox-Background',edgeFile='Interface\\Tooltips\\UI-Tooltip-Border',edgeSize=12})
        p.portrait=p:CreateTexture(nil,'ARTWORK');p.portrait:SetSize(40,40);p.portrait:SetPoint('TOPLEFT',12,-12)
        p.name=p:CreateFontString(nil,'OVERLAY','GameFontNormal');p.name:SetPoint('TOPLEFT',62,-17);p.name:SetWidth(235);p.name:SetJustifyH('LEFT');p.name:SetWordWrap(false)
        p.header=p:CreateFontString(nil,'OVERLAY','GameFontHighlightSmall');p.header:SetPoint('TOPLEFT',62,-35);p.header:SetText('Right-click for settings')
        local function bar(color)
            local b=CreateFrame('StatusBar',nil,p);b:SetHeight(18);b:SetWidth(286);b:SetStatusBarTexture('Interface\\TargetingFrame\\UI-StatusBar');b:SetStatusBarColor(unpack(color))
            local bg=b:CreateTexture(nil,'BACKGROUND');bg:SetAllPoints();bg:SetColorTexture(0.1,0.1,0.1,0.8)
            b.label=b:CreateFontString(nil,'OVERLAY','GameFontHighlightSmall');b.label:SetPoint('CENTER');return b
        end
        p.health=bar({0.2,0.75,0.25});p.focus=bar({0.9,0.5,0.15})
        p.details=p:CreateFontString(nil,'OVERLAY','GameFontHighlightSmall');p.details:SetWidth(286);p.details:SetJustifyH('LEFT');p.details:SetSpacing(4)
        p:SetScript('OnDragStart',function() if IsShiftKeyDown() and not InCombatLockdown() and not F.PetStatusSettings().locked then p:StartMoving() end end)
        p:SetScript('OnDragStop',function()
            p:StopMovingOrSizing();if InCombatLockdown() then return end
            local x,y=p:GetCenter();local px,py=UIParent:GetCenter();local settings=F.PetStatusSettings();settings.x=x-px;settings.y=y-py
        end)
        p:SetScript('OnMouseUp',function(_,button) if button=='RightButton' then F.OpenConfig() end end)
        p:SetScript('OnEnter',function()
            if not F.PetStatusSettings().tooltipEnabled then return end
            GameTooltip:SetOwner(p,'ANCHOR_RIGHT');GameTooltip:SetText('HunterTools Classic')
            F.AddPetStatusTip(GameTooltip,F.PetStatusData());GameTooltip:Show()
        end)
        p:SetScript('OnLeave',function() GameTooltip:Hide() end)
        p:SetScript('OnHide',function() GameTooltip:Hide() end)
    end
    local p=F.petStatusWindow;local d=F.PetStatusData();p.name:SetText(d.name)
    if not d.missing and SetPortraitTexture then
        if not p.portraitReady or p.portraitGUID~=d.guid then
            SetPortraitTexture(p.portrait,'pet');p.portraitGUID=d.guid;p.portraitReady=true
        end
        p.portrait:Show()
    else p.portrait:Hide();p.portraitReady=nil end
    local y=62
    for _,spec in ipairs({{p.health,'health',d.hp,d.maxHP},{p.focus,'focus',d.focusValue,d.maxFocus}}) do
        local b,key,current,maximum=spec[1],spec[2],spec[3],spec[4]
        if s.windowFields[key] and not d.missing then
            b:ClearAllPoints();b:SetPoint('TOPLEFT',12,-y);b:SetMinMaxValues(0,maximum or 1);b:SetValue(current or 0);b.label:SetText(labels[key]..': '..(d[key] or 'Unavailable'));b:Show();y=y+23
        else b:Hide() end
    end
    local fields={};for k,v in pairs(s.windowFields) do fields[k]=v end;fields.health=false;fields.focus=false
    local lines={}
    for _,line in ipairs(F.PetStatusLines(d,fields)) do
        local label,value=line[1],line[2]
        if label==labels.abilities then
            label='Abilities'
            -- Commands and stances remain in the full mouseover details.
            local entries={}
            for entry in value:gmatch('[^;]+') do
                if not entry:find('(Pet Command)',1,true) and not entry:find('(Pet Stance)',1,true) then
                    entries[#entries+1]=entry:match('^%s*(.-)%s*$')
                end
            end
            if #entries>0 then value=table.concat(entries,', ')
            elseif value:find('(Pet ',1,true) then value='No combat abilities listed' end
        end
        lines[#lines+1]='|cffc9b77d'..label..':|r '..value
    end
    p.details:ClearAllPoints();p.details:SetPoint('TOPLEFT',12,-y);p.details:SetText(table.concat(lines,'\n'))
    p:SetHeight(math.max(78,y+p.details:GetStringHeight()+14));p:Show()
end
