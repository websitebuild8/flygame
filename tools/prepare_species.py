"""Normalize licensed fish GLBs for the game; originals remain in Downloads.
Usage: bundled-python tools/prepare_species.py SPECIES SOURCE.glb NODE MESHOPT/index.js
Requires numpy; build-time only. Geometry is reduced with UV/colour-aware meshoptimizer.
"""
import json,struct,sys,tempfile,subprocess,hashlib
from pathlib import Path
import numpy as np
species,source,node,meshopt=sys.argv[1:]
raw=Path(source).read_bytes();n=struct.unpack_from('<I',raw,12)[0]
g=json.loads(raw[20:20+n]);binary=raw[28+n:]
def read(i):
 a=g['accessors'][i];v=g['bufferViews'][a['bufferView']];w={'SCALAR':1,'VEC2':2,'VEC3':3,'VEC4':4}[a['type']]
 dtype={5121:'u1',5123:'<u2',5125:'<u4',5126:'<f4'}[a['componentType']]
 data=np.ndarray((a['count'],w),dtype=dtype,buffer=binary,offset=v.get('byteOffset',0)+a.get('byteOffset',0),strides=(v.get('byteStride',np.dtype(dtype).itemsize*w),np.dtype(dtype).itemsize)).copy()
 if a.get('normalized'):data=data.astype('f4')/np.iinfo(dtype).max
 return data
# All source fish meshes share their coordinates; skipjack's first mesh is a label cube.
prims=[p for m in g['meshes'][1 if species=='skipjack' else 0:] for p in m['primitives']]
bases={'skipjack':[[0,0,-1],[0,1,0],[1,0,0]],'sailfish':[[-1,0,0],[0,1,0],[0,0,-1]],'mahi_mahi':[[1,0,0],[0,1,0],[0,0,1]]}
basis=np.array(bases[species],dtype='f4')
points=np.concatenate([read(p['attributes']['POSITION'])@basis for p in prims]);mid=(points.min(0)+points.max(0))/2;scale=2.4/np.ptp(points[:,2])
buf=bytearray();views=[];acc=[]
def add(data,kind,indices=False):
 buf.extend(b'\0'*(-len(buf)%4));offset=len(buf);data=data.astype('<u4' if indices else '<f4');payload=data.tobytes();buf.extend(payload)
 views.append({'buffer':0,'byteOffset':offset,'byteLength':len(payload)})
 a={'bufferView':len(views)-1,'componentType':5125 if indices else 5126,'count':len(data),'type':kind}
 if kind=='VEC3':a.update(min=data.min(0).tolist(),max=data.max(0).tolist())
 acc.append(a);return len(acc)-1
outprims=[]
for p in prims:
 attrs={}
 for name,i in p['attributes'].items():
  if name not in ['POSITION','NORMAL','TEXCOORD_0','COLOR_0']:continue
  data=read(i)
  if name=='POSITION':data=(data@basis-mid)*scale
  elif name=='NORMAL':data=data@basis
  attrs[name]=add(data,g['accessors'][i]['type'])
 outprims.append({'attributes':attrs,'indices':add(read(p['indices']).ravel(),'SCALAR',True),'material':p.get('material',0)})
for image in g.get('images',[]):
 v=g['bufferViews'][image['bufferView']];payload=binary[v.get('byteOffset',0):v.get('byteOffset',0)+v['byteLength']]
 buf.extend(b'\0'*(-len(buf)%4));offset=len(buf);buf.extend(payload);views.append({'buffer':0,'byteOffset':offset,'byteLength':len(payload)});image['bufferView']=len(views)-1
out={'asset':{'version':'2.0'},'scene':0,'scenes':[{'nodes':[0]}],'nodes':[{'mesh':0,'name':species}],'meshes':[{'primitives':outprims}],'materials':g['materials'],'textures':g.get('textures',[]),'images':g.get('images',[]),'samplers':g.get('samplers',[]),'bufferViews':views,'accessors':acc,'buffers':[{'byteLength':len(buf)}]}
for mat in out['materials']:
 mat.pop('extensions',None);mat.pop('emissiveTexture',None);mat['pbrMetallicRoughness']['roughnessFactor']=.38
 if species=='sailfish':mat['pbrMetallicRoughness']['baseColorFactor']=[1,1,1,1]
with tempfile.TemporaryDirectory(prefix='ishaq-species-') as folder:
 folder=Path(folder);(folder/'input.json').write_text(json.dumps(out));(folder/'input.bin').write_bytes(buf)
 subprocess.run([node,str(Path(__file__).with_name('simplify_species.mjs')),str(folder),meshopt,species],check=True)
Path('assets/models/fish/'+species+'-processing.json').write_text(json.dumps({'original_sha256':hashlib.sha256(raw).hexdigest(),'original_bytes':len(raw),'changes':'Canonical alignment, centering, uniform scale, material preparation, attribute-aware geometry reduction; runtime swimming.'},indent=2)+'\n')
