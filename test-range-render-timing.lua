local clock,reads,now=0,0,100
GetTime=function() return now end
debugprofilestop=function() reads=reads+1;return clock end
GetFramerate=function() return 60 end
C_Timer={NewTicker=function() return {Cancel=function() end} end}
InCombatLockdown=function() return false end
local guid='target-a'
UnitClass=function() return 'Hunter','HUNTER' end
UnitExists=function() return true end
UnitName=function() return 'Public target' end
UnitGUID=function() return guid end
SetPortraitTexture=function() clock=clock+3 end
local function widget()
 return setmetatable({}, {__index=function(_,key)
  if key=='GetStringHeight' then return function() clock=clock+5;return 14 end end
  return function() if key=='Show' then clock=clock+4 elseif key=='SetText' then clock=clock+2 end end
 end})
end
local F={db={},Print=function() end,rangeWindow=widget()}
for _,k in ipairs({'targetName','portrait','petHeal','petDetails','distance','text'}) do F.rangeWindow[k]=widget() end
assert(loadfile('HunterTools/Range.lua'))('test',F)
local details='Bear'
F.TargetPetDetails=function() return details end
F.PetHealRangeWarning=function() end
F.TargetRangeStatus=function() return 'In range',0,1,0 end
F.TargetDistanceEstimate=function() return 'Est. 8-35 yd' end
assert(loadfile('HunterTools/Performance.lua'))('test',F)
F.UpdateRangeWindow();assert(reads==0,'disabled profiling never reads timing clock')
F.StartPerformanceTest(120)
guid='target-b';details='Wolf';F.UpdateRangeWindow()
local report=F.PerformanceReport()
for _,label in ipairs({'range render: portrait','range render: details/layout','range render: status/visibility',
 'range native: SetPortraitTexture','range native: petDetails.GetStringHeight','range native: window.Show','range native: UnitGUID'}) do
 assert(report:find(label,1,true),'missing report attribution '..label)
end
local found={}
for _,e in pairs(F.db.performanceSpikes.entries) do found[e.name]=e end
assert(found['range native: SetPortraitTexture'].ms==3)
assert(found['range native: petDetails.GetStringHeight'].ms==5)
assert(found['range native: window.Show'].ms==4)
assert(found['range native: window.Show'].context:find('range render: status/visibility',1,true))
assert(found['range render: portrait'].selfMS==0,'child UI cost is excluded from stage self time')
assert(found['range render: details/layout'].selfMS==0)
F.StopPerformanceTest();local before=reads;F.UpdateRangeWindow();assert(reads==before)
-- Native errors keep their normal propagation while diagnostics retain their label.
F.StartPerformanceTest(120)
SetPortraitTexture=function() clock=clock+6;error('native failure') end
guid='target-c';local ok,err=pcall(F.UpdateRangeWindow);assert(not ok and err:find('native failure'))
local saw=false
for _,e in pairs(F.db.performanceSpikes.entries) do if e.name=='range native: SetPortraitTexture' then saw=true end end
assert(saw);F.StopPerformanceTest()
print('PASS: range stage/native attribution, nested self timings, saved reports/spikes, error propagation and zero inactive timing clocks')
