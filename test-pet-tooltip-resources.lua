local F={db={}}
InCombatLockdown=function() return false end
assert(loadfile('HunterTools/PetStatus.lua'))('test',F)
local a,b={},{}
issecretvalue=function(v) return v==a or v==b end
UnitHealth=function() return a end;UnitHealthMax=function() return b end
UnitPower=function(_,kind) assert(kind==2);return a end
UnitPowerMax=function(_,kind) assert(kind==2);return b end
local lines,formatted={},{}
local tip={GetName=function() return 'ResourceTestTip' end,NumLines=function() return #lines end}
function tip:AddLine(text)
 lines[#lines+1]=text
 _G['ResourceTestTipTextLeft'..#lines]={SetFormattedText=function(_,fmt,current,maximum)
  assert(current==a and maximum==b);formatted[#formatted+1]=fmt
 end}
end
local s=F.PetStatusSettings()
for _,field in ipairs(F.petStatusFields) do s.tooltipFields[field[1]]=field[1]=='health' or field[1]=='focus' end
F.AddPetStatusTip(tip,{health='Unavailable',focus='Unavailable'})
assert(#formatted==2 and formatted[1]:find('Health',1,true) and formatted[2]:find('Focus',1,true))
assert(not F.db.hp and not F.db.focusValue,'restricted resources never become saved settings')
-- Public values keep their percentage, and absent data stays unavailable.
lines={};formatted={};tip.HunterToolsPetTipAdded=nil
UnitHealth=function() return 25 end;UnitHealthMax=function() return 100 end
UnitPower=function() return nil end
F.AddPetStatusTip(tip,{health='Unavailable',focus='Unavailable'})
assert(#formatted==0 and lines[3]:find('25 / 100 (25%)',1,true) and lines[4]:find('Unavailable',1,true))
-- A tooltip without named font strings safely retains the fallback.
local unnamed={AddLine=function() end};UnitHealth=function() return a end
F.AddPetStatusTip(unnamed,{health='Unavailable',focus='Unavailable'})
-- Paused/missing-pet views never read resource APIs.
UnitHealth=function() error('must not read resources') end
local paused={AddLine=function() end};F.AddPetStatusTip(paused,{paused=true})
print('PASS: restricted health/focus pass directly to native font formatting, public percentages, unavailable/unnamed and combat-paused fallbacks')
