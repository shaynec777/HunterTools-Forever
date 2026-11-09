local _,F=...
local white='Interface\\Buttons\\WHITE8X8'
-- Shared, lightweight presentation. No model loading or external artwork.
function F.MenuText(parent,text,x,y,width,font)
    local t=parent:CreateFontString(nil,'OVERLAY',font or 'GameFontHighlightSmall')
    t:SetPoint('TOPLEFT',x,y);t:SetWidth(width);t:SetJustifyH('LEFT');t:SetText(text)
    return t
end
function F.MenuSection(parent,x,y,w,h)
    local box=CreateFrame('Frame',nil,parent,'BackdropTemplate')
    box:SetPoint('TOPLEFT',x,y);box:SetSize(w,h)
    box:SetBackdrop({bgFile=white,edgeFile='Interface\\Tooltips\\UI-Tooltip-Border',edgeSize=12,insets={left=3,right=3,top=3,bottom=3}})
    box:SetBackdropColor(0.10,0.13,0.12,0.22);box:SetBackdropBorderColor(0.36,0.42,0.38,0.30)
    return box
end
function F.StyleMenuButton(b)
    if b.menuStyled then return end;b.menuStyled=true
    b:SetNormalTexture(white);b:GetNormalTexture():SetVertexColor(0.12,0.25,0.17,0.90)
    b:SetPushedTexture(white);b:GetPushedTexture():SetVertexColor(0.07,0.17,0.10,0.95)
    b:SetHighlightTexture(white);b:GetHighlightTexture():SetVertexColor(0.45,0.70,0.35,0.22)
    b:SetDisabledTexture(white);b:GetDisabledTexture():SetVertexColor(0.12,0.14,0.13,0.40)
    b:SetNormalFontObject('GameFontHighlight');b:SetDisabledFontObject('GameFontDisable')
end
function F.FinishMenu(p,w,h)
    p:SetClampedToScreen(true)
    p:SetBackdrop({bgFile='Interface\\Tooltips\\UI-Tooltip-Background',edgeFile='Interface\\Tooltips\\UI-Tooltip-Border',edgeSize=16,insets={left=4,right=4,top=4,bottom=4}})
    p:SetBackdropColor(0.055,0.075,0.067,0.80)
    p:SetBackdropBorderColor(0.48,0.53,0.46,0.50)
    local width,height=UIParent:GetWidth(),UIParent:GetHeight()
    if type(width)=='number' and type(height)=='number' then p:SetScale(math.min(1,(width-30)/w,(height-30)/h)) end
    local function buttons(parent)
        for _,child in ipairs({parent:GetChildren()}) do
            if child:GetObjectType()=='Button' and child:GetWidth()>40 then F.StyleMenuButton(child) end
            buttons(child)
        end
    end
    buttons(p)
    if p.alertPositionKey and F.RestoreAlertPosition then F.RestoreAlertPosition(p,p.alertPositionKey) end
end

local function coordinate(v)
    return (not issecretvalue or not issecretvalue(v)) and type(v)=='number' and v==v and math.abs(v)<100000
end
local function alertScale(p)
    local own,root=p:GetEffectiveScale(),UIParent:GetEffectiveScale()
    if coordinate(own) and coordinate(root) and own>0 and root>0 then return own/root end
    return 1
end
function F.RestoreAlertPosition(p,key)
    if InCombatLockdown() or p.alertDragging or not F.db then return end
    local positions=F.db.alertPositions
    local saved=type(positions)=='table' and positions[key]
    if type(saved)~='table' or not coordinate(saved.x) or not coordinate(saved.y) then return end
    local scale=alertScale(p)
    p:ClearAllPoints();p:SetPoint('CENTER',UIParent,'CENTER',saved.x/scale,saved.y/scale)
    return true
end
function F.MakeMovableAlert(p,key)
    p.alertPositionKey=key
    p:SetMovable(true);p:EnableMouse(true);p:RegisterForDrag('LeftButton')
    local function finish()
        if not p.alertDragging then return end
        if InCombatLockdown() then p.alertStopPending=true;return end
        p:StopMovingOrSizing();p.alertDragging=nil;p.alertStopPending=nil
        local x,y=p:GetCenter();local px,py=UIParent:GetCenter()
        if not F.db or not coordinate(x) or not coordinate(y) or not coordinate(px) or not coordinate(py) then return end
        local scale=alertScale(p)
        if type(F.db.alertPositions)~='table' then F.db.alertPositions={} end
        F.db.alertPositions[key]={x=x*scale-px,y=y*scale-py}
        F.RestoreAlertPosition(p,key)
    end
    p:SetScript('OnDragStart',function()
        if InCombatLockdown() or not IsShiftKeyDown() then return end
        p:StartMoving();p.alertDragging=true
    end)
    p:SetScript('OnDragStop',finish)
    p:HookScript('OnHide',finish)
    p:RegisterEvent('PLAYER_REGEN_ENABLED')
    p:HookScript('OnEvent',function(_,event) if event=='PLAYER_REGEN_ENABLED' and p.alertStopPending then finish() end end)
    F.RestoreAlertPosition(p,key)
end
