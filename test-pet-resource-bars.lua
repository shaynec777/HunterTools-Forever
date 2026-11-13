local F={db={}}
assert(loadfile('HunterTools/PetStatus.lua'))('test',F)
local function opaque()
    return setmetatable({}, {__tostring=function() error('secret string conversion') end,
        __add=function() error('secret arithmetic') end,__div=function() error('secret arithmetic') end,
        __lt=function() error('secret comparison') end,__le=function() error('secret comparison') end})
end
local health,maxHealth,focus,maxFocus=opaque(),opaque(),opaque(),opaque()
issecretvalue=function(v) return rawequal(v,health) or rawequal(v,maxHealth) or rawequal(v,focus) or rawequal(v,maxFocus) end
UnitExists=function(unit) assert(unit=='pet');return true end
UnitHealth=function(unit,...) assert(unit=='pet' and select('#',...)==0);return health end
UnitHealthMax=function(unit,...) assert(unit=='pet' and select('#',...)==0);return maxHealth end
UnitPower=function(unit,power) assert(unit=='pet' and power==2);return focus end
UnitPowerMax=function(unit,power) assert(unit=='pet' and power==2);return maxFocus end
local function bar()
    local b={label={}}
    function b:SetMinMaxValues(low,high) self.low=low;self.high=high end
    function b:SetValue(value) self.value=value end
    function b:Show() self.shown=true end
    function b:Hide() self.shown=false end
    function b.label:SetFormattedText(fmt,cur,max) self.format=fmt;self.cur=cur;self.max=max end
    function b.label:SetText(text) self.text=text end
    return b
end
local panel={health=bar(),focus=bar()}
local s=F.PetStatusSettings();s.enabled=true
F.UpdatePetStatusResourceBars(panel)
assert(rawequal(panel.health.high,maxHealth) and rawequal(panel.health.value,health))
assert(rawequal(panel.focus.high,maxFocus) and rawequal(panel.focus.value,focus))
assert(rawequal(panel.health.label.cur,health) and rawequal(panel.health.label.max,maxHealth))
assert(panel.focus.label.format=='Focus: %d / %d')
-- Public data fields remain unavailable: opaque display values never enter logic.
InCombatLockdown=function() return true end
panel.details={SetText=function() end};panel.IsShown=function() return true end
F.petStatusWindow=panel
UnitName=function() error('must not inspect pet identity in combat') end
F.UpdatePetStatusWindow();assert(panel.health.shown and panel.focus.shown)
s.windowFields.focus=false;F.UpdatePetStatusWindow();assert(not panel.focus.shown)
UnitExists=function() return false end;F.UpdatePetStatusResourceBars(panel)
assert(not panel.health.shown and not panel.focus.shown,'clear absent-pet bars')
UnitExists=function() return true end;s.windowFields.focus=true
UnitHealth=nil;UnitPower=function() error('API failed') end
F.UpdatePetStatusResourceBars(panel)
assert(panel.health.value==0 and panel.health.high==1 and panel.health.label.text=='Health: Unavailable')
assert(panel.focus.value==0 and panel.focus.label.text=='Focus: Unavailable','no stale fills after failure')
UnitHealth=function() return 0 end;UnitHealthMax=function() return 300 end
UnitPower=function() return 35 end;UnitPowerMax=function() return 100 end
F.UpdatePetStatusResourceBars(panel)
assert(panel.health.label.text=='Health: 0 / 300 (0%)')
assert(panel.focus.label.text=='Focus: 35 / 100 (35%)')
UnitHealthMax=function() return 0 end;F.UpdatePetStatusResourceBars(panel)
assert(panel.health.label.text=='Health: Unavailable')
UnitHealth=function() return health end;UnitHealthMax=function() return maxHealth end
-- Model a rejection of opaque input but acceptance of the public fallback.
panel.health.SetValue=function(self,value) if rawequal(value,health) then error('native setter rejected data') end;self.value=value end
F.UpdatePetStatusResourceBars(panel);assert(panel.health.value==0 and panel.health.label.text=='Health: Unavailable')
print('PASS: native opaque health/focus passthrough, combat updates, settings, absent pets, missing APIs, zero values and stale-state cleanup')
