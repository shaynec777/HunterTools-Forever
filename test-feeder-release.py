from pathlib import Path
import sys,zipfile,hashlib
sys.path.insert(0,'.test-tools')
from lupa.lua51 import LuaRuntime
for folder,entry,api in [('HunterTools','HunterTools.lua','C_PetInfo'),('classic-port/source/HunterToolsClassic','HunterToolsClassic.lua','F.ClassicPetInfo')]:
 lua=LuaRuntime();s=(Path(folder)/entry).read_text();render=s[s.index('function F.Render(mode)'):s.index('function F.BuildUI()')]
 lua.execute('''F={db={},supported=true,foodCount=7}; value=3; combat=false; exists=true
 InCombatLockdown=function() return combat end
 UnitExists=function() return exists end
 UnitIsDeadOrGhost=function() return false end
 F.IsPublic=function(v) return type(v)=='number' end
 F.UpdateHappinessBorder=function() end
 F.NoFoodTint=function() return false end
 F.TooltipStatus=function() return 'Verbose status' end
 F.button={icon={SetDesaturated=function() end,SetVertexColor=function() end},label={SetText=function(_,v) label=v end},Show=function() end}
 ''')
 lua.execute(api+'={GetPetHappiness=function() assert(not combat);return value end}')
 lua.execute(render)
 lua.execute('''F.Render('food');assert(label=='7 food')
 F.db.feederTextMode='simplified';F.Render('hidden');assert(label=='Happy')
 value=2;F.Render('food');assert(label=='Not happy')
 value=1;F.Render('food');assert(label=='Not happy')
 value=nil;F.Render('hidden');assert(label=='')
 value=3;combat=true;F.Render('hidden');assert(label=='')
 combat=false;exists=false;F.Render('hidden');assert(label=='')
 F.db.feederTextMode='off';F.Render('food');assert(label=='')
 ''')
 for p in Path(folder).glob('*.lua'):
  result=lua.eval('loadstring')(p.read_text(encoding='utf-8-sig'));assert not isinstance(result,tuple),(p,result)
 print(folder+': feeder modes and Lua 5.1 syntax passed')
for name in ['test-config-menu.lua','test-menu-redesign.lua','test-food-login.lua','test-range.lua','test-pet-heal-range.lua']:
 LuaRuntime().execute(Path(name).read_text(encoding='utf-8-sig'));print(name+': passed')

