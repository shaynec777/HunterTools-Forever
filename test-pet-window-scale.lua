local F={db={}}
local combat=false
InCombatLockdown=function() return combat end
assert(loadfile('HunterTools/PetStatus.lua'))('test',F)
assert(F.PetStatusSettings().scale==1)
local calls,scale,point=0,nil,nil
F.petStatusWindow={SetScale=function(_,v) calls=calls+1;scale=v end,ClearAllPoints=function() end,
 SetPoint=function(_,...) point={...} end}
local s=F.PetStatusSettings();s.x=200;s.y=-100
F.SetPetStatusScale(1.5);assert(scale==1.5 and point[4]==200/1.5 and point[5]==-100/1.5)
F.ApplyPetStatusScale();assert(calls==1,'unchanged updater must not rewrite scale')
F.SetPetStatusScale(10);assert(scale==2)
F.SetPetStatusScale(0.1);assert(scale==0.5)
combat=true;F.SetPetStatusScale(1);assert(scale==0.5 and s.scale==0.5)
combat=false;F.SetPetStatusScale(1);assert(scale==1)
s.scale=0/0;assert(F.PetStatusSettings().scale==1)
F.SetPetStatusScale(0/0);assert(s.scale==1)
print('PASS: saved pet window scale, limits, stable anchor, no repeated writes and combat guard')
