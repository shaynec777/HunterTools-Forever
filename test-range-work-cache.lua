local F={db={}}
assert(loadfile('HunterTools/Range.lua'))('test',F)
local now,combat=100,false
GetTime=function() return now end;InCombatLockdown=function() return combat end
local metadata,known,rangeCalls,builds=0,0,0,0
local s={enabled=true,info=true,food=true}
F.AnimalSettings=function() return {target=s} end
F.TargetPetDetails=function() builds=builds+1;return 'details '..builds end
assert(F.RangeTargetDetails('one')=='details 1')
now=100.5;assert(F.RangeTargetDetails('one')=='details 1' and builds==1)
now=102;assert(F.RangeTargetDetails('one')=='details 2')
assert(F.RangeTargetDetails('two')=='details 3','target changes refresh immediately')
s.food=false;assert(F.RangeTargetDetails('two')=='details 4','setting changes refresh immediately')
combat=true;assert(F.RangeTargetDetails('two')==nil and builds==4)
combat=false;assert(F.RangeTargetDetails('two')=='details 5','combat entry hides details; exit refreshes')
F.InvalidateRangeData('UNIT_AURA','target');assert(F.RangeTargetDetails('two')=='details 6')
F.InvalidateRangeData('UNIT_AURA','nameplate1');assert(F.RangeTargetDetails('two')=='details 6')
for _,event in ipairs({'BAG_UPDATE_DELAYED','GET_ITEM_INFO_RECEIVED','PLAYER_TARGET_CHANGED','SPELLS_CHANGED','PET_BAR_UPDATE','PLAYER_ENTERING_WORLD'}) do
 local before=builds;F.InvalidateRangeData(event);F.RangeTargetDetails('two');assert(builds==before+1,event)
end
F.InvalidateRangeData('UNIT_SPELLCAST_SUCCEEDED','player');local before=builds;F.RangeTargetDetails('two');assert(builds==before+1)
-- nil results are cached too; missing stable identity is never cached.
F.TargetPetDetails=function() builds=builds+1 end
F.InvalidateRangeData();F.RangeTargetDetails('one');before=builds;F.RangeTargetDetails('one');assert(builds==before)
F.RangeTargetDetails(nil);assert(builds==before+1)
C_Spell={GetSpellInfo=function() metadata=metadata+1;return {minRange=8,maxRange=35} end,
 IsSpellInRange=function(_,unit) rangeCalls=rangeCalls+1;if unit=='pet' then return false end;return true end}
C_SpellBook={IsSpellKnown=function(id) known=known+1;return id==136 end}
UnitExists=function() return true end;UnitCanAttack=function() return true end
UnitIsDeadOrGhost=function() return false end
local info=F.RangeSpellInfo();assert(F.RangeSpellInfo()==info and metadata==1)
F.InvalidateRangeData('UNIT_AURA','player');F.RangeSpellInfo();assert(metadata==2)
now=now+5;F.RangeSpellInfo();assert(metadata==3)
assert(F.PetHealRangeWarning());local learned=known;local checks=rangeCalls
now=now+0.5;assert(F.PetHealRangeWarning() and known==learned and rangeCalls==checks+1)
combat=true;assert(F.PetHealRangeWarning() and known==learned,'combat keeps live heal checks without spell discovery')
combat=false;F.InvalidateRangeData('SPELLS_CHANGED');F.PetHealRangeWarning();assert(known>learned)
learned=known;now=now+5;F.PetHealRangeWarning();assert(known>learned,'missed spell events recover in five seconds')
checks=rangeCalls;F.TargetRangeStatus();F.TargetRangeStatus();assert(rangeCalls==checks+2,'attack checks remain live')
print('PASS: target detail cache identity/settings/combat/events/expiry, spell metadata cache and live attack/heal checks')
