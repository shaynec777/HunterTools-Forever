local _,F=...
local function safe(v) return not issecretvalue or not issecretvalue(v) end
-- Classic Era casting IDs; training scans and learning messages supply ranks.
local linkedPetRanks={[24493]=1,[24497]=2,[24500]=3,[24501]=4,[17253]=1,[17255]=2,[17256]=3,[17257]=4,[17258]=5,[17259]=6,[17260]=7,[17261]=8,[7371]=1,[26177]=2,[26178]=3,[26179]=4,[26201]=5,[27685]=6,[16827]=1,[16828]=2,[16829]=3,[16830]=4,[16831]=5,[16832]=6,[3010]=7,[3009]=8,[1742]=1,[1753]=2,[1754]=3,[1755]=4,[1756]=5,[16697]=6,[23099]=1,[23109]=2,[23110]=3,[23145]=1,[23147]=2,[23148]=3,[23992]=1,[24439]=2,[24444]=3,[24445]=4,[24446]=1,[24447]=2,[24448]=3,[24449]=4,[24604]=1,[24605]=2,[24603]=3,[24597]=4,[4187]=1,[4188]=2,[4189]=3,[4190]=4,[4191]=5,[4192]=6,[4193]=7,[4194]=8,[5041]=9,[5042]=10,[2649]=1,[14916]=2,[14917]=3,[14918]=4,[14919]=5,[14920]=6,[14921]=7,[24844]=1,[25008]=2,[25009]=3,[25010]=4,[25011]=5,[25012]=6,[24545]=1,[24549]=2,[24550]=3,[24551]=4,[24552]=5,[24553]=6,[24554]=7,[24555]=8,[24629]=9,[24630]=10,[24492]=1,[24502]=2,[24503]=3,[24504]=4,[24450]=1,[24452]=2,[24453]=3,[24640]=1,[24583]=2,[24586]=3,[24587]=4,[24423]=1,[24577]=2,[24578]=3,[24579]=4,[24488]=1,[24505]=2,[24506]=3,[24507]=4,[26064]=1,[26090]=1,[26187]=2,[26188]=3}
F.petAbilitySpellRanks=linkedPetRanks
local petAbilityAliases={}

local function abilityKey(name)
    local key=name:lower()
    return petAbilityAliases[key] or key
end
function F.RememberPetAbility(name,rank)
    if not F.db or not safe(name) or type(name)~='string' or not safe(rank) or type(rank)~='number' or rank<1 then return end
    F.db.knownPetAbilities=F.db.knownPetAbilities or {}
    local key=abilityKey(name)
    F.db.knownPetAbilities[key]=math.max(F.db.knownPetAbilities[key] or 0,rank)
end
function F.LearnedPetAbilityMessage(message)
    if not F.db or not safe(message) or type(message)~='string' then return end
    for _,format in ipairs({ERR_LEARN_ABILITY_S or '',ERR_LEARN_SPELL_S or '',ERR_LEARN_PASSIVE_S or ''}) do
        if format~='' then
            local pattern=format:gsub('([%^%$%(%)%%%.%[%]%*%+%-%?])','%%%1'):gsub('%%%%s','(.+)')
            local ability=message:match('^'..pattern..'$')
            if ability then
                local spellID=tonumber(ability:match('|Hspell:(%d+)'))
                ability=ability:gsub('|c%x%x%x%x%x%x%x%x',''):gsub('|r',''):gsub('|H.-|h(.-)|h','%1')
                ability=ability:gsub('%[([^%]]+)%]','%1')
                local name,rank=ability:match('^(.-)%s*%([Rr]ank%s+(%d+)%)$')
                if not name then name,rank=ability:match('^(.-)%s+[Rr]ank%s+(%d+)$') end
                if not name and spellID then
                    local sub
                    if F.ClassicSpell and F.ClassicSpell.GetSpellSubtext then
                        sub=F.ClassicSpell.GetSpellSubtext(spellID)
                    elseif GetSpellInfo then
                        local _; _,sub=GetSpellInfo(spellID)
                    end
                    if safe(sub) and type(sub)=='string' then rank=tonumber(sub:match('(%d+)')) end
                    rank=rank or linkedPetRanks[spellID]
                    if rank then name=ability end
                end
                -- Do not guess rank 1 for a name-only message. Save a small
                -- diagnostic so an unsupported client format can be identified.
                F.db.lastPetAbilityLearning={message=message,spellID=spellID,name=name,rank=tonumber(rank),recognized=name~=nil and rank~=nil}
                if name and rank then F.RememberPetAbility(name,tonumber(rank)) end
                return
            end
        end
    end
end
function F.ScanKnownPetAbilities()
    -- Classic Era Beast Training uses the craft API.
    if not F.db or InCombatLockdown() or not GetCraftDisplaySkillLine or not GetNumCrafts or not GetCraftInfo then return end
    local title=GetCraftDisplaySkillLine()
    local training=F.ClassicSpell and F.ClassicSpell.GetSpellName and F.ClassicSpell.GetSpellName(5149)
    if not safe(title) or not safe(training) or not training or title~=training then return end
    local n=GetNumCrafts()
    if not safe(n) or type(n)~='number' or n==0 then return end
    F.db.knownPetAbilities=F.db.knownPetAbilities or {}
    local names={}
    for i=1,n do
        local name,sub,craftType=GetCraftInfo(i)
        if safe(name) and safe(sub) and safe(craftType) and craftType~='header' and type(name)=='string' then
            local rank=type(sub)=='string' and tonumber(sub:match('(%d+)')) or 1
            if rank then
                local key=abilityKey(name)
                F.db.knownPetAbilities[key]=math.max(F.db.knownPetAbilities[key] or 0,rank)
                names[key]=true
            end
        end
    end
    F.db.petAbilityScanNames=names
end
function F.ReplayPetAbilityLearning()
    local known=F.db and F.db.knownPetAbilities
    if type(known)=='table' then
        for old,new in pairs(petAbilityAliases) do
            if type(known[old])=='number' then
                known[new]=math.max(known[new] or 0,known[old]); known[old]=nil
            end
        end
    end
    local learning=F.db and F.db.lastPetAbilityLearning
    if type(learning)=='table' then F.LearnedPetAbilityMessage(learning.message) end
end
function F.MarkTargetAbilities(text)
    F.ScanKnownPetAbilities()
    local known=F.db.knownPetAbilities or {}
    local seen=F.db.petAbilityScanNames or {}
    return (text:gsub('([^;]+)',function(part)
        local name,rank=part:match('^%s*(.-)%s+[Rr]ank%s+(%d+)')
        if not name then name,rank=part:match('^%s*(.-)%s+(%d+)') end
        if not name or not rank then return part end
        local key=abilityKey(name); rank=tonumber(rank)
        if known[key] and known[key]>=rank then return part..' |cff33ff66[Learned]|r' end
        -- Missing from the cached training list; confirmed entries accumulate.
        if seen[key] or F.db.petTrainingScanned then return '|cffff5555'..part..' [Not Learned]|r' end
        return part..' [Learned status unavailable]'
    end))
end
local events=CreateFrame('Frame')
-- Craft events are client-dependent. Never register an
-- unsupported event; the range display also refreshes this cache on demand.
-- System chat is a stable event even when the optional event validator is absent.
events:RegisterEvent('CHAT_MSG_SYSTEM')
if C_EventUtils and C_EventUtils.IsEventValid then
    for _,event in ipairs({'CRAFT_SHOW','CRAFT_UPDATE','TRAINER_SHOW','TRAINER_UPDATE','CHAT_MSG_SKILL'}) do
        if C_EventUtils.IsEventValid(event) then events:RegisterEvent(event) end
    end
end
events:SetScript('OnEvent',function(_,event,message) if event=='CHAT_MSG_SYSTEM' or event=='CHAT_MSG_SKILL' then F.LearnedPetAbilityMessage(message) else F.ScanKnownPetAbilities() end end)

function F.DebugPetTraining()
    if InCombatLockdown() then F.Print('Check training after combat.'); return end
    local lines={}
    local function add(s) lines[#lines+1]=s; F.Print(s) end
    local learning=F.db and F.db.lastPetAbilityLearning
    if learning then
        add('Last hunter learning message: '..learning.message)
        add('Learning match: '..tostring(learning.name)..', rank '..tostring(learning.rank)..', spell '..tostring(learning.spellID))
    else add('No hunter learning message captured this session/settings yet.') end
    for _,name in ipairs({'GetCraftDisplaySkillLine','GetNumCrafts','GetCraftInfo','GetCraftSpellFocus','CraftFrame'}) do
        add(name..': '..type(_G[name]))
    end
    for _,ns in ipairs({'F.ClassicPetInfo','C_CraftInfo','C_TradeSkillUI','C_BeastTraining'}) do
        local api=_G[ns]; local names={}
        if type(api)=='table' then
            for key,value in pairs(api) do
                if type(value)=='function' and (key:lower():find('train') or key:lower():find('craft') or key:lower():find('spell') or key:lower():find('recipe') or key:lower():find('profession')) then names[#names+1]=key end
            end
        end
        table.sort(names); add(ns..': '..table.concat(names,', '))
    end
    if GetCraftDisplaySkillLine then local ok,title=pcall(GetCraftDisplaySkillLine); add('Craft title: '..(ok and tostring(title) or 'unavailable')) end
    if GetNumCrafts then local ok,n=pcall(GetNumCrafts); add('Craft count: '..(ok and tostring(n) or 'unavailable')) end
    if C_TradeSkillUI and C_TradeSkillUI.GetBaseProfessionInfo then
        local ok,info=pcall(C_TradeSkillUI.GetBaseProfessionInfo)
        if ok and type(info)=='table' then
            for _,key in ipairs({'professionName','professionID','skillLevel','parentProfessionID'}) do add(key..': '..tostring(info[key])) end
        end
    end
    F.db.petTrainingDebug=lines
end
