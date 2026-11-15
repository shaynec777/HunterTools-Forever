"""Rebuild the separately licensed Classic vendor data from its editable JSON."""
from pathlib import Path
import json

root = Path(__file__).resolve().parent
data = json.loads((root / 'ammo-vendor-classic-source.json').read_text(encoding='utf8'))

def lua(value):
    if isinstance(value, str):
        return json.dumps(value)
    if isinstance(value, list):
        return '{' + ','.join(lua(item) for item in value) + '}'
    return str(value)

lines = ['local _,F=...', '-- CMaNGOS Classic DB factual subset, modified; GPL-3.0. See AMMO-VENDORS.md.', 'F.ammoVendorCatalog={']
for row in data['records']:
    lines.append(' {' + ','.join(key + '=' + lua(value) for key, value in row.items()) + '},')
lines.append('}')
(root / 'source/HunterToolsClassic/AmmoVendorData.lua').write_text('\n'.join(lines) + '\n', encoding='utf8')
print(len(data['records']), 'Classic sellers generated')
