"""Prepare the CC0 scan: PCA alignment and UV-aware mesh reduction.
Requires numpy and Node meshoptimizer 1.3.0. Neither is required to build the game.
Usage: python prepare_trevally.py SOURCE.glb NODE MESHOPTIMIZER/index.js
The original remains untouched. Output is assets/models/fish/trevally.glb.
"""
import json, struct, sys, subprocess, tempfile, hashlib
from pathlib import Path
import numpy as np
source=Path(sys.argv[1]);raw=source.read_bytes()
n=struct.unpack_from('<I',raw,12)[0];g=json.loads(raw[20:20+n]);binary=raw[28+n:]
def accessor(index):
 a=g['accessors'][index];v=g['bufferViews'][a['bufferView']]
 dtype={5126:'<f4',5125:'<u4',5123:'<u2'}[a['componentType']];width={'SCALAR':1,'VEC2':2,'VEC3':3}[a['type']]
 return np.frombuffer(binary,dtype=dtype,count=a['count']*width,offset=v.get('byteOffset',0)+a.get('byteOffset',0)).reshape(-1,width).copy()
# The first mesh is a separate labelled cube, not part of the fish.
primitives=[p for mesh in g['meshes'][1:] for p in mesh['primitives']]
points=np.concatenate([accessor(p['attributes']['POSITION']) for p in primitives])
center=points.mean(axis=0);_,axes=np.linalg.eigh(np.cov((points-center).T))
# Principal length -> Z, depth -> Y, thickness -> X.
basis=axes[:,[0,1,2]]
if np.linalg.det(basis)<0: basis[:,0]*=-1
# Source scan's snout lies at positive local X; canonical snout faces -Z.
if basis[0,2]>0: basis[:,[0,2]]*=-1
basis[:,[0,1]]*=-1 # Upright dorsal fin orientation for this scan.
canonical=(points-center)@basis
scale=2.4/np.ptp(canonical[:,2]);mid=(canonical.min(axis=0)+canonical.max(axis=0))/2
new_binary=bytearray();views=[];accessors=[]
def add_array(array,kind):
 new_binary.extend(b'\0'*(-len(new_binary)%4));offset=len(new_binary);payload=array.astype('<f4').tobytes();new_binary.extend(payload)
 views.append({'buffer':0,'byteOffset':offset,'byteLength':len(payload)})
 a={'bufferView':len(views)-1,'componentType':5126,'count':len(array),'type':kind}
 if kind=='VEC3': a.update(min=array.min(axis=0).tolist(),max=array.max(axis=0).tolist())
 accessors.append(a);return len(accessors)-1
new_primitives=[]
for p in primitives:
 pos=((accessor(p['attributes']['POSITION'])-center)@basis-mid)*scale
 norm=accessor(p['attributes']['NORMAL'])@basis
 uv=accessor(p['attributes']['TEXCOORD_0'])
 indices=accessor(p['indices']).astype('<u4').ravel()
 attrs={'POSITION':add_array(pos,'VEC3'),'NORMAL':add_array(norm,'VEC3'),'TEXCOORD_0':add_array(uv,'VEC2')}
 new_binary.extend(b'\0'*(-len(new_binary)%4));offset=len(new_binary);new_binary.extend(indices.tobytes())
 views.append({'buffer':0,'byteOffset':offset,'byteLength':indices.nbytes});accessors.append({'bufferView':len(views)-1,'componentType':5125,'count':len(indices),'type':'SCALAR'})
 new_primitives.append({'attributes':attrs,'indices':len(accessors)-1,'material':p['material'],'mode':4})
for image in g['images']:
 v=g['bufferViews'][image['bufferView']];payload=binary[v.get('byteOffset',0):v.get('byteOffset',0)+v['byteLength']]
 new_binary.extend(b'\0'*(-len(new_binary)%4));offset=len(new_binary);new_binary.extend(payload)
 views.append({'buffer':0,'byteOffset':offset,'byteLength':len(payload)});image['bufferView']=len(views)-1
out={'asset':g['asset'],'scenes':[{'nodes':[0]}],'scene':0,'nodes':[{'mesh':0,'name':'GiantTrevally'}],'meshes':[{'primitives':new_primitives}], 'materials':g['materials'],'textures':g['textures'],'images':g['images'],'samplers':g.get('samplers',[]),'accessors':accessors,'bufferViews':views,'buffers':[{'byteLength':len(new_binary)}]}
for material in out['materials']:
 material.pop('extensions',None);material['pbrMetallicRoughness']['roughnessFactor']=.38
with tempfile.TemporaryDirectory(prefix='ishaq-trevally-') as folder:
 folder=Path(folder);(folder/'input.json').write_text(json.dumps(out));(folder/'input.bin').write_bytes(new_binary)
 subprocess.run([sys.argv[2],str(Path(__file__).with_name('simplify_fish.mjs')),str(folder),sys.argv[3]],check=True)
result=Path('assets/models/fish/trevally.glb')
Path('assets/models/fish/trevally-source.json').write_text(json.dumps({'title':'Giant Trevally, Caranx ignobilis','creator':'ffish.asia / floraZia.com','source':g['asset']['extras']['source'],'license':'CC0 1.0','license_url':'https://creativecommons.org/publicdomain/zero/1.0/','original_sha256':hashlib.sha256(raw).hexdigest(),'original_bytes':len(raw),'game_bytes':result.stat().st_size,'changes':'Removed separate label cube, aligned/centred fish, welded split meshes and reduced geometry with UV-aware meshoptimizer; retained source 1k colour textures; lit wet-fish material and runtime body/tail deformation.'},indent=2)+'\n')
