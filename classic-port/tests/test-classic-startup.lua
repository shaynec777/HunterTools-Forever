local F={};local frames={};local callbacks={}
local function widget(name)
    local w={name=name,scripts={},attributes={},shown=false,text=''}
    setmetatable(w,{__index=function(_,key)
        if key=='CreateFontString' or key=='CreateTexture' then return function() return widget() end end
        return function() end
    end})
    function w:SetScript(k,v) self.scripts[k]=v end
    function w:HookScript(k,v) self.scripts[k]=v end
    function w:SetAttribute(k,v) self.attributes[k]=v end
    function w:GetAttribute(k) return self.attributes[k] end
    function w:Show() self.shown=true end
    function w:Hide() self.shown=false end
    function w:IsShown() return self.shown end
    function w:SetShown(v) self.shown=v end
    function w:SetText(v) self.text=v end
    function w:GetText() return self.text end
    function w:GetFrameLevel() return 1 end
    function w:GetWidth() return 44 end
    function w:GetHeight() return 44 end
    function w:GetEffectiveScale() return 1 end
    function w:GetStringHeight() return 20 end
    return w
end
UIParent=widget();GameTooltip=widget();ItemRefTooltip=widget();UISpecialFrames={}
function CreateFrame(_,name) local w=widget(name);frames[#frames+1]=w;if name then _G[name]=w end;return w end
SlashCmdList={};WOW_PROJECT_CLASSIC=2;WOW_PROJECT_ID=2
InCombatLockdown=function() return false end
UnitExists=function() return false end
UnitClass=function() return 'Hunter','HUNTER' end
UnitIsDeadOrGhost=function() return false end
UnitOnTaxi=function() return false end
IsMounted=function() return false end
GetTime=function() return 100 end
GetBuildInfo=function() return '1.15.9','70003','',11509 end
GetLocale=function() return 'enUS' end
UnitLevel=function() return 1 end
UnitName=function() return 'TestHunter' end
UnitGUID=function() return 'Player-1-1' end
UnitFactionGroup=function() return 'Horde' end
GetInventoryItemID=function() return nil end
GetPetHappiness=function() return nil end
GetPetFoodTypes=function() return nil end
IsInInstance=function() return false,'none' end
RegisterStateDriver=function() end
RegisterUnitWatch=function() end
SecureHandlerWrapScript=function() end
SecureHandlerSetFrameRef=function() end
SecureHandlerExecute=function() end
hooksecurefunc=function() end
DEFAULT_CHAT_FRAME={AddMessage=function() end}
C_Container={GetContainerNumSlots=function() return 16 end,GetContainerItemInfo=function() end}
C_Item={GetItemInfo=function() end,GetItemCount=function() return 0 end}
C_Spell={GetSpellName=function(id) return 'Spell '..id end,GetSpellTexture=function() return 123 end}
C_SpellBook={IsSpellKnown=function() return false end}
C_UnitAuras={GetAuraDataBySpellName=function() end}
C_Minimap={GetNumTrackingTypes=function() return 0 end}
C_Timer={NewTicker=function(_,fn) callbacks[#callbacks+1]=fn;return {} end,After=function() end}
C_EventUtils={IsEventValid=function() return true end}
Enum={SpellBookSpellBank={Player=0,Pet=1}}
HunterToolsDB={sentinel='Forever settings'}
FeedomaticTooDB={sentinel='legacy settings'}
local toc=assert(io.open('source/HunterToolsClassic/HunterToolsClassic.toc'))
for line in toc:lines() do
    line=line:gsub('\r$','')
    if line:match('%.lua$') then assert(loadfile('source/HunterToolsClassic/'..line))('HunterToolsClassic',F) end
end
toc:close()
-- Only the addon loader unregisters ADDON_LOADED; route by its registered script.
for _,frame in ipairs(frames) do
    if frame.scripts.OnEvent then frame.scripts.OnEvent(frame,'ADDON_LOADED','HunterToolsClassic') end
end
assert(F.supported==true and F.db==HunterToolsClassicDB)
assert(F.db.sentinel==nil and HunterToolsDB.sentinel=='Forever settings')
assert(FeedomaticTooDB.sentinel=='legacy settings')
assert(F.db.foodOrder=='low')
assert(SlashCmdList.HUNTERTOOLSCLASSIC and SLASH_HUNTERTOOLSCLASSIC5=='/htc')
assert(not SlashCmdList.FEEDOMATICTOO)
assert(F.GetState()=='hidden')
for _,fn in ipairs(callbacks) do fn() end
F.OpenConfig();assert(F.configPanel.shown)
SlashCmdList.HUNTERTOOLSCLASSIC('classicdebug')
-- Realm-aware names, with exact unqualified and qualified watch behavior.
UnitFullName=function() return 'Darius','Some Realm' end
assert(F.PlayerFinderName('target')=='Darius-SomeRealm')
assert(F.ClassicPlayerNameMatches('Darius','Darius-SomeRealm',false))
assert(F.ClassicPlayerNameMatches('Darius-SomeRealm','Darius-SomeRealm',false))
assert(not F.ClassicPlayerNameMatches('Darius-OtherRealm','Darius-SomeRealm',false))
assert(F.ClassicPlayerNameMatches('dari','Darius-SomeRealm',true))
print('PASS: all TOC Lua modules load, level-1/no-pet startup, periodic refresh, menu, separate settings/commands and realm names')

-- Era may omit spell IDs or inactive spells from minimap tracking rows.
F.ClassicSpellBook.IsSpellKnown=function(id) return id==1494 end
F.ClassicSpell.GetSpellName=function(id) if id==1494 then return 'Localized Track Beasts' end end
F.ClassicMinimap.GetNumTrackingTypes=function() return 0 end
local tracking=F.TrackingState()
assert(#tracking.choices==1 and tracking.choices[1].id==1494,'learned tracker missing from minimap rows must remain selectable')
F.ClassicMinimap.GetNumTrackingTypes=function() return 1 end
F.ClassicMinimap.GetTrackingInfo=function() return {name='Localized Track Beasts',texture=123,active=true} end
tracking=F.TrackingState()
assert(#tracking.choices==1 and tracking.active.id==1494,'localized row without spellID must resolve without duplicates')
F.ClassicSpellBook.IsSpellKnown=function() return false end
assert(#F.TrackingState().choices==0,'unlearned tracking must not be offered')

local petopia,wowhead=F.BeastSourceURLs(3099)
assert(petopia==F.petopiaTameability[3099].source)
assert(wowhead=='https://www.wowhead.com/classic/npc=3099')
F.OpenPetAnimalWowhead({id=3099,name='Elder Mottled Boar'})
assert(F.wowheadLinkPanel.sourceLinks[1]==petopia)
assert(F.wowheadLinkPanel.sourceLinks[2]==wowhead)
assert(F.wowheadLinkPanel.sourceLinks[3]==nil,'Classic chooser must not duplicate the Wowhead source')
assert(F.wowheadLinkPanel.classicButton.text=='Wowhead Classic')
assert(rawget(F.wowheadLinkPanel,'foreverButton')==nil)
