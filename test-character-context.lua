local F={Print=function() end}
local hc,rp,pvp=false,false,false
local guid='Player-91-000000AB'
Enum={GameRule={HardcoreRuleset=1,RPRuleset=2,PvPRuleset=3}}
C_GameRules={IsGameRuleActive=function(id) return ({hc,rp,pvp})[id] end}
UnitGUID=function(unit) assert(unit=='player');return guid end
InCombatLockdown=function() return false end
local secret={};issecretvalue=function(v) return v==secret end
assert(loadfile('HunterTools/Core.lua'))('test',F)
local frame={events={},scripts={}}
function frame:RegisterEvent(e) self.events[e]=true end
function frame:SetScript(k,v) self.scripts[k]=v end
CreateFrame=function() return frame end
assert(loadfile('HunterTools/CharacterContext.lua'))('test',F)
F.ammoCatalog={[2512]={name='Arrow'}};F.foodCatalog={[117]={name='Meat'}}
HunterToolsDB={x=123,mute=true,foodOrder='low',petStatus={enabled=true},
 petFoodLists={['pet:bear:bear']={name='Bear',family='Bear',blacklist={[117]=true},whitelist={}}},
 knownPetAbilities={bite=8},petLastFeeds={pet={food='legacy'}},
 ammo={enabled=true,selected={[2512]=true},discovered={[9999]={name='Legacy'}},lastEquipped=9999},
 beastJournal={enabled=false,records={[10]={name='Legacy beast'}}},
 playerFinder={sound=false,watches={{name='Legacy player'}}}}
local root=HunterToolsDB
F.LoadSettings()
local pve=F.characterContextKey;assert(pve and pve:find('rules:000:',1,true))
assert(F.db.x==123 and F.db.mute and F.db.petStatus.enabled and F.db.ammo.enabled)
assert(F.db.knownPetAbilities==nil and next(F.db.petFoodLists)==nil and F.db.petLastFeeds==nil)
assert(root.knownPetAbilities.bite==8 and root.petLastFeeds.pet.food=='legacy','legacy records preserved unassigned')
assert(not F.db.ammo.lastEquipped and not F.db.ammo.discovered and root.ammo.lastEquipped==9999)
assert(F.db.beastJournal.enabled==false and F.db.beastJournal.records==nil)
F.db.petFoodLists['pet:bear:bear']={blacklist={[117]=true},whitelist={}}
F.db.knownPetAbilities={bite=1};F.db.petLastFeeds={pet={food='PvE meat'}}
F.db.ammo.discovered={[8888]={name='PvE ammo'}};F.db.ammo.lastEquipped=2512
F.db.beastJournal.records={[20]={name='PvE beast'}}
F.db.playerFinder.watches={{name='PvE player'}}
F.db.performanceLastReport='PvE report';F.db.ammoVendorRaidGUID='Creature-0-1-0-0-1-abc'
F.db.distanceQueryDiagnostics={version=1,probe=12};F.distanceRuntime={guid='old'}
F.targetRangeDetailsCache={text='old'};F.rangeSpellInfoCache={};F.mendPetRangeAt=100;F.mendPetRangeSpell=136
local ammoView=F.db.ammo
F.foodCount=99;F.ammoCounts={[2512]=99};F.pendingFeedNotice={food='old'}
F.ammoCatalog[8888]={name='Observed'};F.foodCatalog[8888]={name='Observed'}
local resets=0;F.characterContextResets={function() resets=resets+1 end}
assert(frame.events.PLAYER_ENTERING_WORLD and frame.events.ACTIVE_GAME_MODE_UPDATED)
pvp=true;frame.scripts.OnEvent(nil,'PLAYER_ENTERING_WORLD')
local pvP=F.characterContextKey;assert(pvP~=pve)
assert(F.db.distanceQueryDiagnostics==nil and F.distanceRuntime==nil)
assert(not F.targetRangeDetailsCache and not F.rangeSpellInfoCache and not F.mendPetRangeAt and not F.mendPetRangeSpell)
assert(F.db.knownPetAbilities==nil and next(F.db.petFoodLists)==nil and F.db.petLastFeeds==nil)
assert(F.db.ammo.lastEquipped==nil and ammoView.lastEquipped==nil,'captured preference views follow active context')
assert(F.db.performanceLastReport==nil and F.db.ammoVendorRaidGUID==nil)
assert(F.db.playerFinder.watches==nil and F.db.playerFinder.sound==false)
assert(not F.foodCount and not F.ammoCounts and not F.pendingFeedNotice and resets==1)
assert(F.ammoCatalog[8888]==nil and F.foodCatalog[8888]==nil)
F.db.knownPetAbilities={bite=4};F.db.ammo.lastEquipped=2519;F.db.x=555
F.db.playerFinder.watches={{name='PvP player'}}
pvp=false;F.RefreshCharacterContext()
assert(F.characterContextKey==pve and F.db.knownPetAbilities.bite==1 and F.db.ammo.lastEquipped==2512)
assert(F.db.petLastFeeds.pet.food=='PvE meat' and F.db.playerFinder.watches[1].name=='PvE player')
assert(F.db.x==555,'general settings are shared')
assert(F.db.distanceQueryDiagnostics.probe==12,'distance diagnostics follow the ruleset')
for _,flags in ipairs({{true,false,false},{false,true,false},{false,true,true},{true,true,true}}) do
 hc,rp,pvp=unpack(flags);F.RefreshCharacterContext()
 assert(F.db.knownPetAbilities==nil,'each exact flag combination is isolated')
 F.db.knownPetAbilities={bite=7}
end
hc,rp,pvp=false,false,false;guid='Player-91-000000CD';F.RefreshCharacterContext()
assert(F.db.knownPetAbilities==nil,'same display name cannot merge different character GUIDs')
guid='Player-91-000000AB';F.RefreshCharacterContext();assert(F.db.knownPetAbilities.bite==1)
local savedQuery=C_GameRules.IsGameRuleActive
C_GameRules.IsGameRuleActive=function() return nil end;F.RefreshCharacterContext()
assert(not F.characterContextKey and F.db.knownPetAbilities==nil)
F.db.knownPetAbilities={bite=99};F.db.x=777
C_GameRules.IsGameRuleActive=savedQuery;F.RefreshCharacterContext()
assert(F.db.knownPetAbilities.bite==1 and F.db.x==777,'unknown context never contaminates verified data')
C_GameRules.IsGameRuleActive=function() return secret end
assert(not F.CharacterContextIdentity());C_GameRules.IsGameRuleActive=function() error('loading') end
assert(not F.CharacterContextIdentity());C_GameRules.IsGameRuleActive=savedQuery
guid=nil;assert(not F.CharacterContextIdentity());guid='Player-91-000000AB'
local rootProfiles=root.characterRulesetsV1
F.db=F.BindCharacterSettings(root);assert(rootProfiles==root.characterRulesetsV1)
assert(root.knownPetAbilities.bite==8 and root.ammo.discovered[9999].name=='Legacy')
print('PASS: ruleset/GUID isolation, shared preferences, preserved legacy data, unknown/secret/error guards, runtime invalidation and returning context')

assert(getmetatable(root)==nil and getmetatable(root.ammo)==nil,'never serialize runtime proxy tables')
local reloadF={Print=function() end}
assert(loadfile('HunterTools/Core.lua'))('test',reloadF)
assert(loadfile('HunterTools/CharacterContext.lua'))('test',reloadF)
reloadF.LoadSettings();assert(reloadF.db.knownPetAbilities.bite==1 and reloadF.db.x==777,'reload restores verified owner state and shared preferences')
local combat=true;InCombatLockdown=function() return combat end
pvp=true;reloadF.RefreshCharacterContext();assert(reloadF.db.knownPetAbilities.bite==4 and reloadF.characterContextUICleanup)
combat=false;reloadF.RefreshCharacterContext();assert(not reloadF.characterContextUICleanup)
assert(reloadF.db.knownPetAbilities.bite==4,'deferred UI cleanup must preserve new context records')
