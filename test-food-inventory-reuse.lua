local F={}
assert(loadfile('HunterTools/Core.lua'))('test',F);F.LoadSettings()
local now,combat,pet=100,false,'pet-one'
GetTime=function() return now end;InCombatLockdown=function() return combat end
UnitGUID=function() return pet end
local count,locked=5,false
NUM_TOTAL_EQUIPPED_BAG_SLOTS=0
C_Container={GetContainerNumSlots=function() return 1 end,GetContainerItemInfo=function() return {itemID=1,stackCount=count,isLocked=locked} end}
C_Item={GetItemInfo=function() return 'Food','link',1,10 end}
local eligibility=0
C_PetInfo={CanPetEatItem=function() eligibility=eligibility+1;return true end}
F.FoodAllowed=function() return true end
F.EnsureFoodScan();assert(eligibility==1 and F.foodCount==5)
now=101;F.MarkFoodScanDirty(true);combat=true;F.EnsureFoodScan();assert(F.bagsDirty)
combat=false;F.EnsureFoodScan();assert(not F.bagsDirty and eligibility==1,'combat exit reuses unchanged public inventory')
now=102;F.MarkFoodScanDirty(true);F.EnsureFoodScan();F.EnsureFoodScan();assert(eligibility==1,'happiness/status callbacks reuse validation')
now=103;count=4;F.MarkFoodScanDirty(true);F.EnsureFoodScan();assert(eligibility==2 and F.foodCount==4,'changed stack rescans')
now=104;F.MarkFoodScanDirty(true);F.MarkFoodScanDirty(false);F.MarkFoodScanDirty(true)
F.EnsureFoodScan();assert(eligibility==3,'quest/rule invalidation cannot be weakened by later bag event')
now=105;F.MarkFoodScanDirty(true);F.EnsureFoodScan(true);assert(eligibility==4,'feed click forces immediate validation')
now=106;locked=true;F.MarkFoodScanDirty(true);F.EnsureFoodScan();assert(eligibility==5 and F.lockedFood)
now=107;locked=false;F.MarkFoodScanDirty(true);F.EnsureFoodScan();assert(eligibility==6 and not F.lockedFood)
now=108;pet='pet-two';F.MarkFoodScanDirty(true);F.EnsureFoodScan();assert(eligibility==7,'new pet always rescans')
now=109;F.pendingItems=true;F.MarkFoodScanDirty(true);F.EnsureFoodScan();assert(eligibility==8,'pending food is not eligible for reuse')
print('PASS: combat/happiness inventory reuse, changed stacks/locks, hard invalidation precedence, pet change, pending data and immediate click validation')
