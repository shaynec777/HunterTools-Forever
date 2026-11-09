local function widget()
 local w={shown=false,scripts={},width=680,height=590,level=2,children={}}
 setmetatable(w,{__index=function() return function() end end})
 function w:SetScript(k,f) self.scripts[k]=f end
 function w:Show() self.shown=true end
 function w:Hide() self.shown=false end
 function w:SetShown(v) self.shown=v end
 function w:SetParent(v) self.parent=v end
 function w:SetSize(a,b) self.width=a;self.height=b end
 function w:GetWidth() return self.width end
 function w:GetHeight() return self.height end
 function w:GetFrameLevel() return self.level end
 function w:SetText(s) self.text=s end
 function w:SetChecked(v) self.checked=v end
 function w:GetChecked() return self.checked end
 function w:GetChildren() return unpack(self.children) end
 function w:SelectTab(v) self.tab=v end
 return w
end
CreateFrame=widget;UIParent=widget();UISpecialFrames={}
local combat=false;InCombatLockdown=function() return combat end
local F={VERSION='test',Print=function() end,enabled={}}
F.MenuText=function() return widget() end;F.MenuSection=widget;F.FinishMenu=function() end
F.SetToolEnabled=function(k,v) F.enabled[k]=v end;F.ToolEnabled=function(k) return F.enabled[k]~=false end
local pages={OpenFoodList='foodPanel',OpenFoodProtection='protectionPanel',OpenPetLists='petListPanel',OpenPetStatusSettings='petStatusSettingsPanel',OpenTooltipSettings='tooltipSettingsPanel',OpenPetAlertSettings='petAlertPanel',OpenAnimalSettings='animalSettingsPanel',OpenPetAbilityBrowser='petAbilityBrowser',OpenBeastJournal='beastJournalPanel',OpenTrackingSettings='trackingSettingsPanel',OpenAspectSettings='aspectSettingsPanel',OpenAmmoSettings='ammoPanel',OpenAmmoUpgradeSettings='ammoUpgradePanel',OpenWeaponComparisonSettings='weaponSettingsPanel',OpenRangeSettings='rangeSettingsPanel',OpenInstanceSettings='instanceSettingsPanel',OpenMobFinder='mobFinderPanel',OpenPlayerFinder='playerFinderPanel'}
F.HideConfigPages=function() if F.configPanel then F.configPanel:Hide() end;for _,key in pairs(pages) do if F[key] then F[key]:Hide() end end end
for method,key in pairs(pages) do local field=key;F[method]=function(arg) F.HideConfigPages();F[field]=F[field] or widget();F[field].argument=arg;F[field]:Show() end end
assert(loadfile('HunterTools/SettingsNavigation.lua'))('test',F)
for ci,category in ipairs(F.settingsCategories) do
 for pi,page in ipairs(category[2]) do
  F.OpenSettingsPage(ci,pi)
  local p=F.settingsShell;assert(p.shown and p.current.shown and p.current.parent==p.body)
  assert(p.path.text==category[1]..'  >  '..page[1])
  if page[2]=='OpenTooltipSettings' then assert(p.current.argument==page[4]) end
 end
end
F.OpenTooltipSettings('pet');assert(F.settingsShell.category==2 and F.settingsShell.page==2)
F.OpenFoodList();assert(F.foodPanel.tab=='feeding')
F.settingsShell.enable.checked=false;F.settingsShell.enable.scripts.OnClick();assert(F.enabled.food==false)
local prior=F.settingsShell.current;combat=true;F.OpenPlayerFinder();assert(F.settingsShell.current==prior)
combat=false;F.settingsShell:Hide();F.OpenConfig();assert(F.settingsShell.shown)
print('PASS: every sidebar page, shared content parent, breadcrumbs, legacy routes, food tab, explicit toggle, combat guard and reopening')
