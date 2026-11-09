local F={db={protectQuestFood=true},foodCatalog={},IsPublic=function() return true end}
local time,reads=0,0
GetTime=function() return time end
InCombatLockdown=function() return false end
NUM_TOTAL_EQUIPPED_BAG_SLOTS=0
C_Container={GetContainerNumSlots=function() return 0 end}
C_Item={GetItemInfo=function(id) reads=reads+1;if id~=2 then return 'Food '..id end end}
C_QuestLog={GetNumQuestLogEntries=function() return 0 end,GetInfo=function() end}
for id=1,300 do F.foodCatalog[id]={} end
assert(loadfile('HunterTools/QuestFood.lua'))('test',F)
F.ScanQuestFood();assert(reads==300)
for i=1,100 do F.ScanQuestFood() end
assert(reads==300,'resolved and pending names must not be requested repeatedly')
assert(F.questFoodPendingIDs[2])
F.InvalidateQuestItemName(2);C_Item.GetItemInfo=function(id) reads=reads+1;return 'Food '..id end
F.ScanQuestFood();assert(reads==301,'completed pending name retries only that item')
F.ScanQuestFood();assert(reads==301)
print('PASS: 100 repeated quest scans make no additional catalog item queries; pending completion retries one ID')
