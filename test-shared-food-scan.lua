local F={}
assert(loadfile('HunterTools/Core.lua'))('test',F);F.LoadSettings()
local now,pet,combat=0,'pet-one',false
GetTime=function() return now end;UnitGUID=function() return pet end
InCombatLockdown=function() return combat end
UnitExists=function() return true end;UnitName=function() return 'Pet' end
UnitCreatureFamily=function() return 'Bear' end;UnitLevel=function() return 20 end
UnitIsDeadOrGhost=function() return false end
GameTooltip={HookScript=function() end}
TooltipDataProcessor={AddTooltipPostCall=function() end};Enum={TooltipDataType={Unit=2}}
local bags,edibility,allowed,protection=0,0,0,0
local count,locked,blocked=5,false,false
NUM_TOTAL_EQUIPPED_BAG_SLOTS=0
C_Container={GetContainerNumSlots=function() bags=bags+1;return 3 end,
 GetContainerItemInfo=function(_,slot) return {itemID=slot<3 and 1 or 2,stackCount=count,isLocked=locked} end}
C_Item={GetItemInfo=function(id) return 'Food '..id,'item:'..id,1,10 end}
C_PetInfo={CanPetEatItem=function(id) edibility=edibility+1;return pet=='pet-one' or id==2 end,GetPetHappiness=function() return 3,125,0 end}
F.FoodAllowed=function() allowed=allowed+1;return not blocked end
F.FoodProtectionReason=function() protection=protection+1;return nil end
assert(loadfile('HunterTools/PetStatus.lua'))('test',F)
local settings=F.PetStatusSettings();settings.windowFields.abilities=false;settings.tooltipFields.abilities=false
F.EnsureFoodScan();assert(bags==1 and edibility==2 and allowed==2 and protection==2 and F.foodCount==15)
for i=1,10 do F.PetStatusData();F.EnsureFoodScan() end
assert(bags==1,'status and feeding must share even their first result for the same pet')
F.QueueFoodEntryScan();F.EnsureFoodScan();local initial=bags
for i=1,10 do F.PetStatusData();F.EnsureFoodScan() end
assert(bags==initial,'settling must not cause back-to-back scans')
now=2;F.EnsureFoodScan();F.PetStatusData();assert(bags==initial+1)
now=10;F.EnsureFoodScan();now=12;F.EnsureFoodScan();assert(not F.foodEntryPending)
local stable=bags;now=100;F.EnsureFoodScan();assert(bags==stable,'stable results need no periodic rescan')
F.bagsDirty=true;count=2;F.PetStatusData();F.EnsureFoodScan();assert(bags==stable+1 and F.foodCount==6)
pet='pet-two';F.EnsureFoodScan();F.PetStatusData();assert(bags==stable+2 and F.foodCount==2,'pet switch invalidates shared edibility')
now=100.5;blocked=true;F.bagsDirty=true;F.EnsureFoodScan();assert(F.foodCount==0)
blocked=false;locked=true;F.EnsureFoodScan(true);assert(F.foodCount==0 and F.lockedFood,'forced click scan must recheck locks')
locked=false;count=7;F.EnsureFoodScan(true);assert(F.foodCount==7,'forced validation bypasses cached count')
local before=bags;combat=true;F.bagsDirty=true;F.EnsureFoodScan(true);F.PetStatusData();assert(bags==before and F.bagsDirty)
now=101;combat=false;F.EnsureFoodScan();assert(bags==before+1)
-- A happiness callback can inherit an inventory invalidation from another event.
-- Coalesce it with a recent scan, and prevent status from bypassing that delay.
now=200;F.FindFood();local fresh=bags
F.bagsDirty=true;count=9;now=200.1;F.EnsureFoodScan()
assert(bags==fresh and F.foodScanDeferred and F.bagsDirty)
assert(F.PetStatusData().food=='Inventory settling...' and bags==fresh)
now=200.3;F.EnsureFoodScan();assert(bags==fresh)
now=200.5;F.EnsureFoodScan();assert(bags==fresh+1 and F.foodCount==9 and not F.foodScanDeferred)
F.bagsDirty=true;now=200.6;F.EnsureFoodScan();assert(F.foodScanDeferred)
locked=true;F.EnsureFoodScan(true);assert(bags==fresh+2 and F.lockedFood and not F.foodScanDeferred)
locked=false;F.bagsDirty=true;now=200.7;F.EnsureFoodScan()
pet='pet-one';F.EnsureFoodScan();assert(bags==fresh+3 and F.foodCount==27 and not F.foodScanDeferred)
-- Exercise Refresh's hungry path so a deferred flag cannot prevent its later scan.
F.button={};F.FoodLists=function() end;F.GetState=function() return 'hungry','Hungry' end
F.CheckHungerSound=function() end;F.Disarm=function() end;F.Render=function() end
F.CheckLowFood=function() end;F.CheckTextReminder=function() end
F.bagsDirty=true;now=200.8;F.Refresh();assert(F.foodScanDeferred and bags==fresh+3)
F.button.SetAttribute=function() end;now=201.2;F.Refresh();assert(not F.foodScanDeferred and bags==fresh+4)
-- Exact event-to-ticker regression: dirty inventory arrives 19 ms after a scan.
local last=bags;local armed
F.Disarm=function() armed=nil end
F.button.SetAttribute=function(_,key,value) if key=='type1' then armed=value end end
F.Render=function(mode) F.mode=mode end
F.bagsDirty=true;count=4;now=201.219;F.Refresh()
assert(bags==last and F.foodScanDeferred and not armed and F.mode=='hidden')
F.PetStatusData();assert(bags==last,'status must not bypass event/ticker coalescing')
now=201.3;F.Refresh();now=201.6;F.Refresh();assert(bags==last and F.foodScanDeferUntil==201.7,'burst must not extend the deadline')
-- A real feed-click path must ignore the automatic deadline and re-read slots.
IsShiftKeyDown=function() return false end
now=201.61;F.PreClick(nil,'LeftButton')
assert(bags==last+1 and F.foodCount==12 and armed=='spell' and not F.foodScanDeferred)
F.clickInProgress=false
F.bagsDirty=true;count=2;now=201.62;F.Refresh();assert(bags==last+1 and not armed)
now=202.12;F.Refresh();assert(bags==last+2 and F.foodCount==6 and armed=='spell')
print('PASS: feeding/status share scans, paced settling, unique-item work, inventory/rules/pet invalidation, forced lock/count validation and combat deferral')
