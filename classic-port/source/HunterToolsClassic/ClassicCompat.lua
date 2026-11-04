local _,F=...
-- Private adapters: never overwrite Blizzard namespaces or their functions.
F.IsClassicEra=WOW_PROJECT_ID~=nil and WOW_PROJECT_ID==WOW_PROJECT_CLASSIC
local function adapter(native) return setmetatable({}, {__index=native or {}}) end
F.ClassicSpell=adapter(C_Spell)
F.ClassicSpellBook=adapter(C_SpellBook)
F.ClassicAuras=adapter(C_UnitAuras)
F.ClassicMinimap=adapter(C_Minimap)
F.ClassicPetInfo=adapter(C_PetInfo)
F.ClassicTooltip=adapter(C_TooltipInfo)

if not F.ClassicSpell.GetSpellInfo and GetSpellInfo then
    function F.ClassicSpell.GetSpellInfo(id)
        local name,rank,icon,castTime,minRange,maxRange,spellID=GetSpellInfo(id)
        if name then return {name=name,rank=rank,iconID=icon,castTime=castTime,minRange=minRange,maxRange=maxRange,spellID=spellID or id} end
    end
end
if not F.ClassicSpell.GetSpellName then
    function F.ClassicSpell.GetSpellName(id)
        local info=F.ClassicSpell.GetSpellInfo and F.ClassicSpell.GetSpellInfo(id)
        return info and info.name
    end
end
if not F.ClassicSpell.GetSpellTexture then
    F.ClassicSpell.GetSpellTexture=GetSpellTexture or function(id)
        local info=F.ClassicSpell.GetSpellInfo and F.ClassicSpell.GetSpellInfo(id)
        return info and info.iconID
    end
end
if not F.ClassicSpell.GetSpellSubtext and GetSpellInfo then
    function F.ClassicSpell.GetSpellSubtext(id) local _,rank=GetSpellInfo(id);return rank end
end
if not F.ClassicSpell.GetSpellCooldown and GetSpellCooldown then
    function F.ClassicSpell.GetSpellCooldown(id)
        local start,duration,enabled,modRate=GetSpellCooldown(id)
        return {startTime=start or 0,duration=duration or 0,isEnabled=enabled==1,modRate=modRate or 1}
    end
end
if not F.ClassicSpell.IsSpellInRange and IsSpellInRange then
    function F.ClassicSpell.IsSpellInRange(id,unit)
        local name=F.ClassicSpell.GetSpellName(id)
        if not name then return end
        local value=IsSpellInRange(name,unit)
        if value~=nil then return value==1 or value==true end
    end
end
if not F.ClassicSpellBook.IsSpellKnown and IsSpellKnown then
    function F.ClassicSpellBook.IsSpellKnown(id,bank)
        return IsSpellKnown(id, bank=="pet" or Enum and Enum.SpellBookSpellBank and bank==Enum.SpellBookSpellBank.Pet)
    end
end
F.ClassicSpellBook.HasPetSpells=F.ClassicSpellBook.HasPetSpells or HasPetSpells
F.ClassicPetInfo.GetPetHappiness=F.ClassicPetInfo.GetPetHappiness or GetPetHappiness
F.ClassicPetInfo.GetPetLoyalty=F.ClassicPetInfo.GetPetLoyalty or GetPetLoyalty
F.ClassicPetInfo.GetPetTrainingPoints=F.ClassicPetInfo.GetPetTrainingPoints or GetPetTrainingPoints
F.ClassicPetInfo.GetPetFoodTypes=F.ClassicPetInfo.GetPetFoodTypes or GetPetFoodTypes

-- Era needs a local item-edibility fallback. Only classify known food IDs.
-- English diet tokens are mapped to the client's localized diet constants.
local dietGlobals={Meat='PET_DIET1',Fish='PET_DIET2',Cheese='PET_DIET3',Bread='PET_DIET4',Fungus='PET_DIET5',Fruit='PET_DIET6'}
if not F.ClassicPetInfo.CanPetEatItem then
    function F.ClassicPetInfo.CanPetEatItem(id)
        if not UnitExists('pet') then return false end
        local kind=F.petFoodTypes and F.petFoodTypes[id]
        if not kind then return false end
        local getTypes=F.ClassicPetInfo.GetPetFoodTypes
        if not getTypes then return end
        local wanted=_G[dietGlobals[kind] or '']
        if not wanted then
            if GetLocale and GetLocale()~='enUS' and GetLocale()~='enGB' then return end
            wanted=kind
        end
        local types={getTypes()};local canEat=false
        for _,value in ipairs(types) do
            if type(value)=='string' then
                for token in value:gmatch('[^,]+') do
                    if token:match('^%s*(.-)%s*$')==wanted then canEat=true end
                end
            end
        end
        if not canEat then return false end
        local name,_,_,level=C_Item.GetItemInfo(id)
        if not name or type(level)~='number' then return end
        local petLevel=UnitLevel('pet')
        -- Classic's established minimum-food-level estimate. The game remains
        -- the authority on eligibility; do not infer happiness gain from this.
        return type(petLevel)=='number' and petLevel>0 and level>=petLevel-30
    end
end

if not F.ClassicAuras.GetAuraDataBySpellName and UnitBuff then
    function F.ClassicAuras.GetAuraDataBySpellName(unit,wanted,filter)
        if InCombatLockdown() then return end
        for i=1,40 do
            local name,icon,count,dispel,duration,expires,source,stealable,personal,spellID=UnitBuff(unit,i,filter)
            if not name then break end
            if name==wanted then return {name=name,icon=icon,applications=count,dispelName=dispel,duration=duration,expirationTime=expires,sourceUnit=source,spellId=spellID} end
        end
    end
end
-- Preserve legacy tracking only if the modern table-returning API is absent.
F.ClassicMinimap.GetNumTrackingTypes=F.ClassicMinimap.GetNumTrackingTypes or GetNumTrackingTypes
if not F.ClassicMinimap.GetTrackingInfo and GetTrackingInfo then
    function F.ClassicMinimap.GetTrackingInfo(index)
        local name,texture,active,kind,subType,spellID=GetTrackingInfo(index)
        return name and {name=name,texture=texture,active=active==true or active==1,type=kind,subType=subType,spellID=spellID}
    end
end

-- Older Era tooltips do not expose C_TooltipInfo's data-returning methods.
local scanner,busy
local function scan(method,value)
    if busy or InCombatLockdown() or not value then return end
    busy=true
    if not scanner then scanner=CreateFrame('GameTooltip','HunterToolsClassicScanTooltip',UIParent,'GameTooltipTemplate') end
    scanner:SetOwner(UIParent,'ANCHOR_NONE');scanner:ClearLines()
    local ok=pcall(scanner[method],scanner,value)
    local result={lines={}}
    if ok then
        for i=1,scanner:NumLines() do
            local left=_G['HunterToolsClassicScanTooltipTextLeft'..i]
            local right=_G['HunterToolsClassicScanTooltipTextRight'..i]
            result.lines[#result.lines+1]={leftText=left and left:GetText(),rightText=right and right:GetText()}
        end
    end
    scanner:Hide();busy=false
    return ok and result or nil
end
if not F.ClassicTooltip.GetItemByID then function F.ClassicTooltip.GetItemByID(id) return scan('SetHyperlink','item:'..id) end end
if not F.ClassicTooltip.GetHyperlink then function F.ClassicTooltip.GetHyperlink(link) return scan('SetHyperlink',link) end end
if not F.ClassicTooltip.GetUnit then function F.ClassicTooltip.GetUnit(unit) return scan('SetUnit',unit) end end

function F.ClassicDebug()
    local version,build,_,interface=GetBuildInfo()
    F.Print(('Classic test build %s; client %s (%s), interface %s; Era=%s'):format(F.VERSION,tostring(version),tostring(build),tostring(interface),tostring(F.IsClassicEra)))
    F.Print('Feeding API ready: '..tostring(F.CheckAPIs())..'; happiness: '..tostring(type(F.ClassicPetInfo.GetPetHappiness))..'; diet fallback: '..tostring(not (C_PetInfo and C_PetInfo.CanPetEatItem)))
end
