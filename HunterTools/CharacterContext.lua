local _,F=...
-- Only character-derived state is scoped. Shared preferences stay at the root.
local characterFields={petFoodLists=true,petFoodListsVersion=true,petLastFeeds=true,
    knownPetAbilities=true,lastPetAbilityLearning=true,petAbilityScanNames=true,
    petTrainingScanned=true,petTrainingDebug=true,discoveredFoods=true,ammoVendors=true,
    ammoVendorRaidGUID=true,performanceLastReport=true,performanceSpikes=true,distanceQueryDiagnostics=true,questDebug=true}
local nested={ammo={discovered=true,lastEquipped=true,lastWarning=true},
    beastJournal={records=true},mobFinder={watches=true},playerFinder={watches=true}}
local function query(fn,...)
    if type(fn)~='function' then return end
    local ok,v=pcall(fn,...)
    if ok and (not issecretvalue or not issecretvalue(v)) then return v end
end
function F.CharacterContextIdentity()
    local rules=Enum and Enum.GameRule
    if type(rules)~='table' then return end
    local bits={}
    for _,name in ipairs({'HardcoreRuleset','RPRuleset','PvPRuleset'}) do
        local id=rules[name]
        if (issecretvalue and issecretvalue(id)) or type(id)~='number' then return end
        local active=query(C_GameRules and C_GameRules.IsGameRuleActive,id)
        if type(active)~='boolean' then return end
        bits[#bits+1]=active and '1' or '0'
    end
    local guid=query(UnitGUID,'player')
    if type(guid)~='string' or not guid:match('^Player%-%d+%-%x+$') then return end
    return 'rules:'..table.concat(bits)..':'..guid
end
local function copy(t)
    if type(t)~='table' then return t end
    local result={};for k,v in pairs(t) do result[k]=copy(v) end;return result
end
function F.ResetCharacterRuntime()
    if F.StopPerformanceTest then F.StopPerformanceTest() end
    for _,key in ipairs({'food','foodCount','foodScanAt','foodScanPet','foodEntrySnapshot','foodEntryReadyAt',
        'foodInventorySnapshot','foodDirtyInventoryOnly','foodScanDeferUntil','foodScanDeferred','pendingFoodItemIDs','protectedFoodReasons','bagFoodCounts',
        'sessionPetFoodLists','petFoodGuidProfiles','petAbilitiesCache','ammoCounts','ammoScanAt',
        'ammoEntrySnapshot','ammoEntryReadyAt','ammoAlerts','pendingFeed','pendingFeedNotice','feedAttempt','waitUntil',
        'pendingItems','lockedFood','questFood','questFoodIDs','questFoodNames','questFoodLastScan','petAlertRuntime','petAlertDiagnostics',
        'distanceRuntime','targetRangeDetailsCache','rangeSpellInfoCache','mendPetRangeAt','mendPetRangeSpell','rangedWeaponLastLevel','rangedWeaponPending','aspectRuntime','trackingRuntime',
        'hungerSoundPet','hungerAlerted','lastGrowl','lastTextReminder','reminderPet','questFoodScanAt',
        'questFoodPendingIDs','questFoodProtection','aspectChoicesCache','trackingChoicesCache',
        'playerFinderFound','mobFinderFound','mobFinderLocationStatus','mobFinderDestination'}) do F[key]=nil end
    F.bagsDirty=true;F.ammoDirty=true;F.questFoodDirty=true;F.petAbilitiesDirty=true;F.petStatusDataDirty=true
    for _,callback in ipairs(F.characterContextResets or {}) do callback() end
    for _,key in ipairs({'ammoCatalog','foodCatalog'}) do
        local base=F.characterBaseCatalogs and F.characterBaseCatalogs[key]
        if base then F[key]=copy(base) end
    end
    F.characterContextUICleanup=true
    if not query(InCombatLockdown) then
        F.characterContextUICleanup=nil
        if F.ClearAmmoVendorMarker then F.ClearAmmoVendorMarker(true) end
        if F.ClearTrainerMarker then F.ClearTrainerMarker() end
        for _,key in ipairs({'petStatusWindow','mobFinderPanel','playerFinderPanel','rangedWeaponAlert',
            'mobFinderTargetPopup','playerFinderTargetPopup','mobFinderTargetPing','mobFinderMiniPin','mobFinderMapPin','rangeWindow','petLowHealthVisual'}) do
            local p=F[key];if p then p.statusBuiltAt=nil;p.renderState=nil;p:Hide() end
        end
        if F.Disarm then F.Disarm() end
        if F.HideConfigPages then F.HideConfigPages() end
    end
end
local boundRoot,view,views
function F.BindCharacterSettings(root)
    local key=F.CharacterContextIdentity()
    if boundRoot==root and F.characterContextKey==key and view then return view end
    -- Flush an active diagnostic into the OLD context before selecting a new one.
    if boundRoot and F.StopPerformanceTest then F.StopPerformanceTest() end
    if not F.characterBaseCatalogs then
        F.characterBaseCatalogs={ammoCatalog=copy(F.ammoCatalog),foodCatalog=copy(F.foodCatalog)}
    end
    local data={}
    if key then
        if root.characterRulesetsV1==nil then root.characterRulesetsV1={} end
        if type(root.characterRulesetsV1)=='table' then
            if root.characterRulesetsV1[key]==nil then root.characterRulesetsV1[key]={} end
            if type(root.characterRulesetsV1[key])=='table' then data=root.characterRulesetsV1[key] else key=nil end
        else key=nil end
    end
    F.characterContextKey=key;F.characterContextData=data
    if boundRoot~=root then
        boundRoot=root;views={}
        local function storage(parent)
            if type(root[parent])~='table' then root[parent]={} end
            return root[parent]
        end
        for parent,fields in pairs(nested) do
            local name,scoped=parent,fields
            local proxy
            proxy=setmetatable({}, {
                __index=function(_,k)
                    if scoped[k] then
                        local t=F.characterContextData[name];if type(t)=='table' then return t[k] end
                        return nil
                    end
                    return storage(name)[k]
                end,
                __newindex=function(_,k,v)
                    if scoped[k] then
                        local d=F.characterContextData
                        if type(d[name])~='table' then d[name]={} end
                        d[name][k]=v
                    else storage(name)[k]=v end
                end})
            views[name]=proxy
        end
        view=setmetatable({}, {
            __index=function(_,k)
                if characterFields[k] then return F.characterContextData[k] end
                return views[k] or root[k]
            end,
            __newindex=function(_,k,v)
                if characterFields[k] then F.characterContextData[k]=v
                elseif views[k] then
                    if v~=views[k] and type(v)=='table' then
                        for field,value in pairs(v) do views[k][field]=value end
                    end
                else root[k]=v end
            end})
    end
    -- Unstamped legacy records remain untouched at the root, hidden from the
    -- active view. Never guess their ruleset from a realm, pet name or first login.
    F.db=view
    F.ResetCharacterRuntime()
    return view
end
function F.RefreshCharacterContext()
    if not boundRoot then return end
    if F.CharacterContextIdentity()~=F.characterContextKey then F.LoadSettings()
    elseif F.characterContextUICleanup and not query(InCombatLockdown) then F.ResetCharacterRuntime() end
end

-- Registered before feature modules so their world-entry handlers cannot write
-- a newly logged-in character's observations into the previous context.
if CreateFrame then
    local events=CreateFrame('Frame')
    for _,event in ipairs({'PLAYER_ENTERING_WORLD','PLAYER_REGEN_ENABLED','ACTIVE_GAME_MODE_UPDATED'}) do
        if not C_EventUtils or not C_EventUtils.IsEventValid or C_EventUtils.IsEventValid(event) then events:RegisterEvent(event) end
    end
    events:SetScript('OnEvent',function() F.RefreshCharacterContext() end)
end
