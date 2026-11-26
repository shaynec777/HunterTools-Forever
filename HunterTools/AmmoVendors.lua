local _,F=...
local setMarkerUpdates
local function public(v) return not issecretvalue or not issecretvalue(v) end
local function query(fn,...)
    if type(fn)~='function' then return end
    local ok,a,b,c=pcall(fn,...);if not ok then return end
    if not public(a) then a=nil end;if not public(b) then b=nil end;if not public(c) then c=nil end
    return a,b,c
end
local function number(v) return public(v) and type(v)=='number' and v==v and math.abs(v)<1e8 end
local function point(map,x,y) return number(map) and map>0 and number(x) and number(y) and x>=0 and x<=1 and y>=0 and y<=1 end
local function npcID()
    local guid=query(UnitGUID,'npc')
    if type(guid)~='string' then return end
    return tonumber(guid:match('^Creature%-%d+%-%d+%-%d+%-%d+%-(%d+)%-'))
end
local function observations()
    if not F.db then return {} end
    if type(F.db.ammoVendors)~='table' then F.db.ammoVendors={} end
    return F.db.ammoVendors
end
local resolvedMaps={}
local function resolveMap(v)
    if number(v.mapID) then return v.mapID end
    if not number(v.areaID) or not number(v.x) or not number(v.y) then return end
    if resolvedMaps[v.areaID] then return resolvedMaps[v.areaID] end
    local name=query(C_Map and C_Map.GetAreaInfo,v.areaID) or v.zone
    local current=query(C_Map and C_Map.GetBestMapForUnit,'player')
    local info=number(current) and query(C_Map and C_Map.GetMapInfo,current)
    if info and info.name==name then resolvedMaps[v.areaID]=current;return current end
    -- New Forever zones are resolved through the client's map tree, including
    -- localized area names. There is no external map library dependency.
    for _,root in ipairs({946,947,1414,1415}) do
        local children=query(C_Map and C_Map.GetMapChildrenInfo,root,nil,true)
        if type(children)=='table' then
            for _,child in ipairs(children) do
                if public(child.name) and child.name==name and number(child.mapID) then resolvedMaps[v.areaID]=child.mapID;return child.mapID end
            end
        end
    end
end
local function referenceVendors()
    local vendors={}
    for _,v in ipairs(F.ammoVendorCatalog) do
        local row={};for k,value in pairs(v) do row[k]=value end
        row.mapID=resolveMap(v);vendors[v.id]=row
    end
    return vendors
end
local function worldPoint(map,x,y)
    if not point(map,x,y) or not CreateVector2D then return end
    local instance,pos=query(C_Map and C_Map.GetWorldPosFromMapPos,map,CreateVector2D(x,y))
    if not number(instance) or not pos then return end
    local wx,wy=query(pos.GetXY,pos)
    if number(wx) and number(wy) then return instance,wx,wy end
end
function F.AmmoVendorRows(c,allZones,restock)
    local rows={};if not c or c.baselineUnknown then return rows end
    local map=query(C_Map and C_Map.GetBestMapForUnit,'player')
    local pos=number(map) and query(C_Map and C_Map.GetPlayerMapPosition,map,'player')
    local px,py;if pos then px,py=query(pos.GetXY,pos) end
    local playerInstance,playerX,playerY
    if allZones then playerInstance,playerX,playerY=worldPoint(map,px,py) end
    local width,height=query(C_Map and C_Map.GetMapWorldSize,map)
    if not number(width) or not number(height) then width,height=1,1 end
    local vendors=referenceVendors()
    for id,v in pairs(observations()) do if type(v)=='table' then vendors[id]=v end end
    for _,v in pairs(vendors) do
        if point(v.mapID,v.x,v.y) and (allZones or v.mapID==map) and (v.faction==c.faction or v.faction=='Neutral') then
            local bestID,best
            for _,id in ipairs(v.items or {}) do
                local e=F.ammoUpgradeCatalog[id]
                if e and e.sourceType=='vendor' and e.kind==c.kind and e.level<=c.level and (not e.engineered or c.settings.includeEngineered)
                    and (restock or e.dps>(c.current and c.current.dps or 0)) and (not best or e.dps>best.dps) then bestID,best=id,e end
            end
            if best then
                local row={vendor=v,itemID=bestID,entry=best}
                if map==v.mapID and number(px) and number(py) then row.distance=((v.x-px)*width)^2+((v.y-py)*height)^2 end
                if playerInstance then
                    local instance,wx,wy=worldPoint(v.mapID,v.x,v.y)
                    if instance==playerInstance and number(wx) and number(wy) then row.worldDistance=math.sqrt((wx-playerX)^2+(wy-playerY)^2) end
                end
                rows[#rows+1]=row
            end
        end
    end
    table.sort(rows,function(a,b)
        if a.distance and not b.distance then return true end;if b.distance and not a.distance then return false end
        if a.distance and b.distance and a.distance~=b.distance then return a.distance<b.distance end
        if a.entry.dps~=b.entry.dps then return a.entry.dps>b.entry.dps end
        return a.vendor.id<b.vendor.id
    end)
    return rows
end
function F.NearestAmmoVendor(c,restock,minimumDPS)
    if InCombatLockdown() then return end
    local best
    for _,row in ipairs(F.AmmoVendorRows(c,true,restock)) do
        -- Different continents/instances and unavailable coordinates cannot be
        -- ranked against each other. Never guess a nearest seller from names.
        if (not minimumDPS or row.entry.dps>=minimumDPS) and number(row.worldDistance) and (not best or row.worldDistance<best.worldDistance
            or row.worldDistance==best.worldDistance and row.vendor.id<best.vendor.id) then best=row end
    end
    return best
end
local function nearestDescription(row)
    local info=query(C_Map and C_Map.GetMapInfo,row.vendor.mapID)
    return row.vendor.name..' - '..(info and info.name or row.vendor.zone or 'another zone')
        ..(' (~%d yd straight-line; travel route may be longer)'):format(row.worldDistance)
end
function F.LevelAmmoVendorRow()
    if InCombatLockdown() then F.Print('Find an ammo seller after combat.');return end
    local c,reason=F.AmmoUpgradeContext(nil,true,true)
    if not c then F.Print(reason or 'Ammo data is unavailable.');return end
    -- This action asks for the current level's best ordinary vendor tier,
    -- independent of carried stock or whether it would count as an upgrade.
    local desired
    for _,entry in pairs(F.ammoUpgradeCatalog) do
        if entry.sourceType=='vendor' and entry.kind==c.kind and entry.level<=c.level and (not desired or entry.dps>desired) then desired=entry.dps end
    end
    if not desired then F.Print('No ordinary vendor ammo is known for your weapon and level.');return end
    local context={};for k,value in pairs(c) do context[k]=value end;context.baselineUnknown=false
    local row=F.NearestAmmoVendor(context,true,desired)
    if not row then F.Print('No known seller of your current-level ammo could be located on this continent.');return end
    F.Print('Current-level ammo: '..F.AmmoInfo(row.itemID)..'. Closest known seller: '..nearestDescription(row)..'.')
    return row
end
function F.MarkLevelAmmoVendor()
    local row=F.LevelAmmoVendorRow()
    if row then F.SelectAmmoVendor(row.vendor) end
    return row
end
function F.ClearAmmoVendorMarker(skipRefresh)
    F.ammoVendorDestination=nil
    if setMarkerUpdates then setMarkerUpdates(false) end
    if F.ammoVendorPin then F.ammoVendorPin:Hide() end
    if F.ammoVendorMiniPin then F.ammoVendorMiniPin:Hide() end
    if not skipRefresh and F.ammoVendorPanel and F.ammoVendorPanel:IsShown() then F.ammoVendorPanel:Refresh() end
end
function F.AmmoVendorShop(v)
    if type(v)~='table' then return end
    local shop=v.shop
    if not shop then
        for _,reference in ipairs(F.ammoVendorCatalog) do if reference.id==v.id then shop=reference.shop;break end end
    end
    if public(shop) and type(shop)=='string' and #shop>0 and #shop<=90 and not shop:find('[|\r\n]') then return shop end
end
function F.SelectAmmoVendor(v)
    if InCombatLockdown() or type(v)~='table' or not point(v.mapID,v.x,v.y) then return end
    F.ammoVendorDestination={id=v.id,name=v.name,mapID=v.mapID,x=v.x,y=v.y,shop=F.AmmoVendorShop(v)}
    if setMarkerUpdates then setMarkerUpdates(true) end
    if OpenWorldMap then OpenWorldMap(v.mapID)
    elseif WorldMapFrame then WorldMapFrame:Show();if WorldMapFrame.SetMapID then WorldMapFrame:SetMapID(v.mapID) end end
    F.UpdateAmmoVendorMarker()
    F.Print('Ammo seller: '..v.name..'. Marker clears when you talk to this NPC.')
    return true
end
function F.UpdateAmmoVendorMinimap()
    local pin=F.ammoVendorMiniPin;if pin then pin:Hide() end
    local v=F.ammoVendorDestination
    if not v or not Minimap or InCombatLockdown() or query(Minimap.IsShown,Minimap)==false then return end
    local map=query(C_Map and C_Map.GetBestMapForUnit,'player')
    local pos=query(C_Map and C_Map.GetPlayerMapPosition,map,'player')
    local x,y;if pos then x,y=query(pos.GetXY,pos) end
    local instance,px,py=worldPoint(map,x,y)
    local targetInstance,tx,ty=worldPoint(v.mapID,v.x,v.y)
    local radius=query(C_Minimap and C_Minimap.GetViewRadius)
    if not instance or instance~=targetInstance or not number(radius) or radius<=0 then return end
    local north,west=tx-px,ty-py
    local distance=math.sqrt(north*north+west*west)
    local east,up=-west,north
    if query(GetCVar,'rotateMinimap')=='1' then
        local facing=query(GetPlayerFacing);if not number(facing) then return end
        east=-west*math.cos(facing)+north*math.sin(facing)
        up=north*math.cos(facing)+west*math.sin(facing)
    end
    local width,height=query(Minimap.GetWidth,Minimap),query(Minimap.GetHeight,Minimap)
    if not number(width) or not number(height) or width<=0 or height<=0 then return end
    -- Clamp distant destinations inside a circle, also safe for square minimaps.
    local factor=distance>0 and math.min(1,.82*radius/distance) or 1
    if not pin then
        pin=CreateFrame('Frame',nil,Minimap,'BackdropTemplate');F.ammoVendorMiniPin=pin;pin:SetSize(20,20)
        pin:SetBackdrop({bgFile='Interface\\Buttons\\WHITE8X8',edgeFile='Interface\\Buttons\\WHITE8X8',edgeSize=2})
        pin:SetBackdropColor(.01,.04,.06,.95);pin:SetBackdropBorderColor(.2,.9,1,1)
        pin.texture=pin:CreateTexture(nil,'OVERLAY');pin.texture:SetSize(14,14);pin.texture:SetPoint('CENTER');pin.texture:SetTexture('Interface\\Minimap\\Tracking\\Ammunition')
        pin:EnableMouse(true)
        pin:SetScript('OnEnter',function(self)
            local destination=F.ammoVendorDestination
            if not destination or not GameTooltip then return end
            GameTooltip:SetOwner(self,'ANCHOR_LEFT');GameTooltip:AddLine('Ammo seller: '..destination.name,.4,.95,1)
            if destination.shop then GameTooltip:AddLine(destination.shop,1,.9,.6) end
            GameTooltip:AddLine(('~%d yd straight-line'):format(self.distance),1,1,1)
            if self.atEdge then GameTooltip:AddLine('Outside minimap view; marker shows direction.',1,.85,.4) end
            GameTooltip:Show()
        end)
        pin:SetScript('OnLeave',function() if GameTooltip then GameTooltip:Hide() end end)
    end
    pin.distance=distance;pin.atEdge=factor<1
    pin:SetFrameLevel(Minimap:GetFrameLevel()+25);pin:ClearAllPoints()
    pin:SetPoint('CENTER',Minimap,'CENTER',east*factor/radius*width/2,up*factor/radius*height/2);pin:Show()
end
function F.UpdateAmmoVendorMarker()
    F.UpdateAmmoVendorMinimap()
    local pin=F.ammoVendorPin;if pin then pin:Hide() end
    local v=F.ammoVendorDestination;local map=WorldMapFrame
    if not v or not map or not query(map.IsShown,map) or InCombatLockdown() then return end
    local canvas=query(map.GetCanvas,map);local current=query(map.GetMapID,map)
    if not canvas then return end
    local x,y
    if current==v.mapID then x,y=v.x,v.y
    elseif F.MobFinderWorldPoint and F.MobFinderMapPoint then
        local wx,wy,instance=F.MobFinderWorldPoint(v.mapID,v.x,v.y)
        x,y=F.MobFinderMapPoint({x=wx,y=wy,instance=instance},current)
    end
    local w,h=query(canvas.GetWidth,canvas),query(canvas.GetHeight,canvas)
    if not point(current,x,y) or not number(w) or not number(h) then return end
    if not pin then
        -- Keep the anchor in canvas coordinates. Scale only its visual child:
        -- scaling the anchor also scales its map offsets and moves the marker.
        pin=CreateFrame('Frame',nil,canvas);F.ammoVendorPin=pin;pin:SetSize(1,1)
        pin.badge=CreateFrame('Frame',nil,pin,'BackdropTemplate');pin.badge:SetSize(34,34);pin.badge:SetPoint('CENTER',pin,'CENTER')
        pin.badge:SetBackdrop({bgFile='Interface\\Buttons\\WHITE8X8',edgeFile='Interface\\Buttons\\WHITE8X8',edgeSize=2})
        pin.badge:SetBackdropColor(.01,.04,.06,.95);pin.badge:SetBackdropBorderColor(.2,.9,1,1)
        pin.texture=pin.badge:CreateTexture(nil,'OVERLAY');pin.texture:SetSize(26,26);pin.texture:SetPoint('CENTER');pin.texture:SetTexture('Interface\\Minimap\\Tracking\\Ammunition')
        pin.caption=CreateFrame('Frame',nil,pin.badge,'BackdropTemplate');pin.caption:SetSize(190,24);pin.caption:SetPoint('BOTTOM',pin.badge,'TOP',0,3)
        pin.caption:SetBackdrop({bgFile='Interface\\Buttons\\WHITE8X8',edgeFile='Interface\\Buttons\\WHITE8X8',edgeSize=1})
        pin.caption:SetBackdropColor(0,0,0,.82);pin.caption:SetBackdropBorderColor(.2,.9,1,1)
        pin.label=pin.caption:CreateFontString(nil,'OVERLAY','GameFontNormal');pin.label:SetAllPoints();pin.label:SetTextColor(1,1,1)
        pin.label:SetFont(STANDARD_TEXT_FONT or 'Fonts\\FRIZQT__.TTF',14,'OUTLINE')
    end
    -- Zone overlays can use a higher strata than the canvas. Frame level alone
    -- cannot put our marker above them, even when its coordinates are correct.
    pin:SetParent(canvas);pin:SetFrameStrata('TOOLTIP');pin:SetFrameLevel(canvas:GetFrameLevel()+100)
    pin:ClearAllPoints();pin:SetPoint('CENTER',canvas,'TOPLEFT',x*w,-y*h)
    -- The map canvas already transforms its children; inverse-scale compensation
    -- over-enlarges the badge on the live Forever map.
    pin.badge:SetScale(1)
    pin.badge:SetFrameStrata('TOOLTIP');pin.caption:SetFrameStrata('TOOLTIP')
    pin.badge:SetFrameLevel(pin:GetFrameLevel()+1);pin.caption:SetFrameLevel(pin:GetFrameLevel()+2)
    pin.caption:SetSize(v.shop and 230 or 190,v.shop and 38 or 24)
    pin.label:SetText('|cff66eeff'..v.name..'|r'..(v.shop and '\n|cffffe6aa'..v.shop..'|r' or ''))
    pin:Show()
end
function F.ObserveAmmoMerchant()
    if not F.db or InCombatLockdown() then return end
    local id=npcID();local name=query(UnitName,'npc');local map=query(C_Map and C_Map.GetBestMapForUnit,'player')
    local pos=number(map) and query(C_Map and C_Map.GetPlayerMapPosition,map,'player')
    if not id or type(name)~='string' or not pos then return end
    local x,y=query(pos.GetXY,pos);if not point(map,x,y) then return end
    local n=query(GetMerchantNumItems);if not number(n) or n<=0 or n>1000 then return end
    local items={}
    -- A partially loaded shop must never replace a complete observation.
    for i=1,n do
        local link=query(GetMerchantItemLink,i)
        if type(link)~='string' then return end
        local item=tonumber(link:match('item:(%d+)'))
        local stock
        local ok,a,b,c,d,e=pcall(GetMerchantItemInfo,i)
        if not ok or not public(e) or not number(e) then return end
        stock=e
        local entry=F.ammoUpgradeCatalog[item]
        if entry and entry.sourceType=='vendor' and (stock==-1 or stock>0) then items[#items+1]=item end
    end
    -- Also retain empty observations for known vendors, overriding stale seed stock.
    local known=observations()[id] or referenceVendors()[id]
    if not known then for _,v in ipairs(F.ammoVendorCatalog) do if v.id==id then known=true;break end end end
    if #items==0 and not known then return end
    observations()[id]={id=id,name=name,mapID=map,x=x,y=y,faction=query(UnitFactionGroup,'player'),items=items,observed=true,shop=F.AmmoVendorShop(known)}
end
function F.AmmoVendorInteraction(event)
    if InCombatLockdown() then return end
    local id=npcID();local v=F.ammoVendorDestination
    if id and v and id==v.id then F.ClearAmmoVendorMarker() end
    if event=='MERCHANT_SHOW' or event=='MERCHANT_UPDATE' then F.ObserveAmmoMerchant() end
    if F.ammoVendorPanel and F.ammoVendorPanel:IsShown() then F.ammoVendorPanel:Refresh() end
end
function F.AmmoVendorChatLink()
    if not F.ammoVendorLinksReady then return '' end
    return ' |cff80ff80|Haddon:huntertoolsammo:nearby|h[Mark nearby ammo seller]|h|r'
end
function F.HandleAmmoVendorLink(link)
    if not public(link) or type(link)~='string' or link~='addon:huntertoolsammo:nearby' then return end
    if InCombatLockdown() then F.Print('Mark an ammo seller after combat.');return end
    local c,reason=F.AmmoUpgradeContext(F.ScanAmmo(),true)
    if not c then c,reason=F.AmmoUpgradeContext(nil,true,true) end
    if not c then F.Print(reason or 'Ammo data is unavailable.');return end
    local rows=F.AmmoVendorRows(c,false,false)
    if #rows==0 then rows=F.AmmoVendorRows(c,false,true) end
    if rows[1] then F.SelectAmmoVendor(rows[1].vendor)
    else
        local nearest=F.NearestAmmoVendor(c,true)
        if nearest then
            F.Print('No known suitable seller in this zone. Closest known ammo seller: '..nearestDescription(nearest)..'.')
            F.SelectAmmoVendor(nearest.vendor)
        else F.Print('No known suitable seller in this zone; a closest seller on this continent could not be determined. Choose All known zones to browse.');F.OpenAmmoVendors() end
    end
end
if EventRegistry and EventRegistry.RegisterCallback then
    EventRegistry:RegisterCallback('SetItemRef',function(_,link) F.HandleAmmoVendorLink(link) end,F)
    F.ammoVendorLinksReady=true
end
function F.OpenAmmoVendors()
    if InCombatLockdown() then F.Print('Open ammo sellers after combat.');return end
    F.HideConfigPages()
    if not F.ammoVendorPanel then
        local p=CreateFrame('Frame','HunterToolsAmmoVendors',UIParent,'BackdropTemplate');F.ammoVendorPanel=p
        p.restock=true -- Find sellers by default, including equal/lower-tier ammo.
        p:SetSize(650,560);p:SetPoint('CENTER');p:SetFrameStrata('DIALOG');p:SetClampedToScreen(true)
        p:SetBackdrop({bgFile='Interface\\DialogFrame\\UI-DialogBox-Background',edgeFile='Interface\\DialogFrame\\UI-DialogBox-Border',edgeSize=24})
        local close=CreateFrame('Button',nil,p,'UIPanelCloseButton');close:SetPoint('TOPRIGHT',-4,-4);table.insert(UISpecialFrames,'HunterToolsAmmoVendors')
        local function label(y) local t=p:CreateFontString(nil,'OVERLAY','GameFontHighlightSmall');t:SetPoint('TOPLEFT',24,y);t:SetWidth(600);t:SetJustifyH('LEFT');return t end
        label(-25):SetText('Ammunition | Find a seller')
        p.status=label(-100);p.status:SetHeight(48);p.destination=label(-470)
        local function button(text,x,y,width,fn,secure)
            local b=CreateFrame('Button',nil,p,secure and 'UIPanelButtonTemplate,SecureActionButtonTemplate' or 'UIPanelButtonTemplate');b:SetSize(width,25);b:SetPoint('TOPLEFT',x,y);b:SetText(text);if not secure then b:SetScript('OnClick',fn) end;return b
        end
        p.zones=button('Current zone',24,-60,180,function() p.allZones=not p.allZones;p.page=1;p:Refresh() end)
        p.stock=button('Upgrades only',215,-60,180,function() p.restock=not p.restock;p.page=1;p:Refresh() end)
        p.clearVendorButton=button('Clear Vendor Mark',406,-60,218,function() F.ClearAmmoVendorMarker() end,true)
        if F.SetupAmmoVendorClearButton then F.SetupAmmoVendorClearButton(p.clearVendorButton) end
        p.rows={};for i=1,6 do
            local row=button('',24,-154-(i-1)*48,600,function(self) if self.vendor then F.SelectAmmoVendor(self.vendor);p:Refresh() end end,true)
            if F.SetupAmmoVendorMarkButton then
                F.SetupAmmoVendorMarkButton(row,function() return row.vendor end,function() p:Refresh() end)
            end
            row:SetHeight(42);p.rows[i]=row
        end
        button('Previous',24,-510,110,function() p.page=math.max(1,(p.page or 1)-1);p:Refresh() end)
        button('Next',145,-510,110,function() p.page=(p.page or 1)+1;p:Refresh() end)
        button('Back to upgrade advice',370,-510,254,function() p:Hide();F.OpenAmmoUpgradeSettings() end)
        function p:Refresh()
            local c,reason=F.AmmoUpgradeContext(not self.restock and not InCombatLockdown() and F.ScanAmmo(),true,self.restock)
            local rows=F.AmmoVendorRows(c,self.allZones,self.restock)
            local nearest
            if c and #rows==0 and not self.allZones then nearest=F.NearestAmmoVendor(c,self.restock);if nearest then rows={nearest} end end
            local pages=math.max(1,math.ceil(#rows/6));self.page=math.min(self.page or 1,pages)
            self.zones:SetText(self.allZones and 'All known zones' or 'Current zone');self.stock:SetText(self.restock and 'Include restocking' or 'Upgrades only')
            self.status:SetText(not c and reason or nearest and 'No matching seller here. Closest known: '..nearestDescription(nearest)..'. Select below to mark.' or #rows==0 and 'No known seller matches here. Try All known zones or Include restocking. Shops you visit update the built-in reference.' or ('%d sellers | Page %d/%d. Select a name to mark the map.'):format(#rows,self.page,pages))
            for i,b in ipairs(self.rows) do
                local row=rows[(self.page-1)*6+i];b.vendor=row and row.vendor
                if row then
                    local v=row.vendor;local info=query(C_Map and C_Map.GetMapInfo,v.mapID)
                    b:SetText(v.name..' - '..(info and info.name or v.zone or 'Map '..v.mapID)..' '..('%.1f, %.1f'):format(v.x*100,v.y*100)..'\n'..F.AmmoInfo(row.itemID)..(' | %.1f ammo DPS | '):format(row.entry.dps)..(v.observed and 'Visited shop' or 'Forever reference'));b:Show()
                else b:Hide() end
            end
            self.destination:SetText(F.ammoVendorDestination and 'Marked: '..F.ammoVendorDestination.name..' | Clears when you talk to them.' or 'No ammo seller marked.')
        end
        local elapsed=0;p:SetScript('OnUpdate',function(_,dt) elapsed=elapsed+dt;if elapsed>=2 then elapsed=0;p:Refresh() end end)
    end
    if F.FinishMenu then F.FinishMenu(F.ammoVendorPanel,650,560) end
    F.ammoVendorPanel:Show();F.ammoVendorPanel:Refresh()
end
local events=CreateFrame('Frame')
for _,event in ipairs({'GOSSIP_SHOW','MERCHANT_SHOW','MERCHANT_UPDATE'}) do
    if not C_EventUtils or not C_EventUtils.IsEventValid or C_EventUtils.IsEventValid(event) then events:RegisterEvent(event) end
end
events:SetScript('OnEvent',function(_,event) F.AmmoVendorInteraction(event) end)
local elapsed=0
local function updateMarker(_,dt)
    elapsed=elapsed+dt;if elapsed<.2 then return end;elapsed=0
    if F.ammoVendorDestination then F.UpdateAmmoVendorMarker() end
end
local markerUpdate=F.WrapPerformanceCallback and F.WrapPerformanceCallback('vendor minimap update',updateMarker) or updateMarker
setMarkerUpdates=function(active)
    elapsed=0
    events:SetScript('OnUpdate',active and markerUpdate or nil)
end
-- There is no per-frame callback while no destination is marked.
setMarkerUpdates(F.ammoVendorDestination~=nil)

if F.ProfileFrame then F.ProfileFrame(events,"AmmoVendors event","OnEvent",true) end
