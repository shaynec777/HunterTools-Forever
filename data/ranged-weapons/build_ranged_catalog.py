import json,re,html,urllib.request,concurrent.futures
from pathlib import Path
ROOT=Path(__file__).resolve().parent
raw=json.loads((ROOT/'ranged-weapon-browser.json').read_text())
instances={491,718,719,209,1581,717,1337,721,796,722,1477,1584,1583,2017,2057,2100,2557,2437,2717,2677,1977,3428,3429,3456,16620,16732,16550}
records=[]
for key,pages in raw['lists'].items():
 edition,kind=key.split('-')
 for row in [r for p in pages for r in p['rows']]:
  cells=row['cells'];source=cells[-2];links=source['links']
  item=next((a for c in cells[:-2] for a in c['links'] if 'item=' in a['url'] and a['name']),None)
  if not item or 'Unconfirmed' in cells[1]['text']:continue
  craft=any('/spell=' in a['url'] for a in links)
  zone=next((int(re.search(r'zone=(\d+)',a['url'])[1]) for a in links if '/zone=' in a['url']),None)
  if not craft and (zone not in instances or any(x in source['text'] for x in ['Quests','Vendor']) or any('/quest=' in a['url'] for a in links)):continue
  records.append(dict(edition=edition,kind=kind,id=int(re.search(r'item=(\d+)',item['url'])[1]),name=item['name'],source=source['text'].replace('\n',' â€” '),sourceType='crafted' if craft else 'instance',url=item['url'],sourceURLs=[a['url'] for a in links]))
cache=ROOT/'ranged-tooltips';cache.mkdir(exist_ok=True)
def fetch(r):
 p=cache/f"{r['edition']}-{r['id']}.json"
 if not p.exists():
  req=urllib.request.Request(f"https://nether.wowhead.com/{r['edition']}/tooltip/item/{r['id']}",headers={'User-Agent':'Mozilla/5.0'})
  p.write_bytes(urllib.request.urlopen(req,timeout=30).read())
 d=json.loads(p.read_text());t=d['tooltip']
 # Preserve every displayed stat/effect, excluding vendor sell price.
 t=t.split('<div class="whtt-sellprice">')[0]
 t=re.sub(r'<(?:br|table|/tr|/table)[^>]*>','\n',t);t=re.sub(r'</(?:td|th)>','  ',t)
 lines=[re.sub(r'\s+',' ',html.unescape(re.sub('<[^>]*>','',s))).strip() for s in t.splitlines()]
 r['stats']='\n'.join(s for s in lines if s);r['quality']=d['quality']
 damage=re.search(r'<!--dmg-->([\d.]+) - ([\d.]+)',d['tooltip']);speed=re.search(r'<!--spd-->([\d.]+)',d['tooltip'])
 level=re.search(r'<!--rlvl-->(\d+)',d['tooltip'])
 r.update(level=int(level[1]) if level else 1,min=float(damage[1]) if damage else 0,max=float(damage[2]) if damage else 0,speed=float(speed[1]) if speed else 0)
 return r
with concurrent.futures.ThreadPoolExecutor(max_workers=8) as pool: records=list(pool.map(fetch,records))
(ROOT/'ranged-catalog.json').write_text(json.dumps(records,indent=2),encoding='utf-8')
def lua(v):
 if isinstance(v,str):return '"'+v.replace('\\','\\\\').replace('"','\\"').replace('\n','\\n')+'"'
 if isinstance(v,(int,float)):return str(v)
 raise TypeError(v)
for edition,dest in [('forever','HunterTools'),('classic','classic-port/source/HunterToolsClassic')]:
 rows=[r for r in records if r['edition']==edition];rows.sort(key=lambda r:(r['kind'],r['level'],r['name']))
 out=['local _,F=...','-- Separate edition snapshot: Wowhead visible source lists and public item tooltips, 2026-11-15.','F.rangedWeaponCatalog={']
 for r in rows:
  out.append(' {'+','.join(k+'='+lua(r[k]) for k in ['id','name','kind','level','min','max','speed','stats','source','sourceType','url','quality'])+'},')
 out.append('}')
 (ROOT.parent.parent/dest/'RangedWeaponData.lua').write_text('\n'.join(out)+'\n',encoding='utf-8')
 print(edition,len(rows))
