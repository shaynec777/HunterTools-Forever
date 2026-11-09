local _,F=...
local beastFields={
 {'info','Family, level and tameability'},{'location','Location'},{'role','Role'},
 {'abilities','Abilities'},{'learned','Learned / missing rank labels'},
 {'familyTraining','Family training options'},{'diet','Eats / diet'},{'food','In bags'},
 {'abilityReference','Ability reference'},{'dietReference','Diet reference'},
 {'beastReference','Beast reference'},{'baseline','Classic baseline notice'},
}
function F.OpenTooltipSettings(kind)
    if InCombatLockdown() then F.Print('Open tooltip settings after combat.');return end
    F.HideConfigPages()
    local pet=kind=='pet'
    if not F.tooltipSettingsPanel then
        local p=CreateFrame('Frame','HunterToolsClassicTooltipSettings',UIParent,'BackdropTemplate');F.tooltipSettingsPanel=p
        p:SetSize(560,620);p:SetPoint('CENTER');p:SetFrameStrata('DIALOG');p:SetClampedToScreen(true)
        p:SetBackdrop({bgFile='Interface\\Buttons\\WHITE8X8',edgeFile='Interface\\DialogFrame\\UI-DialogBox-Border',edgeSize=18});p:SetBackdropColor(0.035,0.047,0.044,1)
        table.insert(UISpecialFrames,'HunterToolsClassicTooltipSettings')
        local close=CreateFrame('Button',nil,p,'UIPanelCloseButton');close:SetPoint('TOPRIGHT',-4,-4)
        p.title=F.MenuText(p,'',26,-26,505,'GameFontNormalLarge')
        p.help=F.MenuText(p,'Choose the lines added by HunterTools. Window settings are separate. Changes appear on the next hover; native WoW lines are unchanged.',26,-58,505);p.help:SetHeight(44)
        p.rows={}
        local function check(y)
            local c=CreateFrame('CheckButton',nil,p,'UICheckButtonTemplate');c:SetPoint('TOPLEFT',23,y)
            c.label=F.MenuText(p,'',58,y-6,465)
            c:SetScript('OnClick',function()
                if InCombatLockdown() then c:SetChecked(p.fields[c.key]~=false);return end
                p.fields[c.key]=c:GetChecked() and true or false
            end)
            return c
        end
        p.master=check(-106)
        for i=1,12 do p.rows[i]=check(-145-(i-1)*30) end
        local back=CreateFrame('Button',nil,p,'UIPanelButtonTemplate');back:SetSize(180,27);back:SetPoint('BOTTOM',0,25);back:SetText('Back to tools');back:SetScript('OnClick',F.OpenConfig)
    end
    local p=F.tooltipSettingsPanel
    local fields=pet and F.petStatusFields or beastFields
    local settings=pet and F.PetStatusSettings() or F.AnimalSettings().mouseover
    p.fields=pet and settings.tooltipFields or settings
    -- Location inherits the old grouped information preference once.
    if not pet and p.fields.location==nil then p.fields.location=p.fields.info~=false end
    p.title:SetText(pet and 'Your pet tooltip' or 'Wild beast tooltip')
    p.master.key=pet and 'tooltipEnabled' or 'enabled'
    p.master:SetChecked(settings[p.master.key]~=false);p.master.label:SetText('Enable HunterTools tooltip information')
    p.master:SetScript('OnClick',function()
        if InCombatLockdown() then p.master:SetChecked(settings[p.master.key]~=false);return end
        settings[p.master.key]=p.master:GetChecked() and true or false
    end)
    for i,row in ipairs(p.rows) do
        local field=fields[i];row:SetShown(field~=nil);row.label:SetShown(field~=nil)
        if field then row.key=field[1];row.label:SetText(field[2]);row:SetChecked(p.fields[row.key]~=false) end
    end
    if F.FinishMenu then F.FinishMenu(p,560,620) end
    p:Show()
end
