local F={db={}}
assert(loadfile('source/HunterToolsClassic/Range.lua'))('test',F)
UnitExists=function() return true end
UnitCanAttack=function() return true end
UnitIsDeadOrGhost=function() return false end
InCombatLockdown=function() return false end
F.ClassicSpell={IsSpellInRange=function() end,GetSpellName=function() return 'Auto Shot' end,
    GetSpellInfo=function() return {minRange=8,maxRange=35} end}
F.ClassicSpellBook={IsSpellKnown=function() return false end}
IsSpellInRange=function() return 0 end
CheckInteractDistance=function() end
assert(F.ClassicTargetShotRange()==false,'legacy numeric zero is out of range')
assert(F.TargetRangeStatus()=='Out of range','unavailable secondary check must not discard known range failure')
assert(F.TargetDistanceEstimate('Out of range')=='Too close or beyond shooting range')
CheckInteractDistance=function() return true end
assert(F.TargetRangeStatus()=='Too close')
CheckInteractDistance=function() return false end
assert(F.TargetRangeStatus()=='Too far')
IsSpellInRange=function() end
GetActionInfo=function(slot) if slot==4 then return 'spell',75 end end
IsActionInRange=function() return 1 end
assert(F.ClassicTargetShotRange()==true and F.TargetRangeStatus()=='In range')
IsActionInRange=function() end
F.ClassicSpellBook.IsSpellKnown=function(id) return id==1978 end
F.ClassicSpell.IsSpellInRange=function(id) if id==1978 then return false end end
assert(F.ClassicTargetShotRange()==false,'learned shot supplies fallback')
F.ClassicSpell.IsSpellInRange=function() end
assert(F.ClassicTargetShotRange()==nil and F.TargetRangeStatus()=='Range unavailable','all unanswered checks must remain unknown')
print('PASS: Classic legacy/action/learned-shot range fallbacks, numeric false, close/far vs unknown direction')

-- Never attempt the protected API in combat, even through pcall.
InCombatLockdown=function() return true end
local interactions=0
CheckInteractDistance=function() interactions=interactions+1;error('protected call attempted') end
UnitCanAttack=function() return false end
assert(F.NonEnemyDistanceBand()==nil)
assert(F.TargetRangeStatus()=='Range uncertain')
assert(F.TargetDistanceEstimate('Range uncertain')=='Distance unavailable')
UnitCanAttack=function() return true end
F.ClassicSpell.IsSpellInRange=function() return false end
assert(F.TargetRangeStatus()=='Out of range')
F.ClassicSpell.IsSpellInRange=function() return true end
assert(F.TargetRangeStatus()=='In range','public spell range still works in combat')
assert(interactions==0,'combat must not invoke CheckInteractDistance')
InCombatLockdown=function() return false end
F.ClassicSpell.IsSpellInRange=function() return false end
CheckInteractDistance=function() return true end
assert(F.TargetRangeStatus()=='Too close','interaction estimates resume after combat')
CheckInteractDistance=function() error('API unavailable') end
assert(F.TargetRangeStatus()=='Out of range' and F.NonEnemyDistanceBand()==nil)
print('PASS: protected interaction checks skipped in combat; spell checks retained; recovery and API errors handled')

-- Reproduce the live client: Auto Shot min=35/max=0 is not a valid interval.
F.ClassicSpell.GetSpellInfo=function(id)
 if id==75 then return {minRange=35,maxRange=0} end
 if id==3044 then return {minRange=8,maxRange=35} end
end
F.ClassicSpellBook.IsSpellKnown=function(id) return id==3044 end
local info,id=F.ClassicShotRangeInfo();assert(id==3044 and info.minRange==8 and info.maxRange==35)
UnitCanAttack=function() return true end;UnitIsDeadOrGhost=function() return false end
F.ClassicSpell.IsSpellInRange=function() return false end
CheckInteractDistance=function() return true end
assert(F.TargetRangeStatus()=='Too close' and F.TargetDistanceEstimate('Too close')=='Est. < 8 yd')
F.ClassicSpell.IsSpellInRange=function() return true end
assert(F.TargetRangeStatus()=='In range')
F.ClassicSpell.IsSpellInRange=function() return false end
CheckInteractDistance=function() return false end
assert(F.TargetRangeStatus()=='Too far')
UnitIsDeadOrGhost=function() return true end
CheckInteractDistance=function() return true end
assert(F.TargetRangeStatus()=='Range uncertain','corpses must never claim shooting eligibility')
F.ClassicSpellBook.IsSpellKnown=function() return false end
assert(F.ClassicShotRangeInfo()==nil,'invalid metadata must not be swapped or invented')
print('PASS: live reversed Auto Shot bounds, learned-shot fallback, close/in/far states and corpse safety')

-- Live follow/shot evidence works even when every spell's metadata is malformed.
UnitIsDeadOrGhost=function() return false end
F.ClassicSpell.GetSpellInfo=function() return {minRange=35,maxRange=0} end
F.ClassicSpell.IsSpellInRange=function() return false end
CheckInteractDistance=function() return true end
assert(F.TargetRangeStatus()=='Too close')
F.ClassicSpell.IsSpellInRange=function() return true end
assert(F.TargetRangeStatus()=='In range')
F.ClassicSpell.IsSpellInRange=function() return false end
CheckInteractDistance=function() return false end
assert(F.TargetRangeStatus()=='Too far')
assert(F.TargetDistanceEstimate('Too far')=='Distance unavailable','invalid bounds cannot support numeric distance')
InCombatLockdown=function() return true end
assert(F.TargetRangeStatus()=='Out of range','combat still avoids protected follow checks')
print('PASS: observed nil shooting bounds still allow close/in/far labels; no fabricated distance; combat guard retained')
