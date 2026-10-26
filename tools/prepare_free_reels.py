"""Prepare Sobrom's CC BY reel as independently moving textured parts.
Usage: Python with numpy, tools/prepare_free_reels.py original.glb output.glb
Original downloads are preserved. See free-tackle-source.json for attribution.
"""
import sys,json,struct,hashlib
from pathlib import Path
import numpy as np
raw=Path(sys.argv[1]).read_bytes();size=struct.unpack_from('<I',raw,12)[0];d=json.loads(raw[20:20+size]);blob=bytearray(raw[28+size:])
types={5126:np.dtype('<f4'),5123:np.dtype('<u2'),5125:np.dtype('<u4')};cols={'SCALAR':1,'VEC2':2,'VEC3':3,'VEC4':4}
def read(i):
 a=d['accessors'][i];v=d['bufferViews'][a['bufferView']];dt=types[a['componentType']];n=cols[a['type']]
 return np.ndarray((a['count'],n),dtype=dt,buffer=blob,offset=v.get('byteOffset',0)+a.get('byteOffset',0),strides=(v.get('byteStride',n*dt.itemsize),dt.itemsize)).copy()
pr=d['meshes'][0]['primitives'][0];attributes={k:read(v) for k,v in pr['attributes'].items() if k!='TANGENT'};vertices=attributes['POSITION'];indices=read(pr['indices']).reshape(-1,3);parents=list(range(len(vertices)));same={}
def find(i):
 while parents[i]!=i:parents[i]=parents[parents[i]];i=parents[i]
 return i
def union(a,b):parents[find(a)]=find(b)
for i,v in enumerate(vertices):
 key=tuple(np.round(v,5))
 if key in same:union(i,same[key])
 else:same[key]=i
for a,b,c in indices:union(a,b);union(a,c)
groups={}
for t in indices:groups.setdefault(find(int(t[0])),[]).append(t)
groups=sorted(groups.values(),key=len,reverse=True)
# Source components: spool, rotor/bail, mounting body, crank and knob.
selection={'Body':[2,6,8,10],'Rotor':[1,3,5,7,11,12],'Spool':[0],'Crank':[4,9]}
factor=.44/3.616791
basis=np.array([[-1,0,0],[0,0,1],[0,-1,0]],dtype='<f4')
pivots={'Body':np.zeros(3),'Rotor':np.array([0,0,.02]),'Spool':np.array([0,1.64,.026]),'Crank':np.array([-.28,-.05,.145])}
def add(a,typ,ctype=5126):
 a=np.asarray(a,dtype=types[ctype]);blob.extend(b'\0'*((-len(blob))%4));vi=len(d['bufferViews']);d['bufferViews'].append({'buffer':0,'byteOffset':len(blob),'byteLength':a.nbytes});blob.extend(a.tobytes());ac={'bufferView':vi,'componentType':ctype,'count':len(a),'type':typ}
 if typ=='VEC3':ac.update(min=a.min(0).tolist(),max=a.max(0).tolist())
 ai=len(d['accessors']);d['accessors'].append(ac);return ai
meshes=[];nodes=[{'name':'SobromSpinningReel','children':[1,2,3,4]}]
for name,ids in selection.items():
 triangles=np.concatenate([groups[i] for i in ids]);used,inverse=np.unique(triangles,return_inverse=True);out={};pivot=pivots[name]
 for key,a in attributes.items():
  a=a[used]
  if key=='POSITION':a=(a-pivot)@basis.T*factor
  elif key=='NORMAL':a=a@basis.T
  out[key]=add(a,'VEC'+str(a.shape[1]))
 ix=add(inverse.reshape(-1,3)[:,[0,2,1]].reshape(-1,1),'SCALAR',5123)
 meshes.append({'name':name,'primitives':[{'attributes':out,'indices':ix,'material':0}]})
 nodes.append({'name':name,'mesh':len(meshes)-1,'translation':(basis@pivot*factor).tolist()})
 d.pop('animations',None)
d['meshes']=meshes;d['nodes']=nodes;d['scenes']=[{'nodes':[0]}];d['scene']=0;d['buffers']=[{'byteLength':len(blob)}]
j=json.dumps(d,separators=(',',':')).encode();j+=b' '*((-len(j))%4);blob.extend(b'\0'*((-len(blob))%4));out=struct.pack('<III',0x46546c67,2,28+len(j)+len(blob))+struct.pack('<II',len(j),0x4e4f534a)+j+struct.pack('<II',len(blob),0x004e4942)+blob;Path(sys.argv[2]).write_bytes(out)
foot=vertices[vertices[:,2]>vertices[:,2].max()-.003].mean(0)
print('mount_foot',basis@foot*factor,'crank_grip',basis@(np.array([-1.748,1.204,.145])-pivots['Crank'])*factor,'bytes',len(out))
