local F={db={}}
assert(loadfile('HunterTools/Range.lua'))('test',F)
local now,clock,calls=100,0,0
GetTime=function() return now end
debugprofilestop=function() return clock end
UnitGUID=function() return 'Creature-A' end
UnitExists=function() return true end
UnitDistanceSquared=function() calls=calls+1;return 625,true end
UnitPosition=function() error('unexpected position query') end
assert(F.RangeSettings().measuredDistance==false)
assert(F.MeasuredTargetDistance()==nil and calls==0)
F.RangeSettings().measuredDistance=true
assert(F.MeasuredTargetDistance()==25 and calls==1)
now=100.5;assert(F.MeasuredTargetDistance()==25 and calls==1)
now=101;assert(F.TargetDistanceEstimate('Range unavailable')=='Measured: 25.0 yd' and calls==2)
local function fresh() F.distanceRuntime=nil;now=now+10 end
fresh();UnitDistanceSquared=function() return 0,true end
assert(F.MeasuredTargetDistance()==0)
UnitPosition=nil
for _,v in ipairs({-1,math.huge,0/0,'secret'}) do
    fresh();issecretvalue=function(x) return x=='secret' end
    UnitDistanceSquared=function() return v,true end
    assert(F.MeasuredTargetDistance()==nil)
end
fresh();UnitDistanceSquared=function() return 625,'secret' end
assert(F.MeasuredTargetDistance()==nil)
fresh();UnitDistanceSquared=function() return 625,false end
assert(F.MeasuredTargetDistance()==nil)
fresh();UnitDistanceSquared=function() error('restricted') end
assert(F.MeasuredTargetDistance()==nil)
fresh();local targetMap=1
UnitPosition=function(unit) if unit=='player' then return 1,1,1,1 end;return 4,5,13,targetMap end
assert(F.MeasuredTargetDistance()==13)
fresh();targetMap=2;assert(F.MeasuredTargetDistance()==nil)
fresh();targetMap='secret';assert(F.MeasuredTargetDistance()==nil)
fresh();UnitPosition=function() return 0,0,0,1 end
assert(F.MeasuredTargetDistance()==nil)
fresh();UnitPosition=function() error('restricted') end
assert(F.MeasuredTargetDistance()==nil)
UnitExists=function() return false end
assert(F.MeasuredTargetDistance()==nil)
UnitExists=function() return 'secret' end
assert(F.MeasuredTargetDistance()==nil)
UnitExists=function() return true end
-- Failed measurements back off, and target coordinates are checked before player.
fresh();calls=0;local positions=0
UnitDistanceSquared=function() calls=calls+1;return nil,false end
UnitPosition=function(unit) assert(unit=='target');positions=positions+1 end
assert(F.MeasuredTargetDistance()==nil and calls==1 and positions==1)
now=now+1;assert(F.MeasuredTargetDistance()==nil and calls==1 and positions==1)
now=now+4;assert(F.MeasuredTargetDistance()==nil and calls==2 and positions==2)
-- A slow call is attributed precisely and pauses even across target changes.
fresh();calls=0;positions=0
UnitDistanceSquared=function() calls=calls+1;clock=clock+12;return 100,true end
assert(F.MeasuredTargetDistance()==nil and calls==1 and positions==0)
assert(F.db.distanceQueryDiagnostics['UnitDistanceSquared:target'].max==12)
assert(F.db.distanceQueryDiagnostics['UnitDistanceSquared:target'].slow==1)
UnitGUID=function() return 'Creature-B' end
now=now+1;F.MeasuredTargetDistance();assert(calls==1)
now=now+60;F.MeasuredTargetDistance();assert(calls==2)
-- Each position query has independent attribution and a slow-query pause.
for _,slowUnit in ipairs({'target','player'}) do
 fresh();UnitDistanceSquared=function() return nil,false end
 UnitPosition=function(unit) if unit==slowUnit then clock=clock+15 end;return unit=='target' and 4 or 1,1,1,1 end
 assert(F.MeasuredTargetDistance()==nil)
 assert(F.db.distanceQueryDiagnostics['UnitPosition:'..slowUnit].max==15)
end
-- Target changes never reuse a previous target's cached value.
fresh();UnitDistanceSquared=function() return 100,true end
assert(F.MeasuredTargetDistance()==10)
UnitGUID=function() return 'Creature-C' end
UnitDistanceSquared=function() return 400,true end
assert(F.MeasuredTargetDistance()==20)
F.RangeSettings().measuredDistance=false
calls=0;UnitDistanceSquared=function() calls=calls+1 end
assert(F.MeasuredTargetDistance()==nil and calls==0 and F.distanceRuntime==nil)
print('PASS: optional measurements, per-query attribution, backoff, slow circuit and target-safe cache')
