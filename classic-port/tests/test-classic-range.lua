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
