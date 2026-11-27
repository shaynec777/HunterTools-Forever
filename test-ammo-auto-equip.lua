local frames={};CreateFrame=function() local f={};setmetatable(f,{__index=function(_,k) return function() end end});function f:RegisterEvent() end;function f:SetScript(_,fn) self.event=fn end;frames[#frames+1]=f;return f end
local F={db={ammo={}},ammoCatalog={[100]={kind=2},[101]={kind=2},[200]={kind=3}},Print=function() end,AmmoInfo=function(id) return 'ammo '..id end}
local combat,weapon,ammo,cursor=false,2,100,false
local bagAmmo,locked=100,false;local equips=0
InCombatLockdown=function() return combat end;CursorHasItem=function() return cursor end
GetInventoryItemID=function(_,slot) return slot==18 and weapon or ammo end
NUM_TOTAL_EQUIPPED_BAG_SLOTS=0
C_Container={GetContainerNumSlots=function() return 1 end,GetContainerItemInfo=function() return {itemID=bagAmmo,stackCount=10,isLocked=locked} end}
C_Item={GetItemInfoInstant=function(w) return nil,nil,nil,nil,nil,2,w end,
 EquipItemByName=function(id) assert(not combat and not cursor);ammo=id;equips=equips+1 end}
assert(loadfile('HunterTools/AmmoAutoEquip.lua'))('test',F)
assert(not F.AutoAmmoSettings().autoEquip)
F.RememberAutoAmmo();assert(F.db.ammo.preferredAmmo[2]==100)
weapon=3;ammo=200;F.RememberAutoAmmo();assert(F.db.ammo.preferredAmmo[3]==200)
weapon=18;ammo=101;F.RememberAutoAmmo();assert(F.db.ammo.preferredAmmo[18]==101)
F.db.ammo.autoEquip=true
weapon=2;bagAmmo=100;ammo=200;frames[1].event(nil,'PLAYER_EQUIPMENT_CHANGED',18);assert(ammo==100 and equips==1)
frames[1].event(nil,'PLAYER_EQUIPMENT_CHANGED',0);assert(equips==1)
combat=true;weapon=3;bagAmmo=200;frames[1].event(nil,'PLAYER_EQUIPMENT_CHANGED',18);assert(equips==1 and F.autoAmmoPending)
combat=false;frames[1].event(nil,'PLAYER_REGEN_ENABLED');assert(ammo==200 and equips==2)
weapon=18;bagAmmo=100;F.QueueAutoAmmo();assert(equips==2 and F.autoAmmoPending,'missing preferred ammo is not substituted')
bagAmmo=101;locked=true;frames[1].event(nil,'BAG_UPDATE_DELAYED');assert(equips==2)
locked=false;cursor=true;frames[1].event(nil,'ITEM_LOCK_CHANGED');assert(equips==2)
cursor=false;frames[1].event(nil,'CURSOR_CHANGED');assert(ammo==101 and equips==3)
weapon=2;ammo=200;F.db.ammo.preferredAmmo[2]=200;F.QueueAutoAmmo();assert(equips==3,'reject wrong ammo type')
F.db.ammo.autoEquip=false;F.QueueAutoAmmo();assert(equips==3)
print('PASS: opt-in per-weapon ammo, separate bow/crossbow/gun preferences, equipment events, combat deferral, cursor/locks/missing stock and type safety')

-- Delayed events coalesce; the callback rechecks combat and current weapon.
local queue={};C_Timer={After=function(_,fn) queue[#queue+1]=fn end}
F.db.ammo.autoEquip=true;F.db.ammo.preferredAmmo[2]=100;weapon=2;bagAmmo=100;ammo=200
F.QueueAutoAmmo();F.QueueAutoAmmo();assert(#queue==1)
combat=true;queue[1]();assert(equips==3 and F.autoAmmoPending)
combat=false;frames[1].event(nil,'PLAYER_REGEN_ENABLED');queue[2]();assert(equips==4 and ammo==100)
queue[3]() -- post-equip verification

-- Secure action is prepared out of combat; no combat attribute writes occur.
F.db.ammo.preferredAmmo={[2]=100,[3]=200,[18]=101}
local attrs={};local writes=0
F.autoAmmoCombatButton={SetAlpha=function(_,v) F.testButtonAlpha=v end,EnableMouse=function(_,v) F.testButtonMouse=v end,SetAttribute=function(_,key,value) assert(not combat);attrs[key]=value;writes=writes+1 end,Show=function() assert(not combat) end,Hide=function() assert(not combat) end}
F.RefreshAutoAmmoButton()
assert(attrs.type=='macro')
assert(attrs.macrotext:find('/equip [equipped:Bows] item:100',1,true))
assert(attrs.macrotext:find('/equip [equipped:Guns] item:200',1,true))
assert(attrs.macrotext:find('/equip [equipped:Crossbows] item:101',1,true))
local before=writes;combat=true;weapon=3;F.RefreshAutoAmmoButton();assert(writes==before)
combat=false;F.db.ammo.autoEquip=false;F.RefreshAutoAmmoButton();assert(attrs.type==nil and attrs.macrotext==nil)
assert(_G['BINDING_NAME_CLICK HunterToolsEquipWeaponAmmo:LeftButton'])

-- Execute the actual restricted snippet with a fake secure attribute surface.
local secure={attrs={['cycle-count']=3,['cycle-item-1']=200,['cycle-item-2']=100,['cycle-item-3']=101}}
function secure:GetAttribute(k) return self.attrs[k] end
function secure:SetAttribute(k,v) self.attrs[k]=v end
local cycle=assert(loadstring('return function(self,button,down) '..F.autoAmmoCycleSnippet..' end'))()
cycle(secure,'LeftButton',false);assert(secure.attrs.macrotext=='/equip item:200')
cycle(secure,'LeftButton',false);assert(secure.attrs.macrotext=='/equip item:100')
cycle(secure,'LeftButton',false);assert(secure.attrs.macrotext=='/equip item:101')
cycle(secure,'LeftButton',false);assert(secure.attrs.macrotext=='/equip item:200')
cycle(secure,'LeftButton',true);assert(secure.attrs['cycle-index']==1,'key down must not advance twice')
secure.attrs['cycle-count']=0;cycle(secure,'LeftButton',false);assert(secure.attrs.type==nil,'disabled binding cannot reactivate the macro')
local banners,chats=0,0
RaidWarningFrame={};RaidNotice_AddMessage=function() banners=banners+1 end
F.Print=function() chats=chats+1 end;C_Timer=nil;ammo=100
weapon=2
local clicked={GetAttribute=function() return 100 end}
for _,mode in ipairs({'banner','chat','both','off'}) do
 F.db.ammo.switchMessage=mode;F.VerifyAmmoCycle(clicked)
end
assert(banners==2 and chats==2)
ammo=200;F.VerifyAmmoCycle(clicked);assert(banners==2,'failed equip must never announce success')

combat=false;F.db.ammo.autoEquip=true;F.db.ammo.showSwitchButton=false
F.RefreshAutoAmmoButton()
assert(F.testButtonAlpha==0 and F.testButtonMouse==false)
assert(attrs.type=='macro' and attrs['cycle-count']==3,'keybind-only mode retains the secure cycle action')
F.db.ammo.showSwitchButton=true;F.RefreshAutoAmmoButton()
assert(F.testButtonAlpha==1 and F.testButtonMouse==true)
combat=true;F.db.ammo.showSwitchButton=false;F.RefreshAutoAmmoButton()
assert(F.testButtonAlpha==1 and F.testButtonMouse==true,'visibility changes wait for combat to end')
combat=false

-- Mismatches use the chosen channels, delayed equipment updates get confirmed once.
local messages={};F.Print=function(message) messages[#messages+1]=message end
F.db.ammo.switchMessage='both';weapon=3;ammo=200;C_Timer=nil
local before=banners;F.VerifyAmmoCycle(clicked)
assert(messages[#messages]=='Ammo/Weapon mismatch' and banners==before+1)
weapon=2;ammo=200;local deferred={};C_Timer={After=function(_,fn) deferred[#deferred+1]=fn end}
F.VerifyAmmoCycle(clicked);deferred[1]();assert(#deferred==2)
ammo=100;before=banners;deferred[2]();assert(banners==before+1 and messages[#messages]=='Ammo equipped: ammo 100')
deferred[2]();assert(banners==before+1,'completed confirmation does not announce twice')
-- A superseded click cannot produce a late incorrect message.
local stale={GetAttribute=function() return 200 end}
local prior=#messages;F.VerifyAmmoCycle(stale);F.VerifyAmmoCycle(clicked)
deferred[3]();assert(#messages==prior)
deferred[4]();assert(#messages==prior+1)
