"""Compile ordinary-ammo sellers observed in Wowhead Forever's visible listings.
No Classic, Questie, or other addon data is used. Rebuild from the archived DOM
facts after collecting all eight item seller tables and their NPC map pins.
"""
import json,re
from pathlib import Path
root=Path(__file__).resolve().parent
src=root.parent/'reference-data/forever-ammo-vendors.json'
data=json.loads(src.read_text())
assert set(data['items'])=={'2512','2515','2516','2519','3030','3033','11284','11285'}
mapIDs={1:1426,3:1418,4:1419,8:1435,10:1431,11:1437,12:1429,14:1411,15:1445,16:1447,17:1413,28:1422,33:1434,36:1416,38:1432,40:1436,41:1430,44:1433,45:1417,46:1428,47:1425,51:1427,85:1420,130:1421,139:1423,141:1438,148:1439,215:1412,267:1424,331:1440,357:1444,361:1448,400:1441,405:1443,406:1442,440:1446,490:1449,493:1450,618:1452,1377:1451,1519:1453,1537:1455,1497:1458,1637:1454,1638:1456,1657:1457,2597:1459}
records={}
for item,rows in data['items'].items():
    for row in rows:
        link=next(a for a in row['links'] if 'npc=' in a['url']);npc=int(re.search(r'npc=(\d+)',link['url'])[1])
        r=records.setdefault(npc,{'id':npc,'name':link['name'],'url':link['url'],'items':set(),'reaction':set()})
        r['items'].add(int(item));r['reaction'].update(row['cells'][3].split())
for npc,r in records.items():
    r['items']=sorted(r['items']);reaction=r.pop('reaction');r['faction']='Neutral' if reaction=={'A','H'} else 'Alliance' if reaction=={'A'} else 'Horde' if reaction=={'H'} else 'Unknown'
    evidence=data['npcs'].get(str(npc),{})
    assert not evidence.get('head','').startswith("Let's confirm"),f'Unfinished verification for {npc}'
    assert evidence.get('head','').startswith(r['name']),f'Wrong NPC page for {npc}'
    maps=[m for m in evidence.get('maps',[]) if m.get('link') and m.get('pins')]
    if maps:
        m=maps[0];r['areaID']=int(re.search(r'zone=(\d+)',m['link'])[1]);r['zone']=m['zone'];r['x']=float(m['pins'][0]['x'].rstrip('%'))/100;r['y']=float(m['pins'][0]['y'].rstrip('%'))/100
        assert 0<=r['x']<=1 and 0<=r['y']<=1
        if r['areaID'] in mapIDs:r['mapID']=mapIDs[r['areaID']]
    else:r['zone']=next((row['cells'][2] for rows in data['items'].values() for row in rows if any('npc='+str(npc)+'/' in a['url'] for a in row['links'])),'Unknown')
    r['source']='Wowhead Forever'
shops=json.loads((root/'ammo-vendor-shops.json').read_text())['shops']
for npc,r in records.items():
    if str(npc) in shops:r['shop']=shops[str(npc)]
records=sorted(records.values(),key=lambda r:r['id'])
(root/'ammo-vendor-forever-source.json').write_text(json.dumps({'date':data['date'],'source':'Wowhead Forever visible item sold-by tables and NPC map pins','records':records},indent=2)+'\n')
def lua(v):
    if isinstance(v,str):return json.dumps(v,ensure_ascii=True)
    if isinstance(v,list):return '{'+','.join(lua(x) for x in v)+'}'
    return str(v)
lines=['local _,F=...','-- Independently bundled factual reference from Wowhead Forever, '+data['date']+'.','-- Only item-specific Forever stock; reported map pins, not live NPC tracking. See AMMO-VENDORS.md.','F.ammoVendorCatalog={']
for r in records:lines.append(' {'+','.join(k+'='+lua(v) for k,v in r.items() if k not in ('url','source'))+'},')
lines.append('}')
(root/'HunterTools/AmmoVendorData.lua').write_text('\n'.join(lines)+'\n')
print(len(records),'Forever-specific sellers;',sum('x' in r for r in records),'with map coordinates')
