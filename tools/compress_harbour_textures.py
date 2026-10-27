"""Externalise mobile-size WebP maps from the prepared rock GLB, without changing mesh data."""
from pathlib import Path
from PIL import Image
import json, struct, io
ROOT=Path(__file__).resolve().parents[1]/'assets/models/harbour'
p=ROOT/'armour_rock.glb';data=p.read_bytes();n=struct.unpack_from('<I',data,12)[0];doc=json.loads(data[20:20+n]);chunk=20+n;binary=data[chunk+8:]
if not any('bufferView' in image for image in doc.get('images',[])):
 print('Rock textures already external');raise SystemExit
source=ROOT/'source';source.mkdir(exist_ok=True);(source/'.gdignore').touch();(source/'armour_rock-embedded.glb').write_bytes(data)
image_views=set()
for i,image in enumerate(doc['images']):
 view=doc['bufferViews'][image['bufferView']];image_views.add(image['bufferView'])
 start=view.get('byteOffset',0);pixels=Image.open(io.BytesIO(binary[start:start+view['byteLength']])).convert('RGB')
 name=f'armour_rock_map_{i}.webp';pixels.save(ROOT/name,format='WEBP',quality=90,method=6)
 image.clear();image['uri']=name
views=[];remap={};packed=bytearray()
for old,view in enumerate(doc['bufferViews']):
 if old in image_views:continue
 while len(packed)%4:packed.append(0)
 start=view.get('byteOffset',0);block=binary[start:start+view['byteLength']]
 fresh=dict(view);fresh['byteOffset']=len(packed);fresh['buffer']=0
 remap[old]=len(views);views.append(fresh);packed.extend(block)
for accessor in doc['accessors']:
 if 'bufferView' in accessor:accessor['bufferView']=remap[accessor['bufferView']]
doc['bufferViews']=views;doc['buffers']=[{'byteLength':len(packed)}]
header=json.dumps(doc,separators=(',',':')).encode();header+=b' '*((-len(header))%4);packed+=b'\0'*((-len(packed))%4)
p.write_bytes(struct.pack('<III',0x46546c67,2,28+len(header)+len(packed))+struct.pack('<II',len(header),0x4e4f534a)+header+struct.pack('<II',len(packed),0x004e4942)+packed)
# Preserve generated embedded-source PNGs outside Godot's import/export tree.
for old in ROOT.glob('armour_rock_*.png'):
 old.replace(source/old.name)
 side=Path(str(old)+'.import')
 if side.exists():side.replace(source/side.name)
print('Prepared shared mesh plus compressed WebP texture maps')
