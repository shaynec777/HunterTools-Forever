local _,F=...
-- One navigation shell; retain existing settings logic and saved-variable schema.
local categories={
 {'Feeding',{
  {'Button & food selection','OpenFoodList','foodPanel','feeding','food','Enable pet feeding'},
  {'Food catalog','OpenFoodList','foodPanel','catalog'},
  {'Food protection','OpenFoodProtection','protectionPanel'},
  {'Hunger & supply alerts','OpenFoodList','foodPanel','feeding'},
  {'Saved pet lists','OpenPetLists','petListPanel'},
 }},
 {'My pet',{
  {'Status window','OpenPetStatusSettings','petStatusSettingsPanel',nil,'pet','Show pet status window'},
  {'Tooltip','OpenTooltipSettings','tooltipSettingsPanel','pet'},
  {'Health & death alerts','OpenPetAlertSettings','petAlertPanel'},
 }},
 {'Wild beasts',{
  {'Tooltip','OpenTooltipSettings','tooltipSettingsPanel','beast'},
  {'Target information','OpenAnimalSettings','animalSettingsPanel'},
  {'Abilities & teaching beasts','OpenPetAbilityBrowser','petAbilityBrowser',nil,'abilities','Enable pet ability browser'},
  {'Beast journal','OpenBeastJournal','beastJournalPanel'},
 }},
 {'Tracking & aspects',{
  {'Tracking button & reminder','OpenTrackingSettings','trackingSettingsPanel'},
  {'Aspect button & reminder','OpenAspectSettings','aspectSettingsPanel'},
 }},
 {'Ammunition & weapons',{
  {'Stock alerts','OpenAmmoSettings','ammoPanel','stock','ammo','Enable ammo stock alerts'},
  {'Ammo upgrades','OpenAmmoUpgradeSettings','ammoUpgradePanel'},
  {'Weapon comparisons (Experimental)','OpenWeaponComparisonSettings','weaponSettingsPanel'},
 }},
 {'Range & dungeon checks',{
  {'Target range window','OpenRangeSettings','rangeSettingsPanel',nil,'range','Show target range window'},
  {'Mend Pet range warning','OpenRangeSettings','rangeSettingsPanel'},
  {'Growl & Pack checks','OpenInstanceSettings','instanceSettingsPanel',nil,'instance','Enable dungeon checks'},
 }},
 {'Finders',{
  {'Mob Finder','OpenMobFinder','mobFinderPanel'},
  {'Player Finder','OpenPlayerFinder','playerFinderPanel'},
 }},
}
F.settingsCategories=categories
local originals={}
for _,category in ipairs(categories) do for _,page in ipairs(category[2]) do originals[page[2]]=F[page[2]] end end
local oldHide=F.HideConfigPages
F.HideConfigPages=function()
    local shell=F.settingsShell
    if F.settingsEmbedding and F.configPanel==shell then
        F.configPanel=nil;oldHide();F.configPanel=shell
    else oldHide() end
end
local function build()
    if F.settingsShell then return F.settingsShell end
    local p=CreateFrame('Frame','HunterToolsClassicSettings',UIParent,'BackdropTemplate')
    F.settingsShell=p;F.configPanel=p;p.checks={};p.statusLabels={};p.actions={}
    p:SetSize(1040,780);p:SetPoint('CENTER');p:SetFrameStrata('DIALOG')
    table.insert(UISpecialFrames,'HunterToolsClassicSettings')
    local close=CreateFrame('Button',nil,p,'UIPanelCloseButton');close:SetPoint('TOPRIGHT',-4,-4)
    F.MenuText(p,'HunterTools Classic',26,-24,500,'GameFontNormalLarge')
    p.versionLabel=F.MenuText(p,'',790,-26,200)
    p.path=F.MenuText(p,'',268,-65,730,'GameFontNormalLarge')
    local divider=F.MenuSection(p,248,-58,1,694)
    p.body=CreateFrame('Frame',nil,p);p.body:SetPoint('TOPLEFT',260,-118);p.body:SetSize(758,634)
    p.enable=CreateFrame('CheckButton',nil,p,'UICheckButtonTemplate');p.enable:SetPoint('TOPLEFT',265,-85)
    p.enableLabel=F.MenuText(p,'',301,-92,690)
    p.enable:SetScript('OnClick',function()
        local page=categories[p.category][2][p.page]
        if not page[5] then return end
        F.SetToolEnabled(page[5],p.enable:GetChecked() and true or false)
        p.enable:SetChecked(F.ToolEnabled(page[5]))
    end)
    p.categoryButtons={};p.pageButtons={}
    for i,category in ipairs(categories) do
        local index=i
        local b=CreateFrame('Button',nil,p,'UIPanelButtonTemplate');b:SetSize(216,31);b:SetPoint('TOPLEFT',24,-65-(i-1)*36);b:SetText(category[1])
        b:SetScript('OnClick',function() F.OpenSettingsPage(index,1) end);p.categoryButtons[i]=b
    end
    F.MenuText(p,'Pages',27,-338,210,'GameFontNormal')
    for i=1,5 do
        local index=i
        local b=CreateFrame('Button',nil,p,'UIPanelButtonTemplate');b:SetSize(216,38);b:SetPoint('TOPLEFT',24,-365-(i-1)*43)
        b:SetScript('OnClick',function() F.OpenSettingsPage(p.category,index) end);p.pageButtons[i]=b
    end
    F.MenuText(p,'Settings save immediately.\nExisting slash commands still work.',27,-656,210)
    p:SetScript('OnHide',function() if p.current then p.current:Hide() end end)
    return p
end
function F.OpenSettingsPage(categoryIndex,pageIndex)
    if InCombatLockdown() then F.Print('Open settings after combat.');return end
    local p=build();local category=categories[categoryIndex];local page=category and category[2][pageIndex]
    if not page then return end
    F.settingsEmbedding=true
    F.HideConfigPages()
    p.category=categoryIndex;p.page=pageIndex
    -- Existing pages keep their controls, events and independent view preferences.
    originals[page[2]](page[4])
    local child=F[page[3]]
    F.settingsEmbedding=nil
    if not child then return end
    p.current=child
    child:SetParent(p.body);child:ClearAllPoints();child:SetPoint('CENTER',p.body,'CENTER')
    local width,height=child:GetWidth(),child:GetHeight()
    if type(width)=='number' and type(height)=='number' and width>0 and height>0 then child:SetScale(math.min(1,750/width,626/height)) end
    child:SetFrameStrata('DIALOG');child:SetFrameLevel(p:GetFrameLevel()+3)
    child:SetMovable(false)
    child:SetBackdrop(nil) -- One translucent shell, rather than stacked page backgrounds.
    -- The shell owns closing/navigation; hide legacy close/back controls.
    for _,control in ipairs({child:GetChildren()}) do
        if control:GetObjectType()=='Button' then
            local text=control:GetText()
            local small=type(control:GetWidth())=='number' and control:GetWidth()<=40
            if (type(text)=='string' and text:match('^Back to ')) or (small and not text) then control:Hide() end
        end
    end
    if page[4] and page[2]~='OpenTooltipSettings' and child.SelectTab then child:SelectTab(page[4]) end
    p.path:SetText(category[1]..'  >  '..page[1]);p.versionLabel:SetText('Version '..(F.VERSION or 'unknown'))
    p.enable:SetShown(page[5]~=nil);p.enableLabel:SetShown(page[5]~=nil)
    if page[5] then p.enable:SetChecked(F.ToolEnabled(page[5]));p.enableLabel:SetText(page[6]) end
    for i,b in ipairs(p.categoryButtons) do b:SetText((i==categoryIndex and '|cffffd580' or '')..categories[i][1]..(i==categoryIndex and '|r' or '')) end
    for i,b in ipairs(p.pageButtons) do
        local sub=category[2][i];b:SetShown(sub~=nil)
        if sub then b:SetText((i==pageIndex and '|cffffd580' or '')..sub[1]..(i==pageIndex and '|r' or '')) end
    end
    F.FinishMenu(p,1040,780);child:Show();p:Show()
end
function F.OpenConfig()
    local p=F.settingsShell
    F.OpenSettingsPage(p and p.category or 1,p and p.page or 1)
end
-- Route old slash commands and in-page links into the same shell.
for method in pairs(originals) do
    local name=method
    F[name]=function(argument)
        for ci,category in ipairs(categories) do for pi,page in ipairs(category[2]) do
            if page[2]==name and (name~='OpenTooltipSettings' or page[4]==argument) then
                F.OpenSettingsPage(ci,pi);return
            end
        end end
    end
end
