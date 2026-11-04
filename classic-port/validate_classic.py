from pathlib import Path
import os, sys, json, hashlib, re
ROOT=Path(__file__).resolve().parent
sys.path.insert(0,str(ROOT.parent/'.test-tools'))
from lupa.lua51 import LuaRuntime
os.chdir(ROOT)
ADDON=ROOT/'source/HunterToolsClassic'
FOREVER=ROOT.parent
forever_root=FOREVER/'HunterTools'
before_validation={p.relative_to(forever_root).as_posix():hashlib.sha256(p.read_bytes()).hexdigest() for p in forever_root.rglob('*') if p.is_file()}
def runtime():
    lua=LuaRuntime();lua.globals().print=lambda *a:None;return lua
failures=[];passed=[]
for p in ADDON.glob('*.lua'):
    parsed=runtime().eval('loadstring')(p.read_text(encoding='utf-8-sig'))
    assert not isinstance(parsed,tuple),(p.name,parsed)
for p in ADDON.glob('*.lua'):
    assert 'forever' not in p.read_text(encoding='utf-8').lower(), 'Non-Classic reference in '+p.name
for line in (ADDON/'HunterToolsClassic.toc').read_text().splitlines():
    if line and not line.startswith('#'):assert (ADDON/line).is_file(),line
for p in (ROOT/'tests').glob('test-*.lua'):
    try:runtime().execute(p.read_text(encoding='utf-8'));passed.append(p.name)
    except Exception as e:failures.append((p.name,str(e)))
# Reuse behavior tests against the actual independent Classic source, adapting
# only names/paths and API namespaces. Data-specific Forever tests are excluded.
names=['test-config-menu.lua','test-menu-redesign.lua','test-food-login.lua',
 'test-feedomatic-ammo.lua','test-feedomatic-quests.lua','test-feed-message.lua',
 'test-hunger-alerts.lua','test-ammo-upgrades.lua','test-weapon-comparisons.lua',
 'test-special-food.lua','test-instance-check.lua','test-range.lua','test-pet-heal-range.lua',
 'test-pet-alerts.lua','test-movable-alerts.lua','test-aspect-reminder.lua','test-aspect-button.lua',
 'test-tracking-button.lua','test-pet-list-manager.lua','test-pet-status.lua','test-mob-finder.lua']
for name in names:
    t=(FOREVER/name).read_text(encoding='utf-8-sig')
    t=t.replace('HunterTools Forever','HunterTools Classic')
    t=re.sub(r'HunterTools(?! Classic)','HunterToolsClassic',t).replace('GFWForever','GFWClassic').replace('GFWFOREVER','GFWCLASSIC')
    t=t.replace("'HunterToolsClassic/","'source/HunterToolsClassic/").replace('"HunterToolsClassic/','"source/HunterToolsClassic/')
    for ns,private in [('C_PetInfo','ClassicPetInfo'),('C_SpellBook','ClassicSpellBook'),('C_Spell','ClassicSpell'),('C_UnitAuras','ClassicAuras'),('C_TooltipInfo','ClassicTooltip'),('C_Minimap','ClassicMinimap')]:
        t=re.sub(r'\b'+ns+r'\b','F.'+private,t)
    if name=='test-range.lua':
        t=t.replace("assert(F.TargetRangeStatus()=='Range unavailable')\nUnitExists","assert(F.TargetRangeStatus()=='Out of range')\nUnitExists")
    if name=='test-ammo-upgrades.lua':
        t=t.replace("assert(id==274388)","assert(id==15997, 'Era must not recommend Forever-only ammunition')").replace("assert(F.AmmoUpgradeAdvice(c):find('bind-on-pickup',1,true))","assert(F.ammoUpgradeCatalog[274388]==nil)")
    try:runtime().execute(t);passed.append(name)
    except Exception as e:failures.append((name,str(e)))
after_validation={p.relative_to(forever_root).as_posix():hashlib.sha256(p.read_bytes()).hexdigest() for p in forever_root.rglob('*') if p.is_file()}
assert before_validation==after_validation,'Classic validation modified Forever source'
print(json.dumps({'passed':passed,'failures':failures,'forever_unchanged':True},indent=2))
if failures:sys.exit(1)
