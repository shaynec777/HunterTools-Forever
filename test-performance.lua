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
now=16;Q.EnsureQuestFood();assert(scans==4)
print('PASS: unrelated events ignored, bursts coalesced, inventory invalidation, ability invalidation and quest cache recovery')
