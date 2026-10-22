"""Reduce embedded textures while retaining the source GLB mesh, rig and animation.
Usage: /usr/bin/python3 tools/prepare_tuna.py /path/tuna_fish.glb
Requires Pillow. The unmodified source stays outside the exported game.
"""
import io,json,struct,sys,hashlib
from pathlib import Path
from PIL import Image
source=Path(sys.argv[1]); raw=source.read_bytes()
assert raw[:4]==b'glTF' and struct.unpack_from('<I',raw,4)[0]==2
json_length=struct.unpack_from('<I',raw,12)[0]
gltf=json.loads(raw[20:20+json_length]); binary=raw[28+json_length:]
replacements={}
for index,image in enumerate(gltf.get('images',[])):
 view=gltf['bufferViews'][image['bufferView']]
 original=binary[view.get('byteOffset',0):view.get('byteOffset',0)+view['byteLength']]
 texture=Image.open(io.BytesIO(original))
 limit=1024 if index<3 else 512
 texture.thumbnail((limit,limit),Image.Resampling.LANCZOS)
 result=io.BytesIO();texture.save(result,format='PNG',optimize=True)
 replacements[image['bufferView']]=result.getvalue()
new_binary=bytearray()
for index,view in enumerate(gltf['bufferViews']):
 payload=replacements.get(index,binary[view.get('byteOffset',0):view.get('byteOffset',0)+view['byteLength']])
 new_binary.extend(b'\0'*(-len(new_binary)%4))
 view['byteOffset']=len(new_binary);view['byteLength']=len(payload)
 new_binary.extend(payload)
gltf['buffers'][0]['byteLength']=len(new_binary)
new_binary.extend(b'\0'*(-len(new_binary)%4))
json_bytes=json.dumps(gltf,separators=(',',':')).encode();json_bytes+=b' '*(-len(json_bytes)%4)
output=struct.pack('<III',0x46546c67,2,28+len(json_bytes)+len(new_binary))+struct.pack('<II',len(json_bytes),0x4e4f534a)+json_bytes+struct.pack('<II',len(new_binary),0x004e4942)+new_binary
folder=Path('assets/models/fish');folder.mkdir(parents=True,exist_ok=True)
(folder/'tuna.glb').write_bytes(output)
(folder/'tuna-source.json').write_text(json.dumps({'title':'Tuna Fish','creator':'GoldenZtuff','source':'https://www.fab.com/listings/6b90bbe2-3031-4b36-93ad-90f1cb2d01f5','license':'CC BY 4.0','license_url':'https://creativecommons.org/licenses/by/4.0/','original_sha256':hashlib.sha256(raw).hexdigest(),'changes':'Body texture maps reduced to 1024px, eye maps to 512px; GLB buffer repacked. Geometry, rig and Swim animation retained.','original_bytes':len(raw),'game_bytes':len(output)},indent=2)+'\n')
print(f'Tuna GLB: {len(raw)/1048576:.1f} MB -> {len(output)/1048576:.1f} MB')
