"""Create an independent Era test fork. Never writes the Forever source or install."""
from pathlib import Path
import re, shutil, json, html, hashlib

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / 'classic-port'
SOURCE = ROOT / 'release-source/HunterTools'
DEST = OUT / 'source/HunterToolsClassic'
assert not DEST.exists(), 'Classic source already exists; edit it in place rather than overwriting work.'
before = {p.name: hashlib.sha256(p.read_bytes()).hexdigest() for p in SOURCE.rglob('*') if p.is_file()}
shutil.copytree(SOURCE, DEST)

# Separate saved variables, frame IDs, assets, keybindings and command registry.
for p in DEST.rglob('*'):
    if p.suffix not in ('.lua', '.xml', '.toc', '.txt'): continue
    t = p.read_text(encoding='utf-8-sig')
    t = t.replace('HunterTools Forever', 'HunterTools Classic')
    t = re.sub(r'HunterTools(?! Classic)', 'HunterToolsClassic', t)
    t = t.replace('GFWForever', 'GFWClassic').replace('GFWFOREVER', 'GFWCLASSIC')
    t = t.replace('FeedomaticTooDB', 'HunterToolsClassicLegacyDB')
    t = t.replace('www.wowhead.com/forever/', 'www.wowhead.com/classic/')
    for ns, private in [('C_PetInfo','ClassicPetInfo'),('C_SpellBook','ClassicSpellBook'),
                        ('C_Spell','ClassicSpell'),('C_UnitAuras','ClassicAuras'),
                        ('C_TooltipInfo','ClassicTooltip'),('C_Minimap','ClassicMinimap')]:
        t = re.sub(r'\b'+ns+r'\b', 'F.'+private, t)
    t = t.replace('Forever', 'Classic Era') if p.name in ('README.txt',) else t
    p.write_text(t, encoding='utf-8')
for name in ('HunterTools.lua', 'HunterTools.toc'):
    (DEST/name).rename(DEST/name.replace('HunterTools','HunterToolsClassic'))

p = DEST/'Core.lua'; t = p.read_text(encoding='utf-8')
t = t.replace('F.VERSION = "3.1.5"', 'F.VERSION = "0.1.0-beta1"')
t = t.replace('Required Forever APIs unavailable', 'Required Classic Era APIs unavailable')
# No migration from the Forever or old addon namespace.
a = t.index('    if type(HunterToolsClassicDB) ~= "table" then')
b = t.index('    F.db = HunterToolsClassicDB', a)
t = t[:a]+'    if type(HunterToolsClassicDB) ~= "table" then HunterToolsClassicDB={} end\n'+t[b:]
p.write_text(t, encoding='utf-8')
p = DEST/'HunterToolsClassic.toc'; t=p.read_text(encoding='utf-8')
t=t.replace('## Interface: 16001','## Interface: 11509').replace('## Version: 3.1.5','## Version: 0.1.0-beta1')
t=t.replace('## Title: HunterTools Classic','## Title: HunterTools Classic (Era test)')
t=t.replace('## OptionalDeps: FeedomaticToo\n','')
t=t.replace('Core.lua\n','ClassicCompat.lua\nCore.lua\n',1)
t=t.replace('ForeverPetData.lua\n','').replace('PetopiaForeverData.lua\n','')
t=t.replace('PetBrowserData.lua\n','PetBrowserData.lua\nClassicReference.lua\n')
p.write_text(t,encoding='utf-8')
for name in ('ForeverPetData.lua','PetopiaForeverData.lua'):
    (DEST/name).unlink()

# Rebuild ranks from our retained Classic spell-ID table, not Forever learning IDs.
page=(ROOT/'petopia-abilities.html').read_text(encoding='utf-8')
def plain(s): return ' '.join(html.unescape(re.sub('<[^>]+>',' ',s)).split())
sources={}; heads=list(re.finditer(r"class='abilityrankname classic'>(.*?)</span>: Pet Level (\d+)",page,re.S))
for i,h in enumerate(heads):
    m=re.fullmatch(r'(.*?) (\d+)',plain(h[1]))
    if not m: continue
    block=page[h.end():heads[i+1].start() if i+1<len(heads) else len(page)]
    animals=[]
    for a in re.finditer(r"class='npclink classic' href='https://classic.wowhead.com/npc=(\d+)'>(.*?)</a>\s*\((.*?)\)</li>",block,re.S):
        parts=plain(a[3]).split(', ',2)
        if len(parts)!=3: continue
        animals.append(dict(id=int(a[1]),name=plain(a[2]),family=parts[0],levels=parts[1],zone=parts[2],reference='Classic'))
    sources[(m[1].lower(),int(m[2]))]=animals
groups=[]; current=None; ranks={}
for line in (ROOT/'PetAbilitiesData.lua').read_text(encoding='utf-8').splitlines():
    a=re.match(r'ability\(".*?",.*?\) -- (.*?):',line)
    if a:
        name=a[1];current=dict(key=name.lower(),name=name,ranks=[]);groups.append(current)
    a=re.match(r'rank\((\d+),\s*(\d+),\s*(\d+),\s*\d+,\s*"(.*?)"',line)
    if a and current:
        spell,rank,level=int(a[1]),int(a[2]),int(a[3]);ranks[spell]=rank
        current['ranks'].append(dict(rank=rank,spellID=spell,petLevel=level,classicSource=a[4],animals=sources.get((current['key'],rank),[])))
def lua(v):
    if isinstance(v,str): return json.dumps(v,ensure_ascii=False)
    if isinstance(v,int): return str(v)
    if isinstance(v,list): return '{'+','.join(lua(x) for x in v)+'}'
    return '{'+','.join('['+lua(k)+']='+lua(x) for k,x in v.items())+'}'
(DEST/'PetBrowserData.lua').write_text('local _,F=...\n-- Classic Era spell IDs and Petopia Classic teaching references.\nF.petBrowserAbilities='+lua(sorted(groups,key=lambda g:g['name']))+'\n',encoding='utf-8')
p=DEST/'KnownPetAbilities.lua';t=p.read_text(encoding='utf-8')
a=t.index('-- BEGIN GENERATED PET SPELL RANKS');b=t.index('-- END GENERATED PET SPELL RANKS',a)+len('-- END GENERATED PET SPELL RANKS')
t=t[:a]+'-- Classic Era casting IDs; training scans and learning messages supply ranks.\nlocal linkedPetRanks='+lua(ranks)+'\nF.petAbilitySpellRanks=linkedPetRanks\nlocal petAbilityAliases={}\n'+t[b:]
t=t.replace('    F.ScanForeverPetTraining()','    -- Classic Era Beast Training uses the craft API, not Forever trainers.')
t=t.replace("if C_EventUtils.IsEventValid(event) then events:RegisterEvent(event) end","if C_EventUtils.IsEventValid(event) then events:RegisterEvent(event) end")
t=t.replace("end\nevents:SetScript", "end\nevents:SetScript")
p.write_text(t,encoding='utf-8')

# Keep Classic-only food and projectile identities. Live metadata supplies names/levels.
p=DEST/'Foods.lua';t=p.read_text(encoding='utf-8');t='\n'.join(line for line in t.splitlines() if not re.match(r'\s*\[(\d+)\]',line) or int(re.match(r'\s*\[(\d+)\]',line)[1])<25000)+'\n';p.write_text(t,encoding='utf-8')
p=DEST/'AmmoUpgradeData.lua';t=p.read_text(encoding='utf-8');t='\n'.join(line for line in t.splitlines() if not re.match(r'\s*\[(\d+)\]',line) or int(re.match(r'\s*\[(\d+)\]',line)[1])<25000)+'\n';t=t.replace('Curated Wowhead Forever','Classic-era projectile baseline, adapted from curated Wowhead');t=t.replace('Fizzlefuse - Eastern Kingdoms; currency/exchange requirements unverified','Thorium Shells exchange; confirm the Classic vendor');p.write_text(t,encoding='utf-8')
p=DEST/'AmmoCatalog.lua';t=p.read_text(encoding='utf-8');t='\n'.join(line for line in t.splitlines() if not re.match(r'\s*\[(\d+)\]',line) or int(re.match(r'\s*\[(\d+)\]',line)[1])<25000)+'\n';p.write_text(t,encoding='utf-8')
p=DEST/'AspectReminder.lua';t=p.read_text(encoding='utf-8');a=t.index('local aspects={');b=t.index('\n}',a)+2
t=t[:a]+'''local aspects={
    {key='hawk',ids={13165,14318,14319,14320,14321,14322,25296}},
    {key='monkey',ids={13163}}, {key='beast',ids={13161}},
    {key='wild',ids={20043,20190}}, {key='cheetah',ids={5118}}, {key='pack',ids={13159}},
}'''+t[b:];p.write_text(t,encoding='utf-8')
p=DEST/'HunterToolsClassic.lua';t=p.read_text(encoding='utf-8').replace('Required Forever APIs are unavailable.','Required Classic Era APIs are unavailable.')
t=t.replace("        F.supported=F.CheckAPIs()", "        if not F.IsClassicEra then F.Print('This build requires Classic Era, Hardcore or Season of Discovery.');return end\n        F.supported=F.CheckAPIs()")
t=t.replace("SLASH_GFWCLASSIC1='/ht'", "SLASH_GFWCLASSIC1='/ht'")
# Additional explicit command works even when users prefer the longer identity.
t=t.replace("        F.supported=F.CheckAPIs()", "        SLASH_GFWCLASSIC9='/htc'\n        F.supported=F.CheckAPIs()")
p.write_text(t,encoding='utf-8')
after={p.name:hashlib.sha256(p.read_bytes()).hexdigest() for p in SOURCE.rglob('*') if p.is_file()}
assert before==after, 'Forever source changed unexpectedly'
(OUT/'forever-source-baseline.json').write_text(json.dumps(before,indent=2))
print('Created independent Classic Era source:', DEST)
print('Classic ability groups/ranks:',len(groups),len(ranks))
