-- Exercise the real loader with event bursts, without constructing the UI.
local callbacks,handler={},nil
CreateFrame=function() return {RegisterEvent=function() end,SetScript=function(_,_,fn) handler=fn end} end
local F={supported=true,button={},db={}}
local refreshes,petUpdates=0,0
F.Refresh=function() refreshes=refreshes+1 end
F.UpdatePetStatusWindow=function() petUpdates=petUpdates+1 end
F.HandleFeedCastEvent=function() end
F.QueueFoodEntryScan=function() end
F.QueueInstanceCheck=function() end
F.QueueAmmoEntryScan=function() end
InCombatLockdown=function() return false end
C_Timer={After=function(_,fn) callbacks[#callbacks+1]=fn end}
assert(loadfile('HunterTools/HunterTools.lua'))('test',F)
handler(nil,'UNIT_AURA','nameplate1')
assert(#callbacks==0 and not F.bagsDirty)
handler(nil,'UNIT_AURA','pet');handler(nil,'UNIT_HAPPINESS','pet')
assert(#callbacks==1 and not F.bagsDirty and refreshes==0)
callbacks[1]();assert(refreshes==1 and petUpdates==1)
handler(nil,'BAG_UPDATE_DELAYED');handler(nil,'BAG_UPDATE_DELAYED')
assert(#callbacks==2 and F.bagsDirty and F.questFoodDirty)
callbacks[2]();assert(refreshes==2)
handler(nil,'PET_BAR_UPDATE');assert(F.petAbilitiesDirty)
-- Cache quest scans independently; settings changes and invalidation are immediate.
local Q={db={protectQuestFood=true}}
assert(loadfile('HunterTools/QuestFood.lua'))('test',Q)
local now,scans=10,0
GetTime=function() return now end
Q.ScanQuestFood=function() scans=scans+1 end
Q.EnsureQuestFood();Q.EnsureQuestFood();assert(scans==1)
Q.questFoodDirty=true;Q.EnsureQuestFood();assert(scans==2)
Q.db.protectQuestFood=false;Q.EnsureQuestFood();assert(scans==3)
now=16;Q.EnsureQuestFood();assert(scans==3)
now=41;Q.EnsureQuestFood();assert(scans==4)
print('PASS: unrelated events ignored, bursts coalesced, inventory invalidation, ability invalidation and quest cache recovery')

F.bagsDirty=nil;F.questFoodDirty=nil;F.pendingItems=nil;F.foodEntryPending=nil
local count=#callbacks
handler(nil,'GET_ITEM_INFO_RECEIVED',999,true)
assert(#callbacks==count and not F.bagsDirty and not F.questFoodDirty,'unrelated item info must not invalidate scans')
F.questFoodPendingIDs={[999]=true}
handler(nil,'GET_ITEM_INFO_RECEIVED',999,true)
assert(not F.bagsDirty and F.questFoodDirty and not F.questFoodPendingIDs[999],'quest-only completion must not dirty inventory')
F.questFoodDirty=nil
handler(nil,'ITEM_LOCK_CHANGED',0,1)
assert(not F.questFoodDirty,'item locks do not change quest protection')
print('PASS: unrelated item events ignored, pending item completion accepted, lock changes preserve quest cache')

-- Loading is not permission to treat every item-information event as relevant.
F.bagsDirty=nil;F.questFoodDirty=nil;F.pendingItems=true;F.foodEntryPending=true
local snapshot={count=20,pet='test',at=100};F.foodEntrySnapshot=snapshot
local queued=#callbacks
for i=1,1000 do handler(nil,'GET_ITEM_INFO_RECEIVED',12345,true) end
assert(F.foodEntrySnapshot==snapshot and not F.bagsDirty and not F.questFoodDirty)
assert(#callbacks==queued,'unrelated item bursts must not schedule refreshes during entry loading')
F.questFoodPendingIDs={[777]=true};handler(nil,'GET_ITEM_INFO_RECEIVED',777,true)
assert(F.foodEntrySnapshot==snapshot and not F.bagsDirty and F.questFoodDirty)
F.pendingFoodItemIDs={[888]=true};handler(nil,'GET_ITEM_INFO_RECEIVED',888,true)
assert(F.bagsDirty and F.foodEntrySnapshot==nil and F.pendingFoodItemIDs[888]==nil)
print('PASS: 1000 unrelated item events preserve entry snapshot; quest-only completion preserves it; missing food completion invalidates it')