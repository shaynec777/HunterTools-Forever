local now,combat=100,false
GetTime=function() return now end;InCombatLockdown=function() return combat end
-- Real ammo scanning: cached upgrades reuse the reminder's counts, not another bag walk.
local F={db={ammo={selected={[2512]=true}}},IsPublic=function(v) return type(v)~='string' end}
C_Item={};local count,scans=100,0
C_Item.GetItemCount=function() return count end
NUM_TOTAL_EQUIPPED_BAG_SLOTS=0
C_Container={GetContainerNumSlots=function() scans=scans+1;return 0 end,GetContainerItemInfo=function() end}
assert(loadfile('HunterTools/Ammo.lua'))('test',F)
assert(F.EnsureAmmoScan() and scans==1 and F.ammoCounts[2512]==100)
now=105;assert(F.EnsureAmmoScan() and scans==1)
count=80;F.ammoDirty=true;assert(F.EnsureAmmoScan() and scans==2 and F.ammoCounts[2512]==80)
now=136;assert(F.EnsureAmmoScan() and scans==3,'30-second fallback rescans without an event')
F.ammoEntryReadyAt=now+10;assert(not F.EnsureAmmoScan() and scans==3,'zoning never treats cached counts as ready')
F.ammoEntryReadyAt=nil;combat=true;assert(not F.EnsureAmmoScan() and scans==3);combat=false
-- Range checks continue every call; unchanged render content does not rewrite layout.
local writes,portraits,checks=0,0,0
local function widget()
 local w={}
 setmetatable(w,{__index=function(_,key) if key:match('^[A-Z]') then return function() writes=writes+1 end end end})
 function w:GetStringHeight() return 14 end
 return w
end
local R={db={range={enabled=true}},rangeWindow=widget()}
for _,key in ipairs({'targetName','portrait','petHeal','petDetails','distance','text'}) do R.rangeWindow[key]=widget() end
local guid,name='target-one','First target';local details,heal=nil,nil;local range='In range'
UnitClass=function() return 'Hunter','HUNTER' end;UnitExists=function() return true end
UnitName=function() return name end;UnitGUID=function() return guid end
SetPortraitTexture=function() portraits=portraits+1 end
assert(loadfile('HunterTools/Range.lua'))('test',R)
R.TargetPetDetails=function() return details end;R.PetHealRangeWarning=function() return heal end
R.TargetRangeStatus=function() checks=checks+1;return range,1,1,1 end
R.TargetDistanceEstimate=function() return '20 yards' end
R.UpdateRangeWindow();local firstWrites=writes
R.UpdateRangeWindow();assert(checks==2 and portraits==1 and writes-firstWrites==1,'unchanged update only shows the frame; no redraw/layout writes')
range='Too close';local prior=writes;R.UpdateRangeWindow();assert(checks==3 and writes>prior)
guid='target-two';name='Second target';R.UpdateRangeWindow();assert(portraits==2)
heal='Pet is out of range';details='Bear';prior=writes;R.UpdateRangeWindow();assert(writes>prior)
-- Tracking caches learned metadata, while reading active flags every time.
local T={};local knownCalls=0;local active=true
F=T
C_Minimap={GetNumTrackingTypes=function() return 1 end,GetTrackingInfo=function() return {spellID=1494,name='Track Beasts',active=active,texture=123} end}
C_SpellBook={IsSpellKnown=function(id) knownCalls=knownCalls+1;return id==1494 end}
C_Spell={GetSpellName=function(id) if id==1494 then return 'Track Beasts' end end}
assert(loadfile('HunterTools/TrackingButton.lua'))('test',T)
assert(T.TrackingState().active.id==1494);local baseline=knownCalls
active=false;assert(T.TrackingState().active==nil and knownCalls==baseline)
T.trackingChoicesCache=nil;T.TrackingState();assert(knownCalls>baseline,'spell invalidation refreshes known choices')
baseline=knownCalls;now=now+5;T.TrackingState();assert(knownCalls>baseline,'metadata cache has a five-second fallback')
-- Aspects cache spell discovery but retain live aura ownership/cancellation reads.
local A={db={}};local known=13165;local aura=true;knownCalls=0
F=A;C_SpellBook={}
C_SpellBook.IsSpellKnown=function(id) knownCalls=knownCalls+1;return id==known end
C_Spell={GetSpellName=function(id) return 'Aspect '..id end}
C_UnitAuras={GetAuraDataBySpellName=function(_,name) if aura and name=='Aspect '..known then return {sourceUnit='player',auraInstanceID=1} end end}
assert(loadfile('HunterTools/AspectReminder.lua'))('test',A)
assert(A.AspectState().active.id==13165);baseline=knownCalls
aura=false;assert(A.AspectState().active==nil and knownCalls==baseline)
known=14318;A.aspectChoicesCache=nil;assert(A.AspectState().choices[1].id==14318 and knownCalls>baseline)
known=13163;now=now+5;assert(A.AspectState().choices[1].id==13163,'missed spell event is recovered by fallback')
combat=true;assert(A.AspectState()==nil and T.TrackingState()==nil)
print('PASS: ammo reuse/invalidation/fallback, live range checks with no unchanged redraw, target/layout changes, cached choices with live active states and spell invalidation')
