local time,clock,mem=0,0,1024
GetTime=function() return time end;debugprofilestop=function() return clock end
UpdateAddOnMemoryUsage=function() end;GetAddOnMemoryUsage=function() return mem end
GetFramerate=function() return 60 end
Enum={AddOnProfilerMetric={RecentAverageTime=1,PeakTime=4}}
C_AddOnProfiler={GetAddOnMetric=function(_,metric) return metric==1 and 0.5 or 2 end}
local timers={};C_Timer={NewTicker=function(_,fn) local t={fn=fn};function t:Cancel() self.cancelled=true end;timers[#timers+1]=t;return t end}
local messages={};local F={db={},Print=function(s) messages[#messages+1]=s end}
F.Refresh=function(a) clock=clock+2;return a,nil,'third' end
F.FindFood=function() clock=clock+1;error('expected failure') end
local original=F.Refresh
assert(loadfile('HunterTools/Performance.lua'))('HunterTools',F)
assert(#timers==0 and F.Refresh==original,'disabled profiler must create no timer or wrappers')
F.StartPerformanceTest(10)
local a,b,c=F.Refresh(42);assert(a==42 and b==nil and c=='third','preserve return arity and nil holes')
local ok,err=pcall(F.FindFood);assert(not ok and err:find('expected failure'))
time=5;mem=1536;timers[1].fn();local report=F.PerformanceReport()
assert(report:find('Refresh: 1 calls; 2.00 ms',1,true));assert(report:find('FindFood: 1 calls',1,true))
assert(report:find('+0.50 MB',1,true) and not report:find('nan',1,true))
time=10;timers[1].fn();assert(timers[1].cancelled and F.Refresh==original)
assert(F.db.performanceLastReport:find('10.0s',1,true))
F.PerformanceReport();assert(#messages>5)
C_AddOnProfiler=nil;F.StartPerformanceTest(999);assert(messages[#messages]:find('120s',1,true))
local replacement=function() end;F.Refresh=replacement;F.StopPerformanceTest();assert(F.Refresh==replacement,'preserve later replacement')
assert(F.db.performanceLastReport:find('unavailable',1,true))
F.PerformanceCommand('start 20');F.PerformanceCommand('stop');assert(timers[#timers].cancelled)
-- A pre-registered callback must be measured after a test starts, with nested
-- inclusive/self timing separated and no event arguments captured in settings.
local frame={scripts={}}
function frame:GetScript(k) return self.scripts[k] end
function frame:SetScript(k,fn) self.scripts[k]=fn end
F.Refresh=function() clock=clock+4;return 7,nil,9 end
frame.scripts.OnEvent=function(_,event,private) clock=clock+1;return F.Refresh() end
F.ProfileFrame(frame,'test event','OnEvent',true)
local before=F.db.performanceSpikes.count
frame.scripts.OnEvent(frame,'UNIT_AURA','private text');assert(F.db.performanceSpikes.count==before)
F.StartPerformanceTest(60)
local a,b,c=frame.scripts.OnEvent(frame,'UNIT_AURA','private text');assert(a==7 and b==nil and c==9)
local log=F.db.performanceSpikes;assert(log.count==2 and #log.entries==2)
assert(log.entries[1].name=='Refresh' and log.entries[1].ms==4 and log.entries[1].selfMS==4)
assert(log.entries[1].context=='test event:UNIT_AURA > Refresh')
assert(log.entries[2].name=='test event:UNIT_AURA' and log.entries[2].ms==5 and log.entries[2].selfMS==1)
for i=1,100 do frame.scripts.OnEvent(frame,'UNIT_AURA','private text') end
assert(#log.entries==50 and log.count==202 and log.overwritten==152)
for _,e in ipairs(log.entries) do assert(not e.context:find('private',1,true)) end
F.StopPerformanceTest();assert(log.finished and F.db.performanceSpikes==log)
F.PerformanceSpikeReport();assert(messages[#messages]:find('self',1,true))
local restored={db={performanceSpikes=log},Print=F.Print}
assert(loadfile('HunterTools/Performance.lua'))('HunterTools',restored)
restored.PerformanceCommand('spikes');assert(restored.db.performanceSpikes.count==202)
print('PASS: opt-in profiling, returns/errors, inclusive timing, memory delta, unavailable APIs, auto-stop, wrapper restoration and limits')
