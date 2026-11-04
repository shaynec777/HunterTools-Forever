local F={}
WOW_PROJECT_CLASSIC=2;WOW_PROJECT_ID=2
local combat=false
InCombatLockdown=function() return combat end
local pet=true
UnitExists=function(unit) return unit=='pet' and pet end
UnitLevel=function() return 19 end
GetLocale=function() return 'enUS' end
GetPetHappiness=function() return 2,100,1 end
GetPetFoodTypes=function() return 'Fish','Meat' end
GetPetLoyalty=function() return 'Loyalty Level 3' end
GetPetTrainingPoints=function() return 30,10 end
GetSpellInfo=function(id) return 'Spell '..id,'Rank 2',123,0,0,30,id end
GetSpellCooldown=function() return 5,10,1,1 end
IsSpellKnown=function(id) return id==6991 end
IsSpellInRange=function() return 0 end
C_PetInfo={PetAssistMode=function() end}
C_Item={GetItemInfo=function(id) if id==999 then return end;return 'Food',nil,1,id==3173 and 11 or 10 end}
C_Spell=nil;C_SpellBook=nil;C_UnitAuras=nil;C_Minimap=nil;C_TooltipInfo=nil
UnitBuff=function(_,i)
    if i==1 then return 'Pack',123,1,nil,10,100,'player',false,false,13159 end
end
GetNumTrackingTypes=function() return 1 end
GetTrackingInfo=function() return 'Track Beasts',123,1,'spell',1,1494 end
assert(loadfile('source/HunterToolsClassic/ClassicCompat.lua'))('HunterToolsClassic',F)
assert(F.IsClassicEra and C_PetInfo.GetPetHappiness==nil,'adapters must not modify native namespaces')
assert(F.ClassicPetInfo.GetPetHappiness()==2)
assert(F.ClassicPetInfo.GetPetLoyalty()=='Loyalty Level 3')
assert(F.ClassicPetInfo.GetPetTrainingPoints()==30)
F.petFoodTypes={[3173]='Meat',[5469]='Meat',[999]='Meat',[4604]='Fungus'}
assert(F.ClassicPetInfo.CanPetEatItem(3173)==true and F.ClassicPetInfo.CanPetEatItem(5469)==true)
assert(F.ClassicPetInfo.CanPetEatItem(4604)==false,'wrong diet excluded')
assert(F.ClassicPetInfo.CanPetEatItem(12345)==false,'unknown items must not be guessed edible')
assert(F.ClassicPetInfo.CanPetEatItem(999)==nil,'uncached known food stays pending')
UnitLevel=function() return 60 end
assert(F.ClassicPetInfo.CanPetEatItem(3173)==false,'food too far below pet level excluded')
pet=false;assert(F.ClassicPetInfo.CanPetEatItem(3173)==false)
assert(F.ClassicSpellBook.IsSpellKnown(6991)==true)
assert(F.ClassicSpell.GetSpellCooldown(6991).duration==10)
assert(F.ClassicSpell.IsSpellInRange(75,'target')==false,'legacy zero must become false, not true')
assert(F.ClassicAuras.GetAuraDataBySpellName('player','Pack').sourceUnit=='player')
combat=true;assert(F.ClassicAuras.GetAuraDataBySpellName('player','Pack')==nil);combat=false
assert(F.ClassicMinimap.GetTrackingInfo(1).active==true)
assert(F.ClassicMinimap.GetTrackingInfo(1).spellID==1494)
-- Exercise the real feeder selection through the Classic eligibility adapter.
pet=true;UnitLevel=function() return 19 end
UnitGUID=function() return 'Pet-0-1' end;UnitName=function() return 'The Rake' end
NUM_TOTAL_EQUIPPED_BAG_SLOTS=0
local foods={{itemID=3173,stackCount=5},{itemID=5469,stackCount=3}}
C_Container={GetContainerNumSlots=function() return #foods end,GetContainerItemInfo=function(_,i) return foods[i] end}
assert(loadfile('source/HunterToolsClassic/Core.lua'))('HunterToolsClassic',F)
F.LoadSettings()
assert(F.FindFood().id==5469 and F.foodCount==8,'default low-to-high must choose Strider Meat')
F.db.foodOrder='high';assert(F.FindFood().id==3173,'explicit high-to-low must choose Bear Meat')
foods[1].isLocked=true;assert(F.FindFood().id==5469,'locked food cannot be armed')
F.FoodLists(true).blacklist[5469]=true;assert(F.FindFood()==nil,'blocked food cannot be armed')

-- Verify modern APIs are retained when present, without global replacement.
local native=function() return 'modern' end
C_PetInfo={CanPetEatItem=native,GetPetHappiness=native};C_Spell={GetSpellName=native}
local modern={};assert(loadfile('source/HunterToolsClassic/ClassicCompat.lua'))('HunterToolsClassic',modern)
assert(modern.ClassicPetInfo.CanPetEatItem==native and modern.ClassicSpell.GetSpellName==native)
assert(C_PetInfo.CanPetEatItem==native)
print('PASS: Classic private adapters, diet/level/cache/no-pet checks, legacy spells and auras, modern API preservation')
