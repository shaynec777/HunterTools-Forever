local F={db={}}
assert(loadfile('HunterTools/Range.lua'))('test',F)
UnitExists=function() return true end
UnitCanAttack=function() return true end
UnitIsDeadOrGhost=function() return false end
local ranged,near=false,true
C_Spell={IsSpellInRange=function(id,target) assert(id==75 and target=='target'); return ranged end,
    GetSpellInfo=function() return {maxRange=35} end}
CheckInteractDistance=function() return near end
assert(F.TargetRangeStatus()=='Too close')
near=false; assert(F.TargetRangeStatus()=='Too far')
ranged=true; assert(F.TargetRangeStatus()=='In range')
ranged=nil; assert(F.TargetRangeStatus()=='Range unavailable')
ranged='secret'; issecretvalue=function(v) return v=='secret' end
assert(F.TargetRangeStatus()=='Range unavailable')
issecretvalue=nil; ranged=false; C_Spell.GetSpellInfo=function() return {maxRange=20} end
assert(F.TargetRangeStatus()=='Range unavailable')
UnitExists=function() return false end; assert(F.TargetRangeStatus()=='No target')
UnitExists=function() return true end; UnitCanAttack=function() return false end
ranged=nil; C_Spell.GetSpellInfo=function() return {minRange=8,maxRange=35} end
CheckInteractDistance=function(_,i) return i==4 end
assert(F.TargetRangeStatus()=='In range' and F.rangeNonEnemy)
local s=F.RangeSettings(); assert(s.enabled and s.x==0 and s.y==-230)
s.enabled=false; s.x=123; assert(F.RangeSettings().x==123 and not F.RangeSettings().enabled)
print('PASS: range classifications, unavailable/secret values, target states and saved settings')

C_Spell.GetSpellInfo=function() return {minRange=8,maxRange=35} end
F.rangeNonEnemy=false
assert(F.TargetDistanceEstimate('In range')=='Est. 8-35 yd')
assert(F.TargetDistanceEstimate('Too close')=='Est. < 8 yd')
assert(F.TargetDistanceEstimate('Too far')=='Est. > 35 yd')
assert(F.TargetDistanceEstimate('No target')=='Distance unavailable')
C_Spell.GetSpellInfo=function() return {maxRange=35} end
assert(F.TargetDistanceEstimate('In range')=='Distance unavailable')
C_Spell.GetSpellInfo=function() return {minRange='secret',maxRange=35} end
issecretvalue=function(v) return v=='secret' end
assert(F.TargetDistanceEstimate('In range')=='Distance unavailable')
issecretvalue=nil
print('PASS: estimated distance bands, missing ranges and restricted values')

F.rangeNonEnemy=true
CheckInteractDistance=function(_,index) return index==3 end
assert(F.TargetDistanceEstimate('Range uncertain')=='Est. 0-10 yd')
CheckInteractDistance=function(_,index) return index==4 end
assert(F.TargetDistanceEstimate('Range uncertain')=='Est. 10-28 yd')
CheckInteractDistance=function() return false end
assert(F.TargetDistanceEstimate('Range uncertain')=='Est. > 28 yd')
print('PASS: non-enemy target distance bands')

-- Friendly/unknown/dead targets must not run combat interaction checks.
InCombatLockdown=function() return true end
local interactions=0
CheckInteractDistance=function() interactions=interactions+1;error('protected call attempted') end
UnitExists=function() return true end
UnitCanAttack=function() return false end
ranged=nil
C_Spell.GetSpellInfo=function() return {minRange=8,maxRange=35} end
assert(F.NonEnemyDistanceBand()==nil)
assert(F.TargetRangeStatus()=='Range uncertain')
assert(F.TargetDistanceEstimate('Range uncertain')=='Distance unavailable')
UnitCanAttack=function() return true end
ranged=false
assert(F.TargetRangeStatus()=='Range unavailable','blocked hostile check stays unavailable')
assert(interactions==1,'public living hostile target permits one follow-distance query')
CheckInteractDistance=function() interactions=interactions+1;return true end
assert(F.TargetRangeStatus()=='Too close','combat hostile near + Auto Shot false establishes too close')
CheckInteractDistance=function() interactions=interactions+1;return false end
assert(F.TargetRangeStatus()=='Too far','combat hostile far + Auto Shot false establishes too far')
CheckInteractDistance=function() return 'secret' end;issecretvalue=function(v) return v=='secret' end
assert(F.TargetRangeStatus()=='Range unavailable','secret hostile distance cannot classify range')
issecretvalue=nil
local before=interactions
UnitCanAttack=function() return 'secret' end;issecretvalue=function(v) return v=='secret' end
assert(F.TargetRangeStatus()=='Range unavailable' and interactions==before)
issecretvalue=nil;UnitCanAttack=function() return true end
UnitIsDeadOrGhost=function() return true end
assert(F.TargetRangeStatus()=='Range unavailable' and interactions==before,'dead targets skip combat distance')
UnitIsDeadOrGhost=function() return false end
ranged=true
assert(F.TargetRangeStatus()=='In range','public spell range remains usable in combat')
assert(interactions==before,'in-range Auto Shot needs no follow query')
InCombatLockdown=function() return false end
ranged=false
CheckInteractDistance=function() return true end
assert(F.TargetRangeStatus()=='Too close','interaction estimates resume after combat')
CheckInteractDistance=function() error('API unavailable') end
assert(F.TargetRangeStatus()=='Range unavailable' and F.NonEnemyDistanceBand()==nil)
print('PASS: combat hostile close/in/far, friendly/dead/secret guards, denied queries and recovery')
