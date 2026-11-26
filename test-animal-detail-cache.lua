local F={db={},RangeSettings=function() return {} end}
local frames={}
CreateFrame=function()
 local w={};function w:RegisterEvent() end;function w:SetScript(_,fn) self.event=fn end
 frames[#frames+1]=w;return w
end
local now,combat=100,false
GetTime=function() return now end;InCombatLockdown=function() return combat end
UnitGUID=function() return 'Creature-0-0-0-0-1-ABCD' end
UnitPlayerControlled=function() return false end;UnitIsPlayer=function() return false end
UnitCreatureType=function() return 'Beast' end;UnitCreatureFamily=function() return 'Bear' end
UnitLevel=function() return 40 end;UnitName=function() return 'Bear' end
local lore={lines={{leftText='Diet: Meat'},{leftText='Abilities: Bite Rank 1'},{leftText='Claw Rank 2'}}}
local tips,scans,items=0,0,0
C_TooltipInfo={GetUnit=function() tips=tips+1;return lore end}
local count=4;local loaded=true
NUM_TOTAL_EQUIPPED_BAG_SLOTS=0
C_Container={GetContainerNumSlots=function() scans=scans+1;return 3 end,
 GetContainerItemInfo=function(_,slot) return {itemID=slot==3 and 2 or 1,stackCount=count} end}
C_Item={GetItemInfo=function(id) items=items+1;if loaded then return 'Food',nil,nil,id==1 and 10 or 30 end end}
assert(loadfile('HunterTools/BeastKnowledge.lua'))('test',F)
assert(loadfile('HunterTools/TargetPetInfo.lua'))('test',F)
F.petFoodTypes={[1]='Meat',[2]='Fish'}
assert(F.AnimalFoodCounts('Meat',40):find('Meat (8)',1,true))
assert(F.AnimalFoodCounts('Fish',60):find('estimate): 4',1,true))
assert(scans==1 and items==2,'all diets/levels share bag walk and item metadata')
now=103;F.AnimalFoodCounts('Meat',40);assert(scans==1,'details refresh must not rescan unchanged bags')
count=5;frames[2].event(nil,'BAG_UPDATE_DELAYED')
assert(F.AnimalFoodCounts('Meat',40):find('Meat (10)',1,true) and scans==2)
frames[2].event(nil,'GET_ITEM_INFO_RECEIVED',999);F.AnimalFoodCounts('Meat',40);assert(scans==2,'unrelated item loads do not invalidate')
now=134;F.AnimalFoodCounts('Meat',40);assert(scans==3,'missed bag events recover after 30 seconds')
loaded=false;frames[2].event(nil,'BAG_UPDATE_DELAYED');F.AnimalFoodCounts('Fish',40);local before=scans
now=now+1;F.AnimalFoodCounts('Fish',40);assert(scans==before)
loaded=true;frames[2].event(nil,'GET_ITEM_INFO_RECEIVED',2);F.AnimalFoodCounts('Fish',40);assert(scans==before+1)
F.InvalidateBeastLore();F.ObserveBeast('target');local prior=tips
local diet,abilities=F.AnimalLore('target');assert(diet=='Meat' and abilities=='Bite Rank 1; Claw Rank 2')
assert(tips==prior,'journal and display share the same tooltip read')
F.AnimalLore('mouseover');assert(tips==prior,'same GUID across unit tokens shares lore')
lore={lines={{leftText='Diet: Fish'}}};frames[1].event(nil,'UNIT_AURA','target')
assert(F.AnimalLore('target')=='Fish' and tips==prior+1,'Beast Lore aura invalidates immediately')
combat=true;assert(F.AnimalLore('target')==nil and tips==prior+1);combat=false
-- Context reset must discard both inventory and observations.
for _,fn in ipairs(F.characterContextResets) do fn() end
before=scans;F.AnimalFoodCounts('Meat',40);assert(scans==before+1)
prior=tips;F.AnimalLore('target');assert(tips==prior+1)
print('PASS: shared animal inventory, food metadata deduplication, bag/item/fallback invalidation, shared lore, aura refresh and character resets')
