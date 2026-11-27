local _,F=...
BINDING_HEADER_HUNTERTOOLS="HunterTools"
_G["BINDING_NAME_CLICK HunterToolsEquipWeaponAmmo:LeftButton"]="HunterTools: Cycle ammo"
local function public(v) return not issecretvalue or not issecretvalue(v) end
local function read(fn,...)
    if type(fn)~='function' then return end
    local ok,a,b,c,d,e,f,g=pcall(fn,...)
    if not ok then return end
    return a,b,c,d,e,f,g
end
local function id(v) return public(v) and type(v)=='number' and v>0 and v%1==0 end
local names={[2]='Bow',[3]='Gun',[18]='Crossbow'}
function F.AutoAmmoSettings()
    local a=F.db.ammo
    if type(a.autoEquip)~='boolean' then a.autoEquip=false end
    if type(a.showSwitchButton)~='boolean' then a.showSwitchButton=true end
    if type(a.preferredAmmo)~='table' then a.preferredAmmo={} end
    if a.switchMessage~='chat' and a.switchMessage~='both' and a.switchMessage~='off' then a.switchMessage='banner' end
    return a
end
function F.AutoAmmoWeapon()
    local weapon=read(GetInventoryItemID,'player',18)
    if not id(weapon) then return end
    local _,_,_,_,_,class,kind=read(C_Item and C_Item.GetItemInfoInstant,weapon)
    if public(class) and public(kind) and class==2 and names[kind] then return kind,weapon end
end
local function compatible(ammo,weaponKind)
    if not id(ammo) then return false end
    local entry=F.ammoCatalog and F.ammoCatalog[ammo]
    local class,kind=6,entry and entry.kind
    if not kind then local _,_,_,_,_,c,k=read(C_Item and C_Item.GetItemInfoInstant,ammo);class,kind=c,k end
    return public(class) and public(kind) and class==6 and kind==(weaponKind==3 and 3 or 2)
end
-- Configure outside combat; secure macro conditions select the current weapon
-- at the user's click, without changing protected attributes during combat.
function F.AutoAmmoCombatMacro()
    local a=F.AutoAmmoSettings();local lines={}
    for _,kind in ipairs({2,3,18}) do
        local ammo=a.preferredAmmo[kind]
        if compatible(ammo,kind) then
            local subclass=read(C_Item and C_Item.GetItemSubClassInfo or GetItemSubClassInfo,2,kind)
            if not public(subclass) or type(subclass)~='string' then subclass=({[2]='Bows',[3]='Guns',[18]='Crossbows'})[kind] end
            if not subclass:find('[%[%];\n\r]') then lines[#lines+1]='/equip [equipped:'..subclass..'] item:'..ammo end
        end
    end
    return table.concat(lines,'\n')
end
function F.AutoAmmoCycleChoices()
    local choices={};local a=F.AutoAmmoSettings()
    for _,kind in ipairs({3,2,18}) do
        local ammo=a.preferredAmmo[kind]
        if compatible(ammo,kind) then choices[#choices+1]={kind=kind,id=ammo} end
    end
    return choices
end
function F.AmmoSwitchMessage(message)
    local mode=F.AutoAmmoSettings().switchMessage
    if mode=='chat' or mode=='both' then F.Print(message) end
    if (mode=='banner' or mode=='both') and RaidNotice_AddMessage and RaidWarningFrame then
        RaidNotice_AddMessage(RaidWarningFrame,message,{r=1,g=0.8,b=0.2},4)
    end
end
function F.AnnounceAmmoEquipped(ammo)
    F.AmmoSwitchMessage('Ammo equipped: '..F.AmmoInfo(ammo))
end
function F.VerifyAmmoCycle(button)
    local requested=read(button.GetAttribute,button,'cycle-request')
    if not id(requested) then return end
    local context=F.characterContextKey
    local token={};F.autoAmmoVerifyToken=token
    local attempt=0
    local function verify()
        if context~=F.characterContextKey or not F.db or F.autoAmmoVerifyToken~=token then return end
        local kind=F.AutoAmmoWeapon()
        if kind and not compatible(requested,kind) then
            F.AmmoSwitchMessage('Ammo/Weapon mismatch');F.autoAmmoVerifyToken=nil;return
        end
        local equipped=read(GetInventoryItemID,'player',0)
        if id(equipped) and equipped==requested then
            F.AnnounceAmmoEquipped(equipped);F.autoAmmoVerifyToken=nil;return
        end
        attempt=attempt+1
        if attempt<3 and C_Timer and C_Timer.After then C_Timer.After(0.4,verify)
        else F.AmmoSwitchMessage('Ammo did not change. Check stock, locks and level requirements.');F.autoAmmoVerifyToken=nil end
    end
    if C_Timer and C_Timer.After then C_Timer.After(0.2,verify) else verify() end
end
F.autoAmmoCycleSnippet=[[
    if down then return false end
    local count=self:GetAttribute('cycle-count') or 0
    if count<1 then self:SetAttribute('type',nil);return end
    local index=(self:GetAttribute('cycle-index') or 0)%count+1
    local ammo=self:GetAttribute('cycle-item-'..index)
    if not ammo then self:SetAttribute('type',nil);return end
    self:SetAttribute('cycle-index',index)
    self:SetAttribute('cycle-request',ammo)
    self:SetAttribute('macrotext','/equip item:'..ammo)
    self:SetAttribute('type','macro')
]]
function F.RefreshAutoAmmoButton()
    if InCombatLockdown() or not F.db then return end
    local a=F.AutoAmmoSettings();local macro=F.AutoAmmoCombatMacro()
    local p=F.autoAmmoCombatButton
    if not p and a.autoEquip and macro~='' then
        p=CreateFrame('Button','HunterToolsEquipWeaponAmmo',UIParent,'UIPanelButtonTemplate,SecureActionButtonTemplate,SecureHandlerBaseTemplate');F.autoAmmoCombatButton=p
        p:SetSize(80,22);p:SetPoint('CENTER',UIParent,'CENTER',0,-290);p:SetText('Ammo')
        p:RegisterForClicks('AnyUp');p:SetAttribute('useOnKeyDown',false);p:SetMovable(true);p:EnableMouse(true);p:SetClampedToScreen(true);p:RegisterForDrag('LeftButton')
        p:SetScript('OnDragStart',function() if IsShiftKeyDown() and not InCombatLockdown() then p:StartMoving() end end)
        p:SetScript('OnDragStop',function() if not InCombatLockdown() then p:StopMovingOrSizing() end end)
        p:SetScript('OnEnter',function()
            GameTooltip:SetOwner(p,'ANCHOR_RIGHT');GameTooltip:SetText('Equip preferred ammunition')
            GameTooltip:AddLine('Click to cycle saved Gun, Bow, Crossbow ammunition. Does not swap weapons. Uses a protected click during combat. Shift-drag outside combat to move.',1,1,1,true);GameTooltip:Show()
        end)
        p:SetScript('OnLeave',function() GameTooltip:Hide() end)
        if SecureHandlerWrapScript then
            SecureHandlerWrapScript(p,'OnClick',p,F.autoAmmoCycleSnippet)
            p.cycleReady=true
        end
        p:SetScript('PostClick',function(self) F.VerifyAmmoCycle(self) end)
    end
    if p then
        p:SetAttribute('type',nil);p:SetAttribute('macrotext',nil);p:SetAttribute('cycle-count',0);p:SetAttribute('cycle-request',nil)
        if a.autoEquip and macro~='' then
            local choices=F.AutoAmmoCycleChoices();local current=read(GetInventoryItemID,'player',0);local index=0
            for i=1,3 do p:SetAttribute('cycle-item-'..i,nil) end
            for i,row in ipairs(choices) do p:SetAttribute('cycle-item-'..i,row.id);if index==0 and public(current) and current==row.id then index=i end end
            p:SetAttribute('cycle-count',#choices);p:SetAttribute('cycle-index',index);p:SetAttribute('cycle-request',nil)
            p:SetAttribute('macrotext',macro);p:SetAttribute('type','macro')
            -- Keep the secure click target shown for CLICK key bindings, but
            -- remove both its visual presence and mouse hitbox in keybind-only mode.
            p:SetAlpha(a.showSwitchButton and 1 or 0);p:EnableMouse(a.showSwitchButton);p:Show()
        else p:Hide() end
    end
end
function F.RememberAutoAmmo()
    if InCombatLockdown() then return end
    local kind=F.AutoAmmoWeapon();local ammo=read(GetInventoryItemID,'player',0)
    if not kind or not compatible(ammo,kind) then F.Print('Equip a gun, bow or crossbow and matching ammunition first.');return end
    F.AutoAmmoSettings().preferredAmmo[kind]=ammo
    F.RefreshAutoAmmoButton()
    F.Print(names[kind]..' ammunition saved: '..F.AmmoInfo(ammo))
end
local function notice(message)
    if F.autoAmmoNotice~=message then F.autoAmmoNotice=message;F.Print(message) end
end
function F.TryAutoAmmo()
    if not F.db or not F.AutoAmmoSettings().autoEquip then F.autoAmmoPending=nil;return end
    if InCombatLockdown() then return end
    local kind,weapon=F.AutoAmmoWeapon()
    if not kind then return end -- item data may still be loading
    local ammo=F.AutoAmmoSettings().preferredAmmo[kind]
    if not compatible(ammo,kind) then F.autoAmmoPending=nil;return end
    local equipped=read(GetInventoryItemID,'player',0)
    if not public(equipped) then return end
    if equipped==ammo then F.autoAmmoPending=nil;return end
    local cursor=read(CursorHasItem)
    if not public(cursor) then return end
    if cursor then notice('Ammo switch waits: finish moving the item on your cursor.');return end
    local found,locked=false,false
    for bag=0,(NUM_TOTAL_EQUIPPED_BAG_SLOTS or NUM_BAG_SLOTS or 4) do
        local slots=read(C_Container and C_Container.GetContainerNumSlots,bag)
        if not public(slots) or type(slots)~='number' then return end
        for slot=1,slots do
            local item=read(C_Container.GetContainerItemInfo,bag,slot)
            if public(item) and type(item)=='table' and public(item.itemID) and item.itemID==ammo then
                if public(item.isLocked) and not item.isLocked and public(item.stackCount) and type(item.stackCount)=='number' and item.stackCount>0 then found=true
                else locked=true end
            end
        end
    end
    if not found then notice(locked and 'Preferred ammo is locked; switch waits for inventory to settle.' or 'Preferred ammo is not in your bags.');return end
    local equip=C_Item and C_Item.EquipItemByName or EquipItemByName
    if type(equip)~='function' then F.Print('Automatic ammo equipping is unavailable on this client.');F.autoAmmoPending=nil;return end
    F.autoAmmoPending=nil
    local ok=pcall(equip,ammo)
    if not ok then F.Print('Ammo could not be equipped. Equip it manually.');return end
    local function verify()
        if not F.db or InCombatLockdown() then return end
        local currentKind,currentWeapon=F.AutoAmmoWeapon()
        if currentWeapon~=weapon or currentKind~=kind then return end
        local current=read(GetInventoryItemID,'player',0)
        if public(current) and current==ammo then F.ammoDirty=true;F.AnnounceAmmoEquipped(ammo)
        else F.Print('Preferred ammo was not equipped; check its level requirement or equip it manually.') end
    end
    if C_Timer and C_Timer.After then C_Timer.After(0.2,verify) else verify() end
end
function F.QueueAutoAmmo()
    if not F.db then return end
    F.RefreshAutoAmmoButton()
    if not F.AutoAmmoSettings().autoEquip then return end
    F.autoAmmoPending=true
    if F.autoAmmoQueued then return end
    F.autoAmmoQueued=true
    local function run() F.autoAmmoQueued=nil;if F.autoAmmoPending then F.TryAutoAmmo() end end
    if C_Timer and C_Timer.After then C_Timer.After(0.2,run) else run() end
end
function F.OpenAutoAmmoSettings()
    if InCombatLockdown() then F.Print('Open settings after combat.');return end
    if F.HideConfigPages then F.HideConfigPages() end
    if not F.autoAmmoPanel then
        local p=CreateFrame('Frame','HunterToolsAutoAmmo',UIParent,'BackdropTemplate');F.autoAmmoPanel=p
        p:SetSize(540,450);p:SetPoint('CENTER');p:SetFrameStrata('DIALOG')
        p:SetBackdrop({bgFile='Interface\\DialogFrame\\UI-DialogBox-Background',edgeFile='Interface\\DialogFrame\\UI-DialogBox-Border',edgeSize=24})
        local close=CreateFrame('Button',nil,p,'UIPanelCloseButton');close:SetPoint('TOPRIGHT',-4,-4)
        p.text=p:CreateFontString(nil,'OVERLAY','GameFontHighlight');p.text:SetPoint('TOPLEFT',25,-55);p.text:SetWidth(490);p.text:SetJustifyH('LEFT')
        local c=CreateFrame('CheckButton',nil,p,'UICheckButtonTemplate');p.enabled=c;c:SetPoint('TOPLEFT',25,-20)
        local label=c:CreateFontString(nil,'OVERLAY','GameFontNormal');label:SetPoint('LEFT',c,'RIGHT');label:SetText('Equip preferred ammo when weapon changes')
        c:SetScript('OnClick',function() if InCombatLockdown() then c:SetChecked(F.AutoAmmoSettings().autoEquip);return end;F.AutoAmmoSettings().autoEquip=c:GetChecked() and true or false;if F.db.ammo.autoEquip then F.QueueAutoAmmo() else F.autoAmmoPending=nil;F.RefreshAutoAmmoButton() end end)
        local function button(text,x,y,fn)
            local b=CreateFrame('Button',nil,p,'UIPanelButtonTemplate');b:SetSize(235,26);b:SetPoint('TOPLEFT',x,y);b:SetText(text);b:SetScript('OnClick',function() if not InCombatLockdown() then fn();p:Refresh() end end)
        end
        p.showButton=CreateFrame('CheckButton',nil,p,'UICheckButtonTemplate');p.showButton:SetPoint('TOPLEFT',25,-375)
        local showLabel=p.showButton:CreateFontString(nil,'OVERLAY','GameFontHighlight');showLabel:SetPoint('LEFT',p.showButton,'RIGHT');showLabel:SetText('Show ammo button (keybind works when off)')
        p.showButton:SetScript('OnClick',function()
            if InCombatLockdown() then p.showButton:SetChecked(F.AutoAmmoSettings().showSwitchButton);return end
            F.AutoAmmoSettings().showSwitchButton=p.showButton:GetChecked() and true or false;F.RefreshAutoAmmoButton()
        end)
        local modes={'banner','chat','both','off'}
        p.message=CreateFrame('Button',nil,p,'UIPanelButtonTemplate');p.message:SetSize(490,26);p.message:SetPoint('TOPLEFT',25,-208)
        p.message:SetScript('OnClick',function()
            if InCombatLockdown() then return end
            local a=F.AutoAmmoSettings();for i,mode in ipairs(modes) do if a.switchMessage==mode then a.switchMessage=modes[i%#modes+1];break end end;p:Refresh()
        end)
        local help=p:CreateFontString(nil,'OVERLAY','GameFontHighlightSmall');help:SetPoint('TOPLEFT',25,-322);help:SetWidth(490);help:SetText('Key Bindings > AddOns > HunterTools: Cycle ammo. Choices must be saved before combat.')
        button('Remember equipped ammo',25,-245,F.RememberAutoAmmo)
        button('Clear saved ammo',280,-245,function() F.AutoAmmoSettings().preferredAmmo={};F.autoAmmoPending=nil;F.RefreshAutoAmmoButton() end)
        button('Equip preferred ammo now',25,-280,F.QueueAutoAmmo)
        button('Back to ammo',280,-280,function() p:Hide();F.OpenAmmoSettings() end)
        function p:Refresh()
            local a=F.AutoAmmoSettings();self.enabled:SetChecked(a.autoEquip);self.showButton:SetChecked(a.showSwitchButton)
            local lines={'Equip the desired weapon and ammo, then click Remember. Each weapon type has its own choice. Automatic switches wait until combat ends. The button/key cycles saved Gun, Bow, Crossbow ammo in combat; it does not swap weapons. Missing ammo is never substituted.',''}
            for _,kind in ipairs({2,3,18}) do local ammo=a.preferredAmmo[kind];lines[#lines+1]=names[kind]..': '..(id(ammo) and F.AmmoInfo(ammo) or 'Not set') end
            self.text:SetText(table.concat(lines,'\n'))
            self.message:SetText('Ammo switch message: '..({banner='Banner',chat='Chat',both='Banner + chat',off='Off'})[a.switchMessage])
        end
    end
    F.autoAmmoPanel:Refresh();F.autoAmmoPanel:Show()
end
local frame=CreateFrame('Frame')
for _,event in ipairs({'PLAYER_EQUIPMENT_CHANGED','PLAYER_REGEN_ENABLED','PLAYER_ENTERING_WORLD','BAG_UPDATE_DELAYED','GET_ITEM_INFO_RECEIVED','ITEM_LOCK_CHANGED','CURSOR_CHANGED'}) do frame:RegisterEvent(event) end
frame:SetScript('OnEvent',function(_,event,slot)
    if event=='PLAYER_EQUIPMENT_CHANGED' then if public(slot) and slot==18 then F.autoAmmoNotice=nil;F.QueueAutoAmmo() end
    elseif event=='PLAYER_ENTERING_WORLD' then F.QueueAutoAmmo()
    elseif event=='PLAYER_REGEN_ENABLED' then F.RefreshAutoAmmoButton();if F.autoAmmoPending then F.QueueAutoAmmo() end
    elseif F.autoAmmoPending then F.QueueAutoAmmo() end
end)
