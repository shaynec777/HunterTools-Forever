"""Run after build_ranged_catalog.py; vendors come from separate visible edition pages."""
import json,re,html
from pathlib import Path
ROOT=Path(__file__).resolve().parent
records=json.loads((ROOT/'ranged-catalog.json').read_text(encoding='utf8'))
records=[r for r in records if r['sourceType']!='vendor']
pages=json.loads((ROOT/'vendor-browser.json').read_text(encoding='utf8'))
def price(cell):
 parts=[]
 for unit in ['gold','silver','copper']:
  for amount in re.findall(r'class="money'+unit+r'"[^>]*>([\d,]+)<',cell['html']):parts.append(amount+' '+unit)
 for link in cell['links']:
  if '/item=' in link['url'] or '/currency=' in link['url']:
   parts.append(link['name']+' '+link['url'].rstrip('/').split('/')[-1].replace('-',' '))
 return ', '.join(parts) or 'Price not verified'
missing=[]
for p in pages:
 sellers=[];sides=set();costs=[]
 for row in p['rows']:
  c=row['cells'];i=next((i for i,v in enumerate(c) if any('/npc=' in a['url'] for a in v['links'])),None)
  if i is None:continue
  j=i+(2 if p['edition']=='classic' else 1)
  seller=c[i]['text'].replace('\n',' ');zone=c[j]['text'];side=c[j+1]['text'];stock=c[j+2]['text'];cost=price(c[j+3])
  sides.update(x for x in side if x in 'AH')
  sellers.append(seller+' — '+zone+'; '+('Alliance' if side=='A' else 'Horde' if side=='H' else 'check faction access')+'; stock '+stock+'; '+cost)
  costs.append(cost)
 if not sellers:missing.append((p['edition'],p['id'],p['name']));continue
 stats=p['stats'].split('Sell Price:')[0].strip()
 stats=re.sub(r'\tSoD Phase \d+','',stats)
 damage=re.search(r'([\d.]+)(?: - ([\d.]+))? Damage',stats);speed=re.search(r'Speed\s+([\d.]+)',stats)
 if not damage or not speed:raise ValueError(p['url'])
 required=re.search(r'Requires Level\s+(\d+)',stats)
 requirements='\n'.join(s.strip() for s in stats.splitlines() if s.strip().startswith('Requires'))
 if 'Grand Marshal' in p['name'] or 'High Warlord' in p['name']:
  requirements+='\nRequires Grand Marshal / High Warlord (Rank 14); verify current season/vendor stock.'
  if p['edition']=='classic':sellers=[s+'; Officer\'s Barracks (Stormwind) / Hall of Legends (Orgrimmar), faction-specific quartermaster' for s in sellers]
 if p['edition']=='classic' and p['name'] in ["Outrunner's Bow","Outrider's Bow"]:
  requirements+='\nRequires '+('Silverwing Sentinels' if p['name']=="Outrunner's Bow" else 'Warsong Outriders')+' - Revered'
 category='pvp' if re.search(r'Rank \d|honor|mark of',requirements+' '+' '.join(costs),re.I) else 'reputation' if any(' - ' in s and not 'Level' in s for s in requirements.splitlines()) else 'ordinary'
 r={k:p[k] for k in ['edition','kind','id','name','url']}
 r.update(sourceType='vendor',source='\n'.join(sellers),requirements=requirements or 'No extra item requirement listed; check weapon proficiency and vendor access.',vendorCategory=category,side='Alliance' if sides=={'A'} else 'Horde' if sides=={'H'} else 'Both',stats=stats,level=int(required[1]) if required else 1,min=float(damage[1]),max=float(damage[2] or damage[1]),speed=float(speed[1]),quality=2)
 if p['id']==17753:r['requirements']+='\nQuest-associated vendor; verify completion/prerequisite before attempting purchase.'
 records.append(r)
def lua(v):
 if isinstance(v,str):return '"'+v.replace('\\','\\\\').replace('"','\\"').replace('\r','').replace('\n','\\n').replace('\t',' ')+'"'
 return str(v)
for edition,dest in [('forever','HunterTools'),('classic','classic-port/source/HunterToolsClassic')]:
 rows=[r for r in records if r['edition']==edition];rows.sort(key=lambda r:(r['kind'],r['level'],r['name'],r['id']))
 out=['local _,F=...','-- Independent edition source/tooltip snapshots, 2026-11-15; see RANGED-WEAPONS.md.','F.rangedWeaponCatalog={']
 for r in rows:
  keys=['id','name','kind','level','min','max','speed','stats','source','sourceType','url','quality','requirements','vendorCategory','side']
  out.append(' {'+','.join(k+'='+lua(r[k]) for k in keys if k in r)+'},')
 out.append('}')
 (ROOT.parent.parent/dest/'RangedWeaponData.lua').write_text('\n'.join(out)+'\n',encoding='utf8')
 print(edition,len(rows),'total,',sum(r['sourceType']=='vendor' for r in rows),'vendors')
(ROOT/'ranged-catalog.json').write_text(json.dumps(records,indent=2),encoding='utf8')
print('Pages without verified sellers:',missing)
