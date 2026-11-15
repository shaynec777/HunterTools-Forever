local F={db={},Print=function() end,HideConfigPages=function() end,ScanAmmo=function() return true end}
local frames={}
local function widget()
 local w={scripts={},shown=false}
 setmetatable(w,{__index=function(_,k) if k=='CreateFontString' or k=='CreateTexture' then return widget end;if k:match('^[A-Z]') then return function() end end end})
 function w:SetScript(k,f) self.scripts[k]=f end
 function w:RegisterEvent(e) assert(e~='UNIT_GUILD_UPDATE') end
 function w:Show() self.shown=true end
 function w:Hide() self.shown=false end
 function w:IsShown() return self.shown end
 function w:SetText(t) self.text=t end
 function w:GetWidth() return 1000 end
 function w:GetHeight() return 600 end
 function w:GetFrameLevel() return 5 end
 function w:SetPoint(...) self.point={...} end
 frames[#frames+1]=w;return w
end
CreateFrame=widget;UIParent={};UISpecialFrames={}
local linkCallback
EventRegistry={RegisterCallback=function(_,event,fn) assert(event=='SetItemRef');linkCallback=fn end}
local combat=false
InCombatLockdown=function() return combat end
local secret={};issecretvalue=function(v) return v==secret end
local function vec(x,y) return {GetXY=function() return x,y end} end
CreateVector2D=vec
local map=1453
C_Map={GetBestMapForUnit=function() return map end,GetPlayerMapPosition=function() return vec(.5,.5) end,
 GetMapInfo=function(id) return {name='Map '..id} end,GetMapPosFromWorldPos=function() return 1429,vec(.4,.6) end}
C_Map.GetAreaInfo=function() return 'New Forever Zone' end
C_Map.GetMapChildrenInfo=function() return {{name='New Forever Zone',mapID=1429}} end
local canvas=widget();WorldMapFrame=widget()
WorldMapFrame.GetCanvas=function() return canvas end;WorldMapFrame.GetMapID=function() return map end
OpenWorldMap=function(id) map=id;WorldMapFrame:Show() end
local npc=1285
UnitGUID=function(unit) assert(unit=='npc');return npc and 'Creature-0-1-0-0-'..npc..'-000000001' end
UnitName=function() return 'Visited vendor' end
UnitFactionGroup=function() return 'Alliance' end
local links={2512,2515,2516,2519,3030,3033,11284,11285};local incomplete=false;local stock=-1
GetMerchantNumItems=function() return #links end
GetMerchantItemLink=function(i) if incomplete then return end;return '|Hitem:'..links[i]..':0|h[Ammo]|h' end
GetMerchantItemInfo=function() return 'Ammo',nil,1,200,stock,true end
-- Merchant available stock is return 5.
assert(loadfile('source/HunterToolsClassic/AmmoUpgradeData.lua'))('test',F)
assert(loadfile('source/HunterToolsClassic/AmmoVendorData.lua'))('test',F)
assert(#F.ammoVendorCatalog==111,'independent Classic seller reference')
for _,v in ipairs(F.ammoVendorCatalog) do assert(v.worldX and v.worldY and v.instance~=nil) end
F.ammoVendorCatalog={
 {id=1285,name='Test seller',shop='Test shop',mapID=1453,x=.648,y=.722,faction='Alliance',items={2512,2515,2516,2519,3030,3033,11284,11285}},
 {id=3313,name='Enemy seller',mapID=1454,x=.48,y=.8,faction='Horde',items={3030}},
 {id=151,name='Basic seller',mapID=1429,x=.44,y=.66,faction='Alliance',items={2512,2516}},
 {id=9999,name='New zone seller',areaID=16591,zone='New Forever Zone',x=.4,y=.6,faction='Alliance',items={3030}},
 {id=8888,name='No location',zone='Unknown',faction='Alliance',items={3030}},
}
assert(loadfile('source/HunterToolsClassic/AmmoVendors.lua'))('test',F)
F.AmmoInfo=function(id) return 'Ammo '..id end
local c={kind=2,level=25,faction='Alliance',current={dps=3.5},settings={}}
F.AmmoUpgradeContext=function() return c end
local rows=F.AmmoVendorRows(c,false,false)
assert(#rows==1 and rows[1].vendor.id==1285 and rows[1].itemID==3030,'local usable arrow upgrade')
c.kind=3;assert(F.AmmoVendorRows(c,false,false)[1].itemID==3033,'gun ammunition')
c.level=10;assert(#F.AmmoVendorRows(c,false,false)==0,'no unusable or equal-damage upgrade')
assert(#F.AmmoVendorRows(c,false,true)==1,'restocking includes equal/lower stock')
c.kind=2;c.level=25
assert(#F.AmmoVendorRows(c,true,false)==2,'new Forever zones resolve through native map tree; missing positions omitted')
c.faction='Horde';assert(#F.AmmoVendorRows(c,false,false)==0,'enemy faction excluded');c.faction='Alliance'
c.baselineUnknown=true;assert(#F.AmmoVendorRows(c,true,true)==0);c.baselineUnknown=nil
local seller=rows[1].vendor
assert(F.SelectAmmoVendor(seller));assert(F.ammoVendorDestination.id==1285)
assert(F.ammoVendorDestination.shop=='Test shop')
F.UpdateAmmoVendorMarker();assert(F.ammoVendorPin:IsShown(),'map marker drawn')
assert(F.ammoVendorPin.label.text:find('Test shop',1,true),'known shop appears on map label')
assert(F.AmmoVendorShop({id=1285})=='Test shop','existing observations can recover bundled shop names')
assert(not F.AmmoVendorShop({id=151}) and not F.AmmoVendorShop({shop='bad|Hlink'}),'unknown or unsafe shop labels omitted')
npc=151;F.AmmoVendorInteraction('GOSSIP_SHOW');assert(F.ammoVendorDestination,'unrelated conversation must not clear')
npc=1285;F.AmmoVendorInteraction('GOSSIP_SHOW');assert(not F.ammoVendorDestination and not F.ammoVendorPin:IsShown())
F.SelectAmmoVendor(seller);F.AmmoVendorInteraction('MERCHANT_SHOW');assert(not F.ammoVendorDestination)
assert(F.db.ammoVendors[1285].observed and #F.db.ammoVendors[1285].items==8,'stock observed independently')
assert(F.db.ammoVendors[1285].shop=='Test shop','shop retained on stock refresh')
incomplete=true;links={2512};F.ObserveAmmoMerchant();assert(#F.db.ammoVendors[1285].items==8,'loading shop preserves complete data');incomplete=false
links={99999};F.ObserveAmmoMerchant();assert(#F.db.ammoVendors[1285].items==0,'complete empty result overrides stale reference')
assert(#F.AmmoVendorRows(c,false,true)==0)
links={3030};npc=7777;F.ObserveAmmoMerchant();assert(F.db.ammoVendors[7777].items[1]==3030,'new sellers learned')
combat=true;assert(not F.SelectAmmoVendor(seller));npc=1285;F.ObserveAmmoMerchant();assert(#F.db.ammoVendors[1285].items==0);combat=false
npc=nil;F.AmmoVendorInteraction('GOSSIP_SHOW')
F.SelectAmmoVendor(seller);F.ClearAmmoVendorMarker();assert(not F.ammoVendorDestination)
assert(F.AmmoVendorChatLink():find('|Haddon:huntertoolsammo:nearby',1,true))
linkCallback(nil,'addon:huntertoolsammo:nearby');assert(F.ammoVendorDestination.id==7777,'chat link finds a current local seller')
F.ClearAmmoVendorMarker();linkCallback(nil,'addon:huntertoolsammo:nearby:forged');assert(not F.ammoVendorDestination)
combat=true;linkCallback(nil,'addon:huntertoolsammo:nearby');assert(not F.ammoVendorDestination);combat=false
linkCallback(nil,secret);assert(not F.ammoVendorDestination)
F.OpenAmmoVendors();assert(F.ammoVendorPanel:IsShown());assert(F.ammoVendorPanel.rows[1].vendor.id==7777)
-- Zone changes refresh the visible list and hide pins on an unrelated map.
map=1439;F.ammoVendorPanel:Refresh();assert(not F.ammoVendorPanel.rows[1]:IsShown())
C_Map.GetWorldPosFromMapPos=function(id)
 if id==1439 then return 0,vec(0,0) end
 if id==1453 then return 0,vec(20000,0) end
 if id==1429 then return 0,vec(100,0) end
 if id==1456 then return 1,vec(1,0) end
end
F.ammoVendorCatalog[#F.ammoVendorCatalog+1]={id=12000,name='Other continent',mapID=1456,x=.5,y=.5,faction='Neutral',items={3030}}
assert(F.NearestAmmoVendor(c,true).vendor.id==151,'nearest restocking seller by comparable world distance, not higher damage farther away')
assert(F.NearestAmmoVendor(c,false).vendor.id==9999,'upgrade-only search retains damage requirement')
local nearest=F.NearestAmmoVendor(c,false);assert(nearest.worldDistance==100,'world distances are yards')
F.ammoVendorPanel:Refresh();assert(F.ammoVendorPanel.rows[1].vendor.id==9999 and F.ammoVendorPanel.status.text:find('Closest known',1,true),'UI suggests closest upgrade when zone has none')
linkCallback(nil,'addon:huntertoolsammo:nearby');assert(F.ammoVendorDestination.id==151 and map==1429,'chat fallback marks nearest usable seller in another zone')
npc=151;F.AmmoVendorInteraction('GOSSIP_SHOW');assert(not F.ammoVendorDestination,'cross-zone destination still clears on matching interaction')
map=1439;combat=true;assert(not F.NearestAmmoVendor(c,true));combat=false
local worldAPI=C_Map.GetWorldPosFromMapPos;C_Map.GetWorldPosFromMapPos=function() return secret end
assert(not F.NearestAmmoVendor(c,true),'restricted world coordinates cannot produce a suggestion')
C_Map.GetWorldPosFromMapPos=nil;assert(not F.NearestAmmoVendor(c,true),'missing position API cannot produce a guessed nearest seller')
C_Map.GetWorldPosFromMapPos=worldAPI
map=1439
assert(F.MarkLevelAmmoVendor().vendor.id==9999,'current-level button skips closer lower-tier ammunition')
F.ClearAmmoVendorMarker();map=1439;c.level=40
assert(not F.MarkLevelAmmoVendor() and not F.ammoVendorDestination,'never silently substitutes lower-tier ammo when top tier has no known seller')
F.db.ammoVendors[7777].items={3030,11285}
assert(F.MarkLevelAmmoVendor().itemID==11285,'level 40 action selects top usable arrow tier')
F.ClearAmmoVendorMarker();c.level=25;map=1439
Minimap=widget();Minimap.GetWidth=function() return 200 end;Minimap.GetHeight=function() return 200 end;Minimap:Show()
F.ClassicMinimap={GetViewRadius=function() return 100 end}
local rotate,facing,targetNorth='0',0,50
GetCVar=function() return rotate end;GetPlayerFacing=function() return facing end
C_Map.GetWorldPosFromMapPos=function(id) return 0,vec(id==1453 and targetNorth or 0,0) end
F.SelectAmmoVendor(seller);map=1439;WorldMapFrame:Hide();F.UpdateAmmoVendorMarker()
local mini=F.ammoVendorMiniPin
assert(mini:IsShown() and not F.ammoVendorPin:IsShown(),'minimap destination works while world map is closed')
assert(mini.point[4]==0 and mini.point[5]==50,'north-up minimap projection')
rotate='1';facing=math.pi/2;F.UpdateAmmoVendorMarker()
assert(math.abs(mini.point[4]-50)<.001 and math.abs(mini.point[5])<.001,'rotating minimap projection')
rotate='0';targetNorth=1000;F.UpdateAmmoVendorMarker()
assert(mini.atEdge and math.abs(mini.point[5]-82)<.001,'distant vendor clamps inside minimap edge')
combat=true;F.UpdateAmmoVendorMarker();assert(not mini:IsShown());combat=false
rotate='1';facing=secret;F.UpdateAmmoVendorMarker();assert(not mini:IsShown(),'restricted facing hides rotating marker')
rotate='0';F.ClassicMinimap.GetViewRadius=nil;F.UpdateAmmoVendorMarker();assert(not mini:IsShown(),'missing radius clears stale minimap pin')
F.ClassicMinimap.GetViewRadius=function() return 100 end;F.UpdateAmmoVendorMarker();assert(mini:IsShown())
npc=1285;F.AmmoVendorInteraction('GOSSIP_SHOW');assert(not mini:IsShown() and not F.ammoVendorDestination,'conversation clears both map destinations')
print('ammo vendor finder tests passed')
