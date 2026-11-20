local _,F=...
local setMarkerUpdates
local events=CreateFrame('Frame')
local markedGUID
local function public(v) return not issecretvalue or not issecretvalue(v) end
local function query(fn,...)
    if type(fn)~='function' then return end
    local ok,a,b,c=pcall(fn,...);if not ok then return end
    if not public(a) then a=nil end;if not public(b) then b=nil end;if not public(c) then c=nil end
    return a,b,c
end
local function findUnit(matches)
    for _,unit in ipairs({'target','mouseover','npc'}) do if matches(unit) then return unit end end
    local plates=query(C_NamePlate and C_NamePlate.GetNamePlates)
    if type(plates)=='table' then
        for _,plate in pairs(plates) do
            if query(plate.IsForbidden,plate)~=true and query(plate.IsShown,plate)~=false then
                local unit=query(plate.GetUnit,plate) or plate.namePlateUnitToken
                if (not issecretvalue or not issecretvalue(unit)) and type(unit)=='string' and unit:match('^nameplate%d+$') and matches(unit) then return unit end
            end
        end
    end
end
local function number(v) return public(v) and type(v)=='number' and v==v and math.abs(v)<1e8 end
local function point(map,x,y) return number(map) and map>0 and number(x) and number(y) and x>=0 and x<=1 and y>=0 and y<=1 end
local function npcID()
    local guid=query(UnitGUID,'npc')
    if type(guid)~='string' then return end
    return tonumber(guid:match('^Creature%-%d+%-%d+%-%d+%-%d+%-(%d+)%-'))
end
local function worldPoint(map,x,y)
    if not point(map,x,y) or not CreateVector2D then return end
    local instance,pos=query(C_Map and C_Map.GetWorldPosFromMapPos,map,CreateVector2D(x,y))
    if not number(instance) or not pos then return end
    local wx,wy=query(pos.GetXY,pos)
    if number(wx) and number(wy) then return instance,wx,wy end
end
function F.TrainerRows(kind,allZones)
    local rows={}
    if InCombatLockdown() then return rows end
    local map=query(C_Map and C_Map.GetBestMapForUnit,'player')
    local pos=query(C_Map and C_Map.GetPlayerMapPosition,map,'player')
    local x,y;if pos then x,y=query(pos.GetXY,pos) end
    local instance,px,py=worldPoint(map,x,y)
    local faction=query(UnitFactionGroup,'player')
    local level=query(UnitLevel,'player')
    for _,v in ipairs(F.trainerCatalog or {}) do
        if v.kind==kind and v.faction==faction and (allZones or v.mapID==map) and (not v.starter or number(level) and level<=6) then
            local vi,vx,vy=worldPoint(v.mapID,v.x,v.y)
            local distance=instance and vi==instance and math.sqrt((px-vx)^2+(py-vy)^2) or nil
            rows[#rows+1]={trainer=v,distance=distance}
        end
    end
    table.sort(rows,function(a,b)
        if a.distance~=b.distance then return a.distance~=nil and (b.distance==nil or a.distance<b.distance) end
        return a.trainer.id<b.trainer.id
    end)
    return rows
end
function F.ClearTrainerMarker()
    F.trainerDestination=nil
    if setMarkerUpdates then setMarkerUpdates(false) end
    if F.trainerPin then F.trainerPin:Hide() end
    if F.trainerMiniPin then F.trainerMiniPin:Hide() end
end
function F.SelectTrainer(v)
    if InCombatLockdown() or type(v)~='table' or not point(v.mapID,v.x,v.y) then return end
    F.trainerDestination=v
    setMarkerUpdates(true)
    if OpenWorldMap then OpenWorldMap(v.mapID)
    elseif WorldMapFrame then WorldMapFrame:Show();if WorldMapFrame.SetMapID then WorldMapFrame:SetMapID(v.mapID) end end
    F.UpdateTrainerMarker()
    F.Print('Trainer: '..v.name..'. Red marker clears when you talk to this NPC.')
    return true
end
local function inRange(v)
    return findUnit(function(unit)
        local guid=query(UnitGUID,unit)
        local id=type(guid)=='string' and tonumber(guid:match('^Creature%-%d+%-%d+%-%d+%-%d+%-(%d+)%-'))
        local range=id==v.id and query(CheckInteractDistance,unit,1)
        return range==true or range==1
    end)
end
-- Secure hardware-click actions, following CraftingTools 0.8.7. No retries.
function F.SetupNPCMarkButton(button,selection,selectAction,rememberMark)
    button:RegisterForClicks('LeftButtonUp');button:SetAttribute('useOnKeyDown',false)
    button:SetScript('PreClick',function(self)
        if InCombatLockdown() then return end
        local v=selection();self.trainer=v;self.markGUID=nil
        local macro
        if v then
            local unit=inRange(v)
            if unit then
                self.markGUID=query(UnitGUID,unit)
                macro=unit=='target' and '/tm [exists,nocombat] !7' or '/tm [@'..unit..',exists,nocombat] !7'
                -- Mark the exact, prevalidated unit before acquiring the target.
                -- Targeting first could invalidate a target/mouseover unit token.
                if type(v.name)=='string' and not v.name:find('[%c%[%];|]') then
                    macro=macro..'\n/targetexact [nocombat] '..v.name
                end
            elseif type(v.name)=='string' and not v.name:find('[%c%[%];|]') then
                macro='/targetexact [nocombat] '..v.name
            end
        end
        self:SetAttribute('type',macro and 'macro' or nil);self:SetAttribute('macrotext',macro)
    end)
    button:SetScript('PostClick',function(self)
        if InCombatLockdown() then return end
        self:SetAttribute('type',nil);self:SetAttribute('macrotext',nil)
        if self.markGUID and rememberMark then rememberMark(self.markGUID) end
        if self.trainer then selectAction(self.trainer)
        end
    end)
end
function F.SetupTrainerMarkButton(button,selection)
    F.SetupNPCMarkButton(button,selection,function(v) F.SelectTrainer(v) end,function(guid) markedGUID=guid end)
end
function F.SetupTrainerClearButton(button)
    button:RegisterForClicks('LeftButtonUp');button:SetAttribute('useOnKeyDown',false)
    button:SetScript('PreClick',function(self)
        if InCombatLockdown() then return end
        local unit=markedGUID and findUnit(function(u) return query(UnitGUID,u)==markedGUID end)
        local index=unit and query(GetRaidTargetIndex,unit)
        local macro
        if unit and (index==7 or index==nil) then
            macro=unit=='target' and '/tm [nocombat] 0' or '/tm [@'..unit..',exists,nocombat] 0'
        end
        self.found=macro~=nil;self:SetAttribute('type',macro and 'macro' or nil);self:SetAttribute('macrotext',macro)
    end)
    button:SetScript('PostClick',function(self)
        if InCombatLockdown() then return end
        self:SetAttribute('type',nil);self:SetAttribute('macrotext',nil)
        if self.found then markedGUID=nil elseif markedGUID then F.Print('Target the marked trainer and press Clear marker again to remove its red X.') end
        F.ClearTrainerMarker()
    end)
end
function F.UpdateTrainerMinimap()
    local pin=F.trainerMiniPin;if pin then pin:Hide() end
    local v=F.trainerDestination
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
        pin=CreateFrame('Frame',nil,Minimap,'BackdropTemplate');F.trainerMiniPin=pin;pin:SetSize(20,20)
        pin:SetBackdrop({bgFile='Interface\\Buttons\\WHITE8X8',edgeFile='Interface\\Buttons\\WHITE8X8',edgeSize=2})
        pin:SetBackdropColor(.01,.04,.06,.95);pin:SetBackdropBorderColor(1,.2,.2,1)
        pin.texture=pin:CreateTexture(nil,'OVERLAY');pin.texture:SetSize(14,14);pin.texture:SetPoint('CENTER');pin.texture:SetTexture('Interface\\Icons\\Ability_Hunter_BeastTraining')
        pin:EnableMouse(true)
        pin:SetScript('OnEnter',function(self)
            local destination=F.trainerDestination
            if not destination or not GameTooltip then return end
            GameTooltip:SetOwner(self,'ANCHOR_LEFT');GameTooltip:AddLine('Trainer: '..destination.name,1,.35,.35)
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
function F.UpdateTrainerMarker()
    F.UpdateTrainerMinimap()
    local pin=F.trainerPin;if pin then pin:Hide() end
    local v=F.trainerDestination;local map=WorldMapFrame
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
        pin=CreateFrame('Frame',nil,canvas);F.trainerPin=pin;pin:SetSize(1,1)
        pin.badge=CreateFrame('Frame',nil,pin,'BackdropTemplate');pin.badge:SetSize(34,34);pin.badge:SetPoint('CENTER',pin,'CENTER')
        pin.badge:SetBackdrop({bgFile='Interface\\Buttons\\WHITE8X8',edgeFile='Interface\\Buttons\\WHITE8X8',edgeSize=2})
        pin.badge:SetBackdropColor(.01,.04,.06,.95);pin.badge:SetBackdropBorderColor(1,.2,.2,1)
        pin.texture=pin.badge:CreateTexture(nil,'OVERLAY');pin.texture:SetSize(26,26);pin.texture:SetPoint('CENTER');pin.texture:SetTexture('Interface\\Icons\\Ability_Hunter_BeastTraining')
        pin.caption=CreateFrame('Frame',nil,pin.badge,'BackdropTemplate');pin.caption:SetSize(190,24);pin.caption:SetPoint('BOTTOM',pin.badge,'TOP',0,3)
        pin.caption:SetBackdrop({bgFile='Interface\\Buttons\\WHITE8X8',edgeFile='Interface\\Buttons\\WHITE8X8',edgeSize=1})
        pin.caption:SetBackdropColor(0,0,0,.82);pin.caption:SetBackdropBorderColor(1,.2,.2,1)
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
    pin.label:SetText('|cffff6666'..v.name..'|r'..(v.shop and '\n|cffffe6aa'..v.shop..'|r' or ''))
    pin:Show()
end
function F.OpenTrainers()
    if InCombatLockdown() then F.Print('Open trainers after combat.');return end
    F.HideConfigPages()
    local p=F.trainerPanel
    if not p then
        p=CreateFrame('Frame','HunterToolsTrainers',UIParent,'BackdropTemplate');F.trainerPanel=p
        p:SetSize(650,560);p:SetPoint('CENTER');p:SetFrameStrata('DIALOG');p:SetClampedToScreen(true)
        p:SetBackdrop({bgFile='Interface\\DialogFrame\\UI-DialogBox-Background',edgeFile='Interface\\DialogFrame\\UI-DialogBox-Border',edgeSize=24})
        local close=CreateFrame('Button',nil,p,'UIPanelCloseButton');close:SetPoint('TOPRIGHT',-4,-4)
        table.insert(UISpecialFrames,'HunterToolsTrainers')
        local function label(y) local t=p:CreateFontString(nil,'OVERLAY','GameFontHighlightSmall');t:SetPoint('TOPLEFT',24,y);t:SetWidth(600);t:SetJustifyH('LEFT');return t end
        label(-25):SetText('Mark Trainer | Red map and minimap markers')
        p.status=label(-100);p.status:SetHeight(48);p.destination=label(-465)
        local function button(text,x,y,w,secure)
            local b=CreateFrame('Button',nil,p,secure and 'UIPanelButtonTemplate,SecureActionButtonTemplate' or 'UIPanelButtonTemplate')
            b:SetSize(w,25);b:SetPoint('TOPLEFT',x,y);b:SetText(text);return b
        end
        p.kind='hunter'
        p.kindButton=button('Hunter trainers',24,-60,180)
        p.kindButton:SetScript('OnClick',function() if InCombatLockdown() then return end;p.kind=p.kind=='hunter' and 'pet' or 'hunter';p.page=1;p:Refresh() end)
        p.zones=button('Current zone',215,-60,180)
        p.zones:SetScript('OnClick',function() if InCombatLockdown() then return end;p.allZones=not p.allZones;p.page=1;p:Refresh() end)
        local clear=button('Clear marker',406,-60,218,true);F.SetupTrainerClearButton(clear)
        p.rows={}
        for i=1,6 do
            local row=button('',24,-154-(i-1)*48,600,true);row:SetHeight(42);p.rows[i]=row
            F.SetupTrainerMarkButton(row,function() return row.trainer end)
        end
        local previous=button('Previous',24,-510,110);previous:SetScript('OnClick',function() if InCombatLockdown() then return end;p.page=math.max(1,(p.page or 1)-1);p:Refresh() end)
        local nextPage=button('Next',145,-510,110);nextPage:SetScript('OnClick',function() if InCombatLockdown() then return end;p.page=(p.page or 1)+1;p:Refresh() end)
        local nearest=button('Mark nearest trainer',300,-510,324,true)
        F.SetupTrainerMarkButton(nearest,function()
            local rows=F.TrainerRows(p.kind,true)
            return rows[1] and rows[1].distance and rows[1].trainer
        end)
        function p:Refresh()
            if InCombatLockdown() then return end
            local rows=F.TrainerRows(self.kind,self.allZones)
            local nearestFallback=false
            if #rows==0 and not self.allZones then
                local all=F.TrainerRows(self.kind,true)
                if all[1] and all[1].distance then rows={all[1]};nearestFallback=true end
            end
            local pages=math.max(1,math.ceil(#rows/6));self.page=math.min(self.page or 1,pages)
            self.kindButton:SetText(self.kind=='hunter' and 'Hunter trainers' or 'Pet trainers')
            self.zones:SetText(self.allZones and 'All known zones' or 'Current zone')
            self.status:SetText(nearestFallback and 'No known trainer here. Closest known trainer on this continent:' or ('%d trainers | Page %d/%d. Select to mark. Distances are straight-line.'):format(#rows,self.page,pages))
            for i,b in ipairs(self.rows) do
                local row=rows[(self.page-1)*6+i];b.trainer=row and row.trainer
                if row then
                    local v=row.trainer;local info=query(C_Map and C_Map.GetMapInfo,v.mapID)
                    b:SetText(v.name..' - '..(info and info.name or 'Map '..v.mapID)..(' %.1f, %.1f'):format(v.x*100,v.y*100)..(row.distance and ('\n~%d yd straight-line'):format(row.distance) or '\nDistance unavailable'));b:Show()
                else b:Hide() end
            end
            self.destination:SetText(F.trainerDestination and 'Marked: '..F.trainerDestination.name..' | Clears when you talk to them.' or 'No trainer marked. X: interaction range only; target first or press Mark again.')
        end
    end
    if F.FinishMenu then F.FinishMenu(p,650,560) end
    p:Show();p:Refresh()
end
local elapsed=0
setMarkerUpdates=function(active)
    elapsed=0
    events:SetScript('OnUpdate',active and function(_,dt)
        elapsed=elapsed+dt;if elapsed<.2 then return end;elapsed=0
        if F.trainerDestination then F.UpdateTrainerMarker() end
    end or nil)
end
for _,event in ipairs({'GOSSIP_SHOW','TRAINER_SHOW'}) do
    if not C_EventUtils or not C_EventUtils.IsEventValid or C_EventUtils.IsEventValid(event) then events:RegisterEvent(event) end
end
events:SetScript('OnEvent',function()
    if F.trainerDestination and npcID()==F.trainerDestination.id then F.ClearTrainerMarker() end
end)
setMarkerUpdates(false)
