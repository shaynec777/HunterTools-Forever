local _,F=...
local function safe(v) return not issecretvalue or not issecretvalue(v) end
function F.RangeSettings()
    if type(F.db.range)~='table' then F.db.range={} end
    local s=F.db.range
    if type(s.measuredDistance)~='boolean' then s.measuredDistance=false end
    if type(s.enabled)~='boolean' then s.enabled=true end
    for _,key in ipairs({'showPetAbilities','showPetDiet'}) do if type(s[key])~='boolean' then s[key]=true end end
    if type(s.showPetHealRange)~='boolean' then s.showPetHealRange=true end
    for key,default in pairs({x=0,y=-230}) do
        if type(s[key])~='number' or s[key]~=s[key] or math.abs(s[key])>10000 then s[key]=default end
    end
    return s
end
-- No timing clock, protected-call wrapper or per-call labels while profiling is off.
local function timed(label,fn,...)
    if F.IsPerformanceTestActive and F.IsPerformanceTestActive() then return F.PerformanceCallback(label,fn,...) end
    return fn(...)
end
local function ui(label,object,method,...)
    if F.IsPerformanceTestActive and F.IsPerformanceTestActive() then
        return F.PerformanceCallback('range native: '..label,object[method],object,...)
    end
    return object[method](object,...)
end
local function query(fn,...)
    if type(fn)~='function' then return end
    local ok,value
    if F.IsPerformanceTestActive and F.IsPerformanceTestActive() then
        local label='query'
        if fn==UnitGUID then label='UnitGUID'
        elseif fn==GetTime then label='GetTime'
        elseif fn==UnitExists then label='UnitExists'
        elseif fn==UnitCanAttack then label='UnitCanAttack'
        elseif fn==UnitIsDeadOrGhost then label='UnitIsDeadOrGhost'
        elseif fn==CheckInteractDistance then label='CheckInteractDistance'
        elseif C_Spell and fn==C_Spell.GetSpellInfo then label='GetSpellInfo'
        elseif C_Spell and fn==C_Spell.IsSpellInRange then label='IsSpellInRange'
        elseif C_SpellBook and fn==C_SpellBook.IsSpellKnown then label='IsSpellKnown'
        elseif fn==debugprofilestop then label='debugprofilestop' end
        ok,value=pcall(F.PerformanceCallback,'range native: '..label,fn,...)
    else ok,value=pcall(fn,...) end
    if ok and safe(value) then return value end
end
-- Cache learned/static spell data, never the live attack/heal range result.
function F.RangeSpellInfo()
    local now=query(GetTime)
    local cache=F.rangeSpellInfoCache
    if type(now)=='number' and cache and now>=cache.at and now-cache.at<5 then return cache.info end
    local info=query(C_Spell and C_Spell.GetSpellInfo,75)
    if type(now)=='number' then F.rangeSpellInfoCache={at=now,info=info} end
    return info
end
function F.InvalidateRangeData(event,unit)
    if not event or event=='PLAYER_ENTERING_WORLD' or event=='SPELLS_CHANGED'
        or (event=='UNIT_AURA' and unit=='player') then
        F.rangeSpellInfoCache=nil;F.mendPetRangeAt=nil
    end
    if not event or not event:match('^UNIT_') or unit=='target'
        or (event=='UNIT_SPELLCAST_SUCCEEDED' and unit=='player') then F.targetRangeDetailsCache=nil end
end
function F.RangeTargetDetails(guid)
    if not F.TargetPetDetails then return end
    if InCombatLockdown() then F.targetRangeDetailsCache=nil;return end
    local now=query(GetTime)
    if type(guid)~='string' or type(now)~='number' or not F.AnimalSettings then return F.TargetPetDetails() end
    local settings=F.AnimalSettings().target
    local signature={}
    for _,key in ipairs({'enabled','info','role','abilities','diet','food','location','abilityReference',
        'learned','familyTraining','dietReference','beastReference','baseline'}) do
        signature[#signature+1]=key..'='..tostring(settings[key])
    end
    signature=table.concat(signature,';')
    local c=F.targetRangeDetailsCache
    if c and c.guid==guid and c.settings==signature and now>=c.at and now-c.at<2 then return c.text end
    local text=F.TargetPetDetails()
    F.targetRangeDetailsCache={guid=guid,settings=signature,at=now,text=text}
    return text
end
local function interactRange(index)
    -- Combat restrictions apply to friendly/non-attackable units. A public,
    -- living hostile target can still supply native interaction-range evidence.
    if InCombatLockdown and InCombatLockdown() then
        if query(UnitCanAttack,'player','target')~=true or query(UnitIsDeadOrGhost,'target')~=false then return end
    end
    return query(CheckInteractDistance,'target',index)
end
-- Actual Forever hunter Mend Pet ranks; native range checks include applicable modifiers.
local mendRanks={136,3111,3661,3662,13542,13543,13544}
function F.PetHealRangeWarning(ignoreDisplaySetting)
    if not ignoreDisplaySetting and not F.RangeSettings().showPetHealRange then return end
    if query(UnitExists,'pet')~=true then return end
    local dead=query(UnitIsDeadOrGhost,'pet')
    if dead~=false then return end
    local now=query(GetTime)
    if not InCombatLockdown() and (type(now)~='number' or not F.mendPetRangeAt or now<F.mendPetRangeAt or now-F.mendPetRangeAt>=5) then
        F.mendPetRangeAt=now
        F.mendPetRangeSpell=nil
        for _,id in ipairs(mendRanks) do
            if query(C_SpellBook and C_SpellBook.IsSpellKnown,id)==true then F.mendPetRangeSpell=id end
        end
    end
    local id=F.mendPetRangeSpell
    if not id then return end
    local inRange
    if C_Spell and C_Spell.IsSpellInRange then inRange=query(C_Spell.IsSpellInRange,id,'pet')
    elseif IsSpellInRange then
        local name=query(C_Spell and C_Spell.GetSpellName,id)
        if type(name)=='string' then inRange=query(IsSpellInRange,name,'pet') end
    end
    if inRange==false or inRange==0 then return 'Pet too far to heal (Mend Pet)' end
    -- Missing/secret range results do not establish that the pet is too far away.
end
function F.TargetRangeStatus()
    F.rangeNonEnemy=false
    if not timed('range native: UnitExists',UnitExists,'target') then return 'No target',0.7,0.7,0.7 end
    local enemy=timed('range native: UnitCanAttack',UnitCanAttack,'player','target')
    local dead=timed('range native: UnitIsDeadOrGhost',UnitIsDeadOrGhost,'target')
    if not safe(enemy) or not safe(dead) then return 'Range unavailable',0.7,0.7,0.7 end
    F.rangeNonEnemy=not enemy or dead
    local ranged
    if C_Spell and C_Spell.IsSpellInRange then ranged=query(C_Spell.IsSpellInRange,75,'target')
    elseif IsSpellInRange and C_Spell and C_Spell.GetSpellName then ranged=query(IsSpellInRange,query(C_Spell.GetSpellName,75),'target') end
    if not safe(ranged) then return 'Range unavailable',0.7,0.7,0.7 end
    if ranged==true or ranged==1 then return 'In range',0.2,1,0.3 end
    if ranged~=false and ranged~=0 then
        if F.rangeNonEnemy then
            local low,high=F.NonEnemyDistanceBand()
            local info=F.RangeSpellInfo()
            local minimum=info and info.minRange
            local maximum=info and info.maxRange
            if safe(minimum) and safe(maximum) and type(minimum)=='number' and type(maximum)=='number' then
                if high and high<minimum then return 'Too close',1,0.3,0.15 end
                if low and low>maximum then return 'Too far',1,0.8,0.2 end
                if low and high and low>=minimum and high<=maximum then return 'In range',0.2,1,0.3 end
            end
            return 'Range uncertain',0.7,0.7,0.7
        end
        return 'Range unavailable',0.7,0.7,0.7
    end
    -- Follow-distance is inside Auto Shot's normal maximum range, so a failed
    -- ranged check inside that distance means the target is too close.
    local info=F.RangeSpellInfo()
    local maximum=info and info.maxRange
    local near=interactRange(4)
    if not safe(near) or not safe(maximum) or type(maximum)~='number' or maximum<28 then
        return 'Range unavailable',0.7,0.7,0.7
    end
    if near==true or near==1 then return 'Too close',1,0.3,0.15 end
    if near==false or near==0 then return 'Too far',1,0.8,0.2 end
    return 'Range unavailable',0.7,0.7,0.7
end
function F.NonEnemyDistanceBand()
    local close=interactRange(3)
    local near=interactRange(4)
    if not safe(close) or not safe(near) then return nil end
    if close==true or close==1 then return 0,10 end
    if near==true or near==1 then return (close==false or close==0) and 10 or 0,28 end
    if near==false or near==0 then return 28,nil end
end
local function finiteNumber(value)
    return safe(value) and type(value)=='number' and value==value and math.abs(value)<math.huge
end
-- Bounded per-query diagnostics are character data; no target names/positions are saved.
local function distanceQuery(label,fn,now,...)
    local runtime=F.distanceRuntime
    if now<(runtime.slowUntil[label] or 0) then return nil end
    local start=query(debugprofilestop)
    local ok,a,b,c,d=pcall(timed,'range native: '..label,fn,...)
    local finish=query(debugprofilestop)
    local cost=finiteNumber(start) and finiteNumber(finish) and math.max(0,finish-start) or 0
    local logs=F.db.distanceQueryDiagnostics
    if type(logs)~='table' or logs.version~=1 then logs={version=1};F.db.distanceQueryDiagnostics=logs end
    local row=logs[label]
    if type(row)~='table' then row={count=0,total=0,max=0,errors=0,unavailable=0,slow=0};logs[label]=row end
    row.count=row.count+1;row.total=row.total+cost;row.max=math.max(row.max,cost)
    if not ok then row.errors=row.errors+1 end
    if cost>=2 then
        row.slow=row.slow+1;runtime.slowUntil[label]=now+60
        return nil,nil,nil,nil,true
    end
    if ok then return a,b,c,d end
end
local function unavailable(label)
    local row=F.db.distanceQueryDiagnostics and F.db.distanceQueryDiagnostics[label]
    if row then row.unavailable=row.unavailable+1 end
end
function F.MeasuredTargetDistance()
    if not F.RangeSettings().measuredDistance or query(UnitExists,'target')~=true then
        F.distanceRuntime=nil;return
    end
    local now=query(GetTime)
    if not finiteNumber(now) then return end
    local guid=query(UnitGUID,'target')
    -- Without a stable public identity, cached measurements cannot safely be reused.
    if type(guid)~='string' then return end
    local r=F.distanceRuntime
    if not r or now<r.at then r={at=now,slowUntil={}};F.distanceRuntime=r end
    if r.guid~=guid then r.guid=guid;r.value=nil;r.nextAt=nil;r.squaredAt=nil;r.positionAt=nil end
    if r.nextAt and now<r.nextAt then return r.value end
    r.at=now;r.nextAt=now+1;r.value=nil
    if type(UnitDistanceSquared)=='function' and now>=(r.squaredAt or 0) then
        local squared,checked,_,__,slow=distanceQuery('UnitDistanceSquared:target',UnitDistanceSquared,now,'target')
        if slow then return end
        if safe(checked) and checked==true and finiteNumber(squared) and squared>=0 then
            r.value=math.sqrt(squared);return r.value
        end
        unavailable('UnitDistanceSquared:target');r.squaredAt=now+5
    end
    if type(UnitPosition)~='function' or now<(r.positionAt or 0) then return end
    local function position(unit)
        local x,y,z,map,slow=distanceQuery('UnitPosition:'..unit,UnitPosition,now,unit)
        if finiteNumber(x) and finiteNumber(y) and finiteNumber(z) and finiteNumber(map)
            and not (x==0 and y==0 and z==0) then return x,y,z,map end
        if not slow then unavailable('UnitPosition:'..unit) end
    end
    -- Avoid querying player coordinates when the target exposes no coordinates.
    local tx,ty,tz,tm=position('target')
    if not tx then r.positionAt=now+5;return end
    local px,py,pz,pm=position('player')
    if px and pm==tm then
        local squared=(px-tx)^2+(py-ty)^2+(pz-tz)^2
        if finiteNumber(squared) then r.value=math.sqrt(squared);return r.value end
    end
    r.positionAt=now+5
end
function F.DistanceQueryReport()
    local logs=F.db.distanceQueryDiagnostics
    F.Print('Distance query timings (cumulative; milliseconds). Slow queries pause for 60 seconds.')
    for _,label in ipairs({'UnitDistanceSquared:target','UnitPosition:target','UnitPosition:player'}) do
        local r=type(logs)=='table' and logs[label]
        if type(r)=='table' then F.Print(('%s: %d calls; %.3f ms total; %.3f ms max; %d unavailable; %d errors; %d slow'):format(label,r.count,r.total,r.max,r.unavailable,r.errors,r.slow)) end
    end
end
function F.TargetDistanceEstimate(status)
    local measured=F.MeasuredTargetDistance()
    if measured then return ('Measured: %.1f yd'):format(measured) end
    if F.rangeNonEnemy and status~='No target' and status~='Range unavailable' then
        local low,high=F.NonEnemyDistanceBand()
        if low and high then return ('Est. %g-%g yd'):format(low,high) end
        if low then return ('Est. > %g yd'):format(low) end
        return 'Distance unavailable'
    end
    if status~='In range' and status~='Too close' and status~='Too far' then
        return 'Distance unavailable'
    end
    local info=F.RangeSpellInfo()
    if not safe(info) or type(info)~='table' then return 'Distance unavailable' end
    local minimum,maximum=info.minRange,info.maxRange
    if not safe(minimum) or not safe(maximum) or type(minimum)~='number'
        or type(maximum)~='number' or minimum<0 or maximum<=minimum then
        return 'Distance unavailable'
    end
    if status=='Too close' then
        if minimum==0 then return 'Distance unavailable' end
        return ('Est. < %g yd'):format(minimum)
    elseif status=='Too far' then
        return ('Est. > %g yd'):format(maximum)
    end
    return ('Est. %g-%g yd'):format(minimum,maximum)
end

local function renderPortrait(p,cache,changed,exists,guid,name,now)
    local portraitKey=exists and (guid or name) or false
    local portraitChanged=changed('portrait',portraitKey)
    if exists and SetPortraitTexture then
        if portraitChanged or (type(now)=='number' and (not cache.portraitAt or now<cache.portraitAt or now-cache.portraitAt>=5)) then
            timed('range native: SetPortraitTexture',SetPortraitTexture,p.portrait,'target');cache.portraitAt=type(now)=='number' and now or nil
        end
        if portraitChanged then ui('portrait.Show',p.portrait,'Show') end
    elseif portraitChanged then ui('portrait.Hide',p.portrait,'Hide') end
end
local function renderDetails(p,cache,changed,details,heal)
    local healChanged=changed('heal',heal)
    if healChanged then
        ui('petHeal.SetText',p.petHeal,'SetText',heal or '');ui('petHeal.SetShown',p.petHeal,'SetShown',heal~=nil)
        cache.healSpace=heal and (ui('petHeal.GetStringHeight',p.petHeal,'GetStringHeight')+8) or 0
    end
    local detailsChanged=changed('details',details)
    if detailsChanged then
        ui('petDetails.SetText',p.petDetails,'SetText',details or '');ui('petDetails.SetShown',p.petDetails,'SetShown',details~=nil)
        cache.detailsHeight=details and ui('petDetails.GetStringHeight',p.petDetails,'GetStringHeight') or 0
    end
    if healChanged or detailsChanged then
        ui('petDetails.ClearAllPoints',p.petDetails,'ClearAllPoints');ui('petDetails.SetPoint',p.petDetails,'SetPoint','TOPLEFT',12,-96-cache.healSpace)
        ui('window.SetHeight',p,'SetHeight',(details and (110+cache.detailsHeight) or 94)+cache.healSpace)
    end
end
local function renderStatus(p,cache,changed,muted,heal,text,r,g,b,distance)
    if changed('muted',muted) then
        ui('portrait.SetDesaturated',p.portrait,'SetDesaturated',muted)
        ui('targetName.SetTextColor',p.targetName,'SetTextColor',muted and 0.7 or 1,muted and 0.7 or 0.82,muted and 0.7 or 0)
        ui('distance.SetTextColor',p.distance,'SetTextColor',muted and 0.65 or 1,muted and 0.65 or 1,muted and 0.65 or 1)
    end
    local alpha=(muted and not heal) and 0.65 or 1
    if changed('alpha',alpha) then ui('window.SetAlpha',p,'SetAlpha',alpha) end
    if changed('distance',distance) then ui('distance.SetText',p.distance,'SetText',distance) end
    if changed('text',text) then ui('status.SetText',p.text,'SetText',text) end
    local red,green,blue=muted and 0.7 or r,muted and 0.7 or g,muted and 0.7 or b
    if changed('color',table.concat({red,green,blue},':')) then ui('status.SetTextColor',p.text,'SetTextColor',red,green,blue) end
    ui('window.Show',p,'Show')
end
function F.UpdateRangeWindow()
    local s=F.RangeSettings()
    local _,class=timed('range native: UnitClass',UnitClass,'player')
    if class~='HUNTER' or not s.enabled then
        if F.rangeWindow then ui('window.Hide',F.rangeWindow,'Hide') end
        return
    end
    if not F.rangeWindow then
        if InCombatLockdown() then return end
        local p=CreateFrame('Frame','HunterToolsRange',UIParent,'BackdropTemplate'); F.rangeWindow=p
        p:SetSize(245,94); p:SetPoint('CENTER',UIParent,'CENTER',s.x,s.y)
        p:SetMovable(true); p:EnableMouse(true); p:SetClampedToScreen(true); p:RegisterForDrag('LeftButton')
        p:SetBackdrop({bgFile='Interface\\DialogFrame\\UI-DialogBox-Background',edgeFile='Interface\\Tooltips\\UI-Tooltip-Border',edgeSize=12})
        p.portrait=p:CreateTexture(nil,'ARTWORK')
        p.portrait:SetSize(42,42); p.portrait:SetPoint('TOPLEFT',10,-10)
        p.targetName=p:CreateFontString(nil,'OVERLAY','GameFontNormal')
        p.targetName:SetPoint('TOPLEFT',p,'TOPLEFT',60,-15); p.targetName:SetWidth(175)
        p.targetName:SetJustifyH('LEFT'); p.targetName:SetWordWrap(false)
        p.text=p:CreateFontString(nil,'OVERLAY','GameFontNormalLarge'); p.text:SetPoint('TOPLEFT',60,-37)
        p.distance=p:CreateFontString(nil,'OVERLAY','GameFontHighlightSmall'); p.distance:SetPoint('TOP',0,-69)
        p.petHeal=p:CreateFontString(nil,'OVERLAY','GameFontNormalLarge');p.petHeal:SetPoint('TOPLEFT',12,-91);p.petHeal:SetWidth(221);p.petHeal:SetJustifyH('LEFT');p.petHeal:SetTextColor(1,0.2,0.15)
        p.petDetails=p:CreateFontString(nil,'OVERLAY','GameFontHighlightSmall'); p.petDetails:SetPoint('TOPLEFT',12,-96); p.petDetails:SetWidth(221); p.petDetails:SetJustifyH('LEFT')
        p:SetScript('OnDragStart',function() if IsShiftKeyDown() and not InCombatLockdown() then p:StartMoving() end end)
        p:SetScript('OnDragStop',function()
            p:StopMovingOrSizing()
            local x,y=p:GetCenter(); local px,py=UIParent:GetCenter()
            s.x,s.y=x-px,y-py
        end)
        p:SetScript('OnMouseUp',function(_,button)
            if button=='RightButton' then F.OpenConfig() end
        end)
        p:SetScript('OnEnter',function()
            GameTooltip:SetOwner(p,'ANCHOR_RIGHT'); GameTooltip:SetText('Hunter range')
            GameTooltip:AddLine('Right-click: settings. Shift + left-drag to move outside combat. /ht range toggles this window.',1,1,1,true)
            GameTooltip:AddLine('Checks Auto Shot range; does not check line of sight, ammunition, or cooldowns.',0.7,0.7,0.7,true)
            GameTooltip:AddLine('Pet warning uses Mend Pet range. Line of sight and healing resources are not checked.',0.7,0.7,0.7,true);GameTooltip:Show()
        end)
        p:SetScript('OnLeave',function() GameTooltip:Hide() end)
    end
    local p=F.rangeWindow
    if type(p.renderState)~='table' then p.renderState={} end
    local cache=p.renderState
    local function changed(key,value)
        local old=cache[key]
        if not old or old.value~=value then cache[key]={value=value};return true end
        return false
    end
    local exists=timed('range native: UnitExists',UnitExists,'target')
    local name=exists and timed('range native: UnitName',UnitName,'target')
    if not safe(name) or type(name)~='string' then name=exists and 'Target' or 'No target' end
    if changed('name',name) then ui('targetName.SetText',p.targetName,'SetText',name) end
    local guid=query(UnitGUID,'target')
    local now=query(GetTime)
    timed('range render: portrait',renderPortrait,p,cache,changed,exists,guid,name,now)
    local details=F.RangeTargetDetails(guid)
    local heal=F.PetHealRangeWarning()
    timed('range render: details/layout',renderDetails,p,cache,changed,details,heal)
    local text,r,g,b=F.TargetRangeStatus()
    local muted=F.rangeNonEnemy and true or false
    local distance=F.TargetDistanceEstimate(text)
    timed('range render: status/visibility',renderStatus,p,cache,changed,muted,heal,text,r,g,b,distance)
end
