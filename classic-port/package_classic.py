from pathlib import Path
import runpy, json, hashlib, zipfile, contextlib, io, sys
ROOT=Path(__file__).resolve().parent
output=io.StringIO()
try:
    with contextlib.redirect_stdout(output):runpy.run_path(str(ROOT/'validate_classic.py'),run_name='__main__')
except SystemExit:
    print(output.getvalue());raise
validation=json.loads(output.getvalue())
addon=ROOT/'source/HunterToolsClassic'
files=sorted(p for p in addon.rglob('*') if p.is_file())
dest=ROOT/'releases';dest.mkdir(exist_ok=True)
preview='--preview' in sys.argv
archive=dest/('HunterToolsClassic-tameability-preview.zip' if preview else 'HunterToolsClassic-3.1.7.zip')
with zipfile.ZipFile(archive,'w',zipfile.ZIP_DEFLATED,compresslevel=9) as z:
    for p in files:z.write(p,p.relative_to(addon.parent).as_posix())
with zipfile.ZipFile(archive) as z:
    assert z.testzip() is None
    assert {n.split('/')[0] for n in z.namelist()}=={'HunterToolsClassic'}
    for p in files:assert z.read(p.relative_to(addon.parent).as_posix())==p.read_bytes()
data={'version':'3.1.7','target':'Classic Era 1.15.9 / interface 11509','date':'2026-10-21',
      'status':'local test package; not published','archive':archive.name,
      'sha256':hashlib.sha256(archive.read_bytes()).hexdigest(),'bytes':archive.stat().st_size,
      'validation':validation,'live_game_testing':'pending',
      'files':{p.relative_to(addon.parent).as_posix():hashlib.sha256(p.read_bytes()).hexdigest() for p in files}}
(dest/('HunterToolsClassic-tameability-preview-package.json' if preview else 'HunterToolsClassic-3.1.7-package.json')).write_text(json.dumps(data,indent=2)+'\n',encoding='utf-8')
print(json.dumps({k:data[k] for k in ('archive','bytes','sha256','status')},indent=2))
print('Passed suites:',len(validation['passed']))
