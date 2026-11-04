local folder,edition=...
folder=folder or 'source/HunterToolsClassic';edition=edition or 'Classic'
local F={db={}}
CreateFrame=function() return {RegisterEvent=function() end,SetScript=function() end} end
InCombatLockdown=function() return false end
GetTime=function() return 100 end
GetServerTime=function() return 1000 end
UnitClass=function() return 'Hunter','HUNTER' end
local npc=5807
UnitExists=function(unit) return unit~='pet' end
UnitIsPlayer=function() return false end
UnitPlayerControlled=function() return false end
UnitCreatureType=function() return 'Beast' end
UnitGUID=function() return 'Creature-0-1-2-3-'..npc..'-0000ABCD' end
UnitName=function() return 'Observed beast' end
UnitLevel=function() return 10 end
UnitCreatureFamily=function() return 'Cat' end
F.RangeSettings=function() return {} end
assert(loadfile(folder..'/PetDatabase.lua'))('test',F)
assert(loadfile(folder..'/PetopiaTameability.lua'))('test',F)
-- Simulate stale affirmative data; explicit fresh negative evidence must win.
F.petopiaForeverCreatures={[11897]={tameable=true}}
assert(loadfile(folder..'/BeastKnowledge.lua'))('test',F)
assert(loadfile(folder..'/TargetPetInfo.lua'))('test',F)
local count=0
for _,row in pairs(F.petopiaTameability) do
    count=count+1;assert(type(row.tameable)=='boolean')
    assert(row.source:find('/'..edition:lower()..'/',1,true),'wrong game edition in source')
end
assert(count==622)
local rake=F.BeastRecord(5807)
assert(rake.tameable==true and rake.sources.tameable=='Petopia '..edition)
assert(F.AnimalDetails('target',{enabled=true,info=true}):find('Tameable - Petopia '..edition,1,true))
local _,details=F.BeastRecordDetails(5807)
assert(details:find('Tameability: Tameable - Petopia '..edition,1,true))
local duskwing=F.BeastRecord(11897)
assert(duskwing.tameable==false and F.TameabilityText(duskwing)=='Not tameable - Petopia '..edition)
npc=11897
assert(F.AnimalDetails('target',{enabled=true,info=true}):find('Not tameable - Petopia '..edition,1,true))
local owl=F.BeastRecord(14283)
assert(owl.tameable and owl.requiredFaction=='Horde')
assert(F.TameabilityText(owl):find('Horde hunters only',1,true))
assert(F.TameabilityText({family='Cat'})=='not specified by available sources','family alone is not evidence')
local results=F.SearchBeasts('Young Wolf');local found=false
for _,r in ipairs(results) do if r.id==299 then found=true end end
assert(found,'non-teaching creatures must be searchable')
local source=F.BeastSourceURLs(5807)
assert(source==F.petopiaTameability[5807].source,'source link must point to the exact Petopia page')
print('PASS: '..edition..' tameability import, affirmative/negative/restricted flags, live/search details, exact sources and no family inference')
