local frames={}
local function widget()
 local w={scripts={},shown=false,text='',height=320}
 setmetatable(w,{__index=function(_,k) if k=='CreateFontString' then return widget elseif k:match('^[A-Z]') then return function() end end end})
 function w:SetScript(k,f) self.scripts[k]=f end
 function w:SetText(v) self.text=v end
 function w:GetText() return self.text end
 function w:GetStringHeight() return #self.text/2 end
 function w:SetHeight(v) self.height=v end
 function w:GetHeight() return self.height end
 function w:Show() self.shown=true end
 function w:Hide() self.shown=false end
 function w:IsShown() return self.shown end
 function w:SetChecked(v) self.checked=v end
 function w:GetChecked() return self.checked end
 frames[#frames+1]=w;return w
end
CreateFrame=widget;UIParent={};UISpecialFrames={};GameTooltip=widget()
local combat=false;InCombatLockdown=function() return combat end
local level=10;UnitLevel=function() return level end;UnitClass=function() return 'Hunter','HUNTER' end
GetInventoryItemLink=function() return 'item:100' end
local F={db={},MenuText=widget,FinishMenu=function() end,Print=function() end,HideConfigPages=function() end}
F.ReadComparisonWeapon=function() return {min=10,max=20,speed=2} end
F.BuildWeaponComparison=function() return nil,'not usable yet' end
assert(loadfile('HunterTools/RangedWeaponData.lua'))('test',F)
assert(#F.rangedWeaponCatalog>40)
local seen={}
for _,w in ipairs(F.rangedWeaponCatalog) do
 assert(not seen[w.id]);seen[w.id]=true
 assert(w.speed>0 and w.min>0 and w.max>=w.min and w.level>=1 and #w.stats>10 and #w.source>5)
 assert(w.sourceType=='crafted' or w.sourceType=='instance' or w.sourceType=='vendor')
 if w.sourceType=='vendor' then assert(w.requirements and w.side and w.vendorCategory and w.source:find('stock',1,true)) end
 assert(w.kind=='guns' or w.kind=='bows' or w.kind=='crossbows')
end
assert(loadfile('HunterTools/RangedWeapons.lua'))('test',F)
assert(F.RangedWeaponSourceLabel({sourceType='crafted'})=='Crafted')
assert(F.RangedWeaponSourceLabel({sourceType='instance'})=='Instance drop')
assert(F.RangedWeaponSourceLabel({sourceType='vendor'})=='Vendor')
assert(F.RangedWeaponSourceLabel({sourceType='vendor',vendorCategory='pvp'})=='Vendor: PvP')
assert(F.RangedWeaponSourceLabel({sourceType='vendor',vendorCategory='reputation'})=='Vendor: reputation')
local statsText=F.RangedWeaponStatsText('Requires Level 20\n(12.00 damage per second)\nDurability 50 / 50')
assert(statsText:find('|cffffdd66Requires Level 20|r',1,true))
assert(statsText:find('|cff66ee88(12.00 damage per second)|r',1,true))
local sourceText=F.RangedWeaponSourceText('Seller — City; Alliance; 1 gold')
assert(sourceText:find('|cff66ddffSeller|r',1,true) and sourceText:find('|cffffdd88City|r',1,true))
local guns=F.FilterRangedWeapons('guns','crafted','',1,25)
assert(#guns>=5)
for i,w in ipairs(guns) do assert(w.kind=='guns' and w.sourceType=='crafted' and w.level<=25);if i>1 then assert(guns[i-1].level<=w.level) end end
assert(#F.FilterRangedWeapons('bows',nil,'Wailing Caverns')==1)
assert(#F.FilterRangedWeapons(nil,nil,'[no literal match]')==0)
assert(#F.FilterRangedWeapons(nil,'vendor')>20 and #F.FilterRangedWeapons(nil,'reputation')>0 and #F.FilterRangedWeapons(nil,'pvp')>0)
local catalog=F.rangedWeaponCatalog
F.rangedWeaponCatalog={
 {id=1,name='Bow',kind='bows',level=10,min=10,max=20,speed=2,source='smith',sourceType='crafted'},
 {id=2,name='Future',kind='bows',level=11,min=100,max=200,speed=1,source='boss',sourceType='instance'},
 {id=3,name='Horde only',kind='guns',level=10,min=100,max=200,speed=1,source='seller',sourceType='vendor',side='Horde',vendorCategory='pvp'},
 {id=4,name='Alliance rep',kind='bows',level=10,min=20,max=40,speed=2,source='seller',sourceType='vendor',side='Alliance',vendorCategory='reputation'},
}
assert(F.SuggestRangedWeapon(10,nil,nil,nil,'Alliance').id==4)
assert(F.SuggestRangedWeapon(10,nil,'crafted',nil,'Alliance').id==1)
assert(F.SuggestRangedWeapon(9,nil,nil,nil,'Alliance')==nil)
assert(F.SuggestRangedWeapon(10,'bows',nil,'Bow','Alliance').id==1)
F.rangedWeaponCatalog=catalog
local originalItem=C_Item
local subclass=3
C_Item={GetItemInfoInstant=function() return 100,'Weapon','Gun','INVTYPE_RANGED',0,2,subclass end}
assert(F.EquippedRangedWeaponKind()=='guns')
subclass=2;assert(F.EquippedRangedWeaponKind()=='bows')
subclass=18;assert(F.EquippedRangedWeaponKind()=='crossbows')
subclass=7;assert(F.EquippedRangedWeaponKind()==nil)
C_Item=originalItem
local shot,dps=F.RangedWeaponBaseComparison({min=20,max=40,speed=3},{min=10,max=20,speed=2})
assert(shot==15 and dps==2.5)
F.CheckRangedWeaponLevel(10);assert(not F.rangedWeaponAlert)
F.RangedWeaponSettings().alerts=true;combat=true;F.CheckRangedWeaponLevel(24)
assert(F.rangedWeaponPending and not F.rangedWeaponAlert)
combat=false;frames[#frames].scripts.OnEvent(nil,'PLAYER_REGEN_ENABLED')
assert(F.rangedWeaponAlert.shown and not F.rangedWeaponPending)
F.rangedWeaponAlert.browseButton.scripts.OnClick()
assert(F.rangedWeaponsPanel.minLevel>10 and F.rangedWeaponsPanel.maxLevel<=24)
for _,w in ipairs(F.rangedWeaponsPanel.items) do assert(w.level>10 and w.level<=24) end
F.rangedWeaponAlert:Hide();F.CheckRangedWeaponLevel(24);assert(not F.rangedWeaponAlert.shown)
F.RangedWeaponSettings().alerts=false;F.CheckRangedWeaponLevel(60);assert(not F.rangedWeaponAlert.shown)
F.OpenRangedWeapons();assert(F.rangedWeaponsPanel.shown and #F.rangedWeaponsPanel.items>40)
F.rangedWeaponsPanel.rows[1].scripts.OnClick(F.rangedWeaponsPanel.rows[1]);assert(F.rangedWeaponsPanel.detail.text:find('Base vs equipped',1,true))
assert(F.rangedWeaponsPanel.detail.text:find('Source:',1,true))
local rowWeapon=F.rangedWeaponsPanel.rows[1].weapon
assert(F.rangedWeaponsPanel.rows[1].text:find(F.RangedWeaponSourceLabel(rowWeapon),1,true))
F.rangedWeaponsPanel.suggest.scripts.OnClick();assert(F.rangedWeaponsPanel.selected.level<=level)
F.rangedWeaponsPanel.kind='bows'
C_Item={GetItemInfoInstant=function() return 100,'Weapon','Gun','INVTYPE_RANGED',0,2,3 end}
F.rangedWeaponsPanel.suggest.scripts.OnClick()
assert(F.rangedWeaponsPanel.kind=='guns' and F.rangedWeaponsPanel.selected.kind=='guns','suggestion must switch from a manually chosen category to equipped type')
assert(F.rangedWeaponsPanel.level:GetText()==tostring(level),'default preview level is current player level')
for _,w in ipairs(F.rangedWeaponsPanel.items) do assert(w.level<=level and w.kind=='guns') end
F.rangedWeaponsPanel.level:SetText('30');F.rangedWeaponsPanel.suggest.scripts.OnClick()
assert(F.rangedWeaponsPanel.maxLevel==30 and F.rangedWeaponsPanel.selected.level<=30)
for _,w in ipairs(F.rangedWeaponsPanel.items) do assert(w.level<=30) end
F.rangedWeaponsPanel.fullList.scripts.OnClick()
assert(F.rangedWeaponsPanel.kind=='guns' and F.rangedWeaponsPanel.maxLevel==nil and not F.rangedWeaponsPanel.levelFiltered)
local future=false;for _,w in ipairs(F.rangedWeaponsPanel.items) do if w.level>30 then future=true end end;assert(future)
F.rangedWeaponsPanel.level:SetText('0');F.rangedWeaponsPanel.suggest.scripts.OnClick();assert(F.rangedWeaponsPanel.maxLevel==nil,'invalid level must not change filters')
F.rangedWeaponsPanel.level:SetText(tostring(level));F.rangedWeaponsPanel.suggest.scripts.OnClick()
C_Item=originalItem
local rebuilds=0;local details=F.rangedWeaponsPanel.Details
F.rangedWeaponsPanel.Details=function(self) rebuilds=rebuilds+1;return details(self) end
F.rangedWeaponsPanel.scripts.OnEvent(nil,'GET_ITEM_INFO_RECEIVED',999999)
F.rangedWeaponsPanel.scripts.OnEvent(nil,'PLAYER_EQUIPMENT_CHANGED',1)
assert(rebuilds==0,'unrelated item/equipment events must not rebuild the comparison')
local queued={};C_Timer={After=function(_,fn) queued[#queued+1]=fn end}
F.rangedWeaponsPanel.scripts.OnEvent(nil,'GET_ITEM_INFO_RECEIVED',F.rangedWeaponsPanel.selected.id)
F.rangedWeaponsPanel.scripts.OnEvent(nil,'GET_ITEM_INFO_RECEIVED',F.rangedWeaponsPanel.selected.id)
assert(#queued==1 and rebuilds==0,'coalesce repeated relevant item notifications')
queued[1]();assert(rebuilds==1)
print('PASS: separate catalog integrity, literal search, filters, sorting, base comparison, no login spam, level crossing, combat deferral, disabled alerts and browser detail')
