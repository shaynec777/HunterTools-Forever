local frames={}
local function widget()
 local w={scripts={},registered={},shown=false}
 setmetatable(w,{__index=function(_,key) if key=='CreateTexture' then return widget elseif key:match('^[A-Z]') then return function() end end end})
 function w:SetScript(k,fn) self.scripts[k]=fn end
 function w:RegisterEvent(e) self.registered[e]=true end
 function w:UnregisterAllEvents() self.registered={} end
 function w:Show() self.shown=true end
 function w:Hide() self.shown=false end
 function w:SetPoint(...) self.point={...} end
 frames[#frames+1]=w;return w
end
CreateFrame=widget;UIParent={}
local combat=false;InCombatLockdown=function() return combat end
local secret={};issecretvalue=function(v) return v==secret end
local plate={token='nameplate1',forbidden=false,shown=true}
function plate:GetUnit() return self.token end
function plate:IsForbidden() return self.forbidden end
function plate:IsShown() return self.shown end
local visible={};local ids={nameplate1=1285,nameplate2=9999}
UnitGUID=function(unit) local id=ids[unit];if id==secret then return secret end;return id and ('Creature-0-1-0-0-'..id..'-0001') end
C_NamePlate={GetNamePlates=function() return visible end,GetNamePlateForUnit=function(unit) return unit==plate.token and plate end}
local iconIndex;SetRaidTargetIconTexture=function(_,index) iconIndex=index end
SetRaidTarget=function() error('must never change shared raid targets') end
local F={}
F.SelectAmmoVendor=function(v) if combat then return end;F.ammoVendorDestination=v;return true end
F.ClearAmmoVendorMarker=function() F.ammoVendorDestination=nil end
assert(loadfile('HunterTools/AmmoVendorWorldMarker.lua'))('test',F)
if F.SetupAmmoVendorMarkButton then assert(loadfile('test-secure-vendor-mark.lua'))();return end
local events=frames[1];assert(not next(events.registered) and not events.scripts.OnUpdate)
if not F.RefreshAmmoVendorWorldMarker then
    -- Forever's corrected semantics: one native attempt on Mark only.
    local inRange,raid,leader,nativeIndex,attempts=false,false,false,0,0
    local denied=false;local markedUnit
    CheckInteractDistance=function() return inRange end
    CanBeRaidTarget=function() return true end
    IsInRaid=function() return raid end;UnitIsGroupLeader=function() return leader end
    UnitIsGroupAssistant=function() return false end
    GetRaidTargetIndex=function() return nativeIndex>0 and nativeIndex or nil end
    SetRaidTarget=function(unit,index)
        attempts=attempts+1;markedUnit=unit;assert(index==7)
        if denied then error('native marking denied') end
        nativeIndex=index
    end
    visible={plate};F.SelectAmmoVendor({id=1285});assert(attempts==0 and not F.ammoVendorWorldPin)
    inRange=true
    for _,event in ipairs({'NAME_PLATE_UNIT_ADDED','PLAYER_TARGET_CHANGED','UPDATE_MOUSEOVER_UNIT','RAID_TARGET_UPDATE','PLAYER_REGEN_ENABLED'}) do events.scripts.OnEvent(nil,event,'nameplate1') end
    assert(attempts==0,'approaching or later unit events must never apply X')
    F.SelectAmmoVendor({id=1285});assert(attempts==1 and nativeIndex==7 and markedUnit=='nameplate1')
    assert(not next(events.registered) and not events.scripts.OnUpdate)
    F.ClearAmmoVendorMarker();assert(nativeIndex==7,'clearing navigation must not clear shared raid marks')
    nativeIndex=0;denied=true;F.SelectAmmoVendor({id=1285})
    assert(attempts==2 and F.ammoVendorWorldPin.shown,'blocked native mark uses immediate visible/in-range fallback')
    events.scripts.OnEvent(nil,'NAME_PLATE_UNIT_REMOVED','nameplate1');assert(not F.ammoVendorWorldPin.shown)
    events.scripts.OnEvent(nil,'NAME_PLATE_UNIT_ADDED','nameplate1');assert(attempts==2 and not F.ammoVendorWorldPin.shown)
    raid=true;F.SelectAmmoVendor({id=1285});assert(attempts==2 and F.ammoVendorWorldPin.shown,'raid without role permission must not call native setter')
    F.ClearAmmoVendorMarker();visible={};denied=false;raid=false;ids.target=9999;ids.mouseover=1285
    F.SelectAmmoVendor({id=1285});assert(attempts==3 and markedUnit=='mouseover','matching mouseover works without nameplates')
    nativeIndex=0;ids.mouseover=9999;F.SelectAmmoVendor({id=1285});assert(attempts==3,'wrong NPC never marked')
    ids.target=1285;CheckInteractDistance=function() return secret end
    F.SelectAmmoVendor({id=1285});assert(attempts==3,'unknown range never accepted')
    CheckInteractDistance=function() return true end;combat=true;F.SelectAmmoVendor({id=1285});assert(attempts==3)
    combat=false;F.ClearAmmoVendorMarker();assert(not next(events.registered) and not events.scripts.OnUpdate)
    F.Print=function() end
    nativeIndex=0;F.SelectAmmoVendor({id=1285});assert(nativeIndex==7)
    local clear=widget();clear.attrs={}
    function clear:SetAttribute(k,v) self.attrs[k]=v end
    F.SetupAmmoVendorClearButton(clear)
    clear.scripts.PreClick(clear);assert(clear.attrs.macrotext=='/tm [nocombat] 0')
    ids.target=9999;visible={plate}
    clear.scripts.PreClick(clear)
    assert(clear.attrs.macrotext=='/tm [@nameplate1,exists,nocombat] 0','clear exact vendor without changing unrelated target')
    assert(not clear.attrs.macrotext:find('targetexact',1,true))
    visible={};clear.scripts.PreClick(clear);assert(not clear.attrs.macrotext,'no visible exact GUID means no raid clear')
    clear.scripts.PostClick(clear);assert(not F.ammoVendorDestination and nativeIndex==7)
    ids.target=1285;nativeIndex=8;clear.scripts.PreClick(clear);assert(not clear.attrs.macrotext,'preserve replacement icon')
    nativeIndex=7;clear.scripts.PreClick(clear);assert(clear.attrs.macrotext)
    nativeIndex=0;clear.scripts.PostClick(clear);assert(not clear.attrs.macrotext)
    nativeIndex=7;clear.scripts.PreClick(clear);assert(not clear.attrs.macrotext,'forget confirmed cleared GUID')
    print('PASS: one-shot native X, exact NPC/range, target/mouseover/nameplate, raid permissions, immediate fallback, no later retries, independent navigation')
    return
end
F.SelectAmmoVendor({id=1285});assert(events.registered.NAME_PLATE_UNIT_ADDED and not F.ammoVendorWorldPin)
visible={plate};events.scripts.OnEvent(nil,'NAME_PLATE_UNIT_ADDED','nameplate1')
assert(F.ammoVendorWorldPin.shown and F.ammoVendorWorldUnit=='nameplate1' and iconIndex==7)
events.scripts.OnEvent(nil,'NAME_PLATE_UNIT_REMOVED','nameplate2');assert(F.ammoVendorWorldPin.shown)
events.scripts.OnEvent(nil,'NAME_PLATE_UNIT_REMOVED','nameplate1');assert(not F.ammoVendorWorldPin.shown)
F.SelectAmmoVendor({id=1285});assert(F.ammoVendorWorldPin.shown,'already-visible vendor must be found by native GetUnit')
ids.nameplate1=9999;events.scripts.OnEvent(nil,'NAME_PLATE_UNIT_ADDED','nameplate1');assert(not F.ammoVendorWorldPin.shown,'recycled nameplate must not keep an X on another NPC')
ids.nameplate1=1285;F.RefreshAmmoVendorWorldMarker()
combat=true;events.scripts.OnEvent(nil,'PLAYER_REGEN_DISABLED');assert(not F.ammoVendorWorldPin.shown)
events.scripts.OnEvent(nil,'NAME_PLATE_UNIT_ADDED','nameplate1');assert(not F.ammoVendorWorldPin.shown)
combat=false;events.scripts.OnEvent(nil,'PLAYER_REGEN_ENABLED');assert(F.ammoVendorWorldPin.shown)
F.SelectAmmoVendor({id=9999});assert(not F.ammoVendorWorldPin.shown,'changing destination hides old X')
F.SelectAmmoVendor({id=1285});F.ClearAmmoVendorMarker();assert(not next(events.registered) and not F.ammoVendorWorldPin.shown)
plate.forbidden=true;F.SelectAmmoVendor({id=1285});assert(not F.ammoVendorWorldPin.shown)
plate.forbidden=false;ids.nameplate1=secret;F.RefreshAmmoVendorWorldMarker();assert(not F.ammoVendorWorldPin.shown)
ids.nameplate1=1285;plate.shown=false;F.RefreshAmmoVendorWorldMarker();assert(not F.ammoVendorWorldPin.shown)
plate.shown=true;C_NamePlate=nil;F.RefreshAmmoVendorWorldMarker();assert(not F.ammoVendorWorldPin.shown)
F.ClearAmmoVendorMarker();assert(not events.scripts.OnUpdate and not next(events.registered))
print('PASS: nearby exact-NPC X, existing/new/recycled plates, destination changes, combat, forbidden/secret/hidden/unavailable plates, clear and idle lifecycle')
