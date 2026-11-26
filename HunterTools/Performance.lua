local addon,F=...
-- Temporary, opt-in instrumentation. No timer or wrappers exist while disabled.
local names={'EnsureFoodScan','FoodInventoryMatches','AnimalFoodInventory','AnimalLore','ReadBeastLore','ObserveBeast','BeastRecord','RangeTargetDetails','TargetPetDetails','AnimalFoodCounts','PetHealRangeWarning','TargetRangeStatus','TargetDistanceEstimate','ScanAmmo','EnsureAmmoScan','TrackingState','AspectState','UpdateHappinessBorder','Refresh','FindFood','CheckAmmoReminder','CheckAmmoUpgradeNotifications','CheckInstancePrompt','CheckAspectPrompt','UpdateAspectButton','UpdateTrackingButton','UpdateRangeWindow','UpdatePetStatusWindow','CheckPetAlerts','AddWeaponComparison','BuildWeaponComparison','ReadComparisonWeapon','FilterRangedWeapons','UpdateAmmoVendorPins','UpdateAmmoVendorMinimap','UpdateAnimalTooltip','UpdatePetTooltip'}
local session
function F.IsPerformanceTestActive() return session~=nil end
local measured
local function safe(fn,...)
    if type(fn)~='function' then return end
    local ok,value=pcall(fn,...)
    if ok and (not issecretvalue or not issecretvalue(value)) and type(value)=='number' then return value end
end
local function memory()
    local update=UpdateAddOnMemoryUsage or (C_AddOns and C_AddOns.UpdateAddOnMemoryUsage)
    if update then pcall(update) end
    return safe(GetAddOnMemoryUsage or (C_AddOns and C_AddOns.GetAddOnMemoryUsage),addon)
end
local function pack(...) return {n=select('#',...),...} end
measured=function(label,fn,...)
    local s=session;if not s then return fn(...) end
    local parent=s.current;local entry={name=label,child=0,parent=parent};s.current=entry
    local start=debugprofilestop();local result=pack(pcall(fn,...));local cost=math.max(0,debugprofilestop()-start)
    s.current=parent;if parent then parent.child=parent.child+cost end
    local row=s.rows[label] or {count=0,total=0,max=0,self=0};s.rows[label]=row
    row.count=row.count+1;row.total=row.total+cost;row.max=math.max(row.max,cost);row.self=(row.self or 0)+math.max(0,cost-entry.child)
    if cost>=s.spikes.threshold then
        local path={label};local p=parent
        while p and #path<8 do table.insert(path,1,p.name);p=p.parent end
        local log=s.spikes;log.count=log.count+1
        local index=(log.count-1)%50+1
        log.entries[index]={at=GetTime()-s.started,name=label,ms=cost,selfMS=math.max(0,cost-entry.child),context=table.concat(path,' > '),combat=InCombatLockdown and InCombatLockdown() or false}
        log.overwritten=math.max(0,log.count-50)
    end
    if not result[1] then error(result[2],0) end
    return unpack(result,2,result.n)
end
-- Callbacks registered before profiling starts still enter this measuring path.
-- Labels are internal names/event types only; event arguments are never logged.
function F.PerformanceCallback(label,fn,...) return measured(label,fn,...) end
function F.WrapPerformanceCallback(label,fn)
    return function(...) return measured(label,fn,...) end
end
function F.ProfileFrame(frame,label,script,eventContext)
    local original=frame:GetScript(script)
    if not original then return end
    frame:SetScript(script,function(self,event,...)
        if not session then return original(self,event,...) end
        local context=label
        if eventContext and type(event)=='string' and event:match('^[A-Z_]+$') then context=label..':'..event end
        return measured(context,original,self,event,...)
    end)
end
local function native()
    local metrics=Enum and Enum.AddOnProfilerMetric
    if not C_AddOnProfiler or not metrics then return end
    return safe(C_AddOnProfiler.GetAddOnMetric,addon,metrics.RecentAverageTime),safe(C_AddOnProfiler.GetAddOnMetric,addon,metrics.PeakTime)
end
local function sample(s)
    local m=memory();s.lastMemory=m or s.lastMemory
    if m then s.peakMemory=math.max(s.peakMemory or m,m) end
    local avg,peak=native();s.recentCPU=avg or s.recentCPU;s.peakCPU=peak or s.peakCPU
    local fps=safe(GetFramerate);if fps then s.minFPS=math.min(s.minFPS or fps,fps) end
    s.samples=s.samples+1
end
function F.PerformanceReport()
    if not session then
        F.Print(F.db and F.db.performanceLastReport or 'No performance test yet. Use /ht perf start 60.');return
    end
    local s=session;sample(s)
    local elapsed=math.max(0.001,GetTime()-s.started)
    local lines={('Performance test: %.1fs; %d samples; instrumentation adds overhead.'):format(elapsed,s.samples)}
    if s.firstMemory and s.lastMemory then lines[#lines+1]=('Addon memory: %.2f MB; change %+.2f MB; peak %.2f MB (GC affects this).'):format(s.lastMemory/1024,(s.lastMemory-s.firstMemory)/1024,s.peakMemory/1024) end
    if s.recentCPU then lines[#lines+1]=('Native addon CPU: recent %.3f ms/tick; session peak %.3f ms (peak includes time before this test).'):format(s.recentCPU,s.peakCPU or 0)
    else lines[#lines+1]='Native addon CPU metric unavailable; timings below cover instrumented functions only.' end
    if s.minFPS then lines[#lines+1]=('Lowest sampled FPS: %.1f (whole game, not addon attribution).'):format(s.minFPS) end
    local rows={};for name,row in pairs(s.rows) do if row.count>0 then rows[#rows+1]={name=name,row=row} end end
    table.sort(rows,function(a,b) return a.row.total>b.row.total end)
    lines[#lines+1]='Top inclusive function times (nested calls overlap; do not add them):'
    for i=1,math.min(10,#rows) do local n,r=rows[i].name,rows[i].row
        lines[#lines+1]=('%s: %d calls; %.2f ms total; %.3f ms/call; %.3f ms max; %.2f ms self'):format(n,r.count,r.total,r.total/r.count,r.max,r.self or 0)
    end
    lines[#lines+1]='Animal food/Beast Lore breakdown (nested times overlap):'
    for _,name in ipairs({'FindFood','EnsureFoodScan','FoodInventoryMatches','AnimalFoodInventory','AnimalFoodCounts','ReadBeastLore','AnimalLore','ObserveBeast','BeastRecord','TargetPetDetails','RangeTargetDetails'}) do
        local r=s.rows[name] or {count=0,total=0,max=0,self=0}
        lines[#lines+1]=('%s: %d calls; %.3f ms total; %.3f ms/call; %.3f ms max; %.3f ms self'):format(name,r.count,r.total,r.count>0 and r.total/r.count or 0,r.max,r.self or 0)
    end
    lines[#lines+1]='Range render/native breakdown (nested times overlap):'
    for _,entry in ipairs(rows) do
        if entry.name:match('^range render:') or entry.name:match('^range native:') then
            local r=entry.row
            lines[#lines+1]=('%s: %d calls; %.3f ms total; %.3f ms max; %.3f ms self'):format(entry.name,r.count,r.total,r.max,r.self or 0)
        end
    end
    lines[#lines+1]=('Spikes >= %.1f ms: %d; retained %d; overwritten %d. /ht perf spikes shows details.'):format(s.spikes.threshold,s.spikes.count,math.min(50,s.spikes.count),s.spikes.overwritten)
    local report=table.concat(lines,'\n');if F.db then F.db.performanceLastReport=report end
    for _,line in ipairs(lines) do F.Print(line) end
    return report
end
function F.StopPerformanceTest()
    if not session then return end
    local s=session
    s.spikes.finished=true;s.spikes.elapsed=GetTime()-s.started
    if s.timer then s.timer:Cancel() end
    -- Restore only our own wrappers, preserving any later intentional replacement.
    for name,row in pairs(s.wrapped) do if F[name]==row.wrapper then F[name]=row.original end end
    F.PerformanceReport();session=nil;F.Print('Performance test stopped; instrumentation removed.')
end
function F.StartPerformanceTest(seconds)
    if session then F.StopPerformanceTest() end
    if type(debugprofilestop)~='function' or not C_Timer or not C_Timer.NewTicker then F.Print('Performance clock/timer unavailable on this client.');return end
    seconds=math.max(10,math.min(120,tonumber(seconds) or 60))
    local s={started=GetTime(),duration=seconds,wrapped={},rows={},samples=0,spikes={threshold=2,count=0,overwritten=0,entries={},version=1,finished=false}};session=s
    if F.db then F.db.performanceSpikes=s.spikes end
    s.firstMemory=memory();s.lastMemory=s.firstMemory;s.peakMemory=s.firstMemory
    for _,name in ipairs(names) do
        local original=F[name]
        if type(original)=='function' then
            local function wrapper(...)
                return measured(name,original,...)
            end
            s.wrapped[name]={original=original,wrapper=wrapper};F[name]=wrapper
        end
    end
    s.timer=C_Timer.NewTicker(5,function() if session~=s then return end;sample(s);if GetTime()-s.started>=s.duration then F.StopPerformanceTest() end end)
    F.Print(('Temporary performance test started for %ds. Play normally; /ht perf stop ends early; /ht perf report shows results. No profiling CVars changed.'):format(seconds))
end
function F.PerformanceSpikeReport()
    local log=F.db and F.db.performanceSpikes
    if not log then F.Print('No spike log yet. Use /ht perf start 120.');return end
    local entries={};for _,e in pairs(log.entries) do entries[#entries+1]=e end
    table.sort(entries,function(a,b) return a.ms>b.ms end)
    F.Print(('Spikes: %d; %d retained; %d overwritten; threshold %.1f ms. Times include diagnostic overhead.'):format(log.count,#entries,log.overwritten,log.threshold))
    for i=1,math.min(10,#entries) do local e=entries[i]
        F.Print(('+%.2fs %s: %.3f ms inclusive / %.3f ms self; %s; %s'):format(e.at,e.name,e.ms,e.selfMS,e.combat and 'combat' or 'out of combat',e.context))
    end
end
function F.PerformanceCommand(text)
    local action,seconds=(text or ''):match('^%s*(%S*)%s*(%d*)')
    if action=='start' then F.StartPerformanceTest(seconds)
    elseif action=='stop' then F.StopPerformanceTest()
    elseif action=='report' then F.PerformanceReport()
    elseif action=='distance' and F.DistanceQueryReport then F.DistanceQueryReport()
    elseif action=='spikes' then F.PerformanceSpikeReport()
    else F.Print('/ht perf start [10-120 seconds]; /ht perf report; /ht perf stop. Reports contain only timings, memory and FPS.') end
end
