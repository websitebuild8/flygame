"""Prepare BoatUS Foundation CC BY 4.0 boats for mobile Godot gameplay.
Usage: python prepare_boats.py whaler|scout|grady|glacier SOURCE.glb NODE MESHOPTIMIZER/index.js
Requires numpy and meshoptimizer at preparation time only. Originals stay untouched.
"""
import json,struct,sys,tempfile,subprocess,hashlib
from pathlib import Path
import numpy as np
key,filename,node,meshopt=sys.argv[1:];raw=Path(filename).read_bytes();n=struct.unpack_from('<I',raw,12)[0];g=json.loads(raw[20:20+n]);binary=raw[28+n:]
def read(i):
 a=g['accessors'][i];v=g['bufferViews'][a['bufferView']];w={'SCALAR':1,'VEC2':2,'VEC3':3,'VEC4':4}[a['type']];dt={5126:'<f4',5123:'<u2',5125:'<u4',5121:'u1'}[a['componentType']]
 return np.ndarray((a['count'],w),dtype=dt,buffer=binary,offset=v.get('byteOffset',0)+a.get('byteOffset',0),strides=(v.get('byteStride',np.dtype(dt).itemsize*w),np.dtype(dt).itemsize)).copy()
# Raw OBJ frame: X across, Z up, Y sternwards. Both hulls face -Y.
basis=np.array([[-1,0,0],[0,0,1],[0,1,0]],dtype='f4');factor=.82 if key=='whaler' else .9;offset=np.array([0,.65 if key=='whaler' else -.30,0],dtype='f4')
if key=='grady':
 basis=np.diag([-1,1,-1]).astype('f4');factor=.8;offset=np.array([0,-.65,0],dtype='f4')
elif key=='glacier':
 factor=.85;offset=np.array([0,-.5,0],dtype='f4')
def canonical(p):return np.asarray(p)@basis*factor+offset
parts={};removed=0
wheel_reference=None
# Connected components preserve small moving parts even in the material-merged source OBJ.
for mi,m in enumerate(g['meshes']):
 for p in m['primitives']:
  pos=read(p['attributes']['POSITION']);idx=read(p['indices']).ravel();dominant=None
  if key=='grady':
   joints=read(p['attributes']['JOINTS_0']);weights=read(p['attributes']['WEIGHTS_0']);dominant=joints[np.arange(len(joints)),weights.argmax(1)]
  parents=list(range(len(pos)));same={}
  def find(i):
   while parents[i]!=i:parents[i]=parents[parents[i]];i=parents[i]
   return i
  def union(a,b):parents[find(a)]=find(b)
  for i,point in enumerate(pos):
   k=tuple(np.round(point,5))
   if k in same:union(i,same[k])
   else:same[k]=i
  for a,b,c in idx.reshape(-1,3):union(a,b);union(a,c)
  groups={}
  for tri in idx.reshape(-1,3):groups.setdefault(find(tri[0]),[]).append(tri)
  for component,tris in groups.items():
   tris=np.array(tris);pts=pos[np.unique(tris)];lo=pts.min(0);hi=pts.max(0);center=(lo+hi)/2
   part='Hull'
   if key=='grady':
    joint=int(dominant[np.unique(tris)][0])
    if joint==8:part='HelmWheel'
    elif joint in [4,6]:part='OutboardPivotPropeller' if center[0]>0 else 'OutboardPivot2Propeller'
    elif lo[2]<-4.1 and hi[2]<-3.9 and abs(center[0])>.12 and abs(center[0])<.75 and hi[0]-lo[0]<1:
     part='OutboardPivot' if center[0]>0 else 'OutboardPivot2'
    elif mi==3 and int(component) in [5644,6479,5883,6717,6006,5172]:part='ThrottleLever'
   elif key=='glacier':
    if lo[1]>3.75 and abs(center[0])>.38 and abs(center[0])<1.1 and hi[2]<1.75:
     part='OutboardPivot' if center[0]>0 else 'OutboardPivot2'
     if lo[1]>4.43 and hi[2]<.2:part+='Propeller'
    elif lo[0]>.18 and hi[0]<.52 and lo[1]>-.02 and hi[1]<.29 and lo[2]>1.68 and hi[2]<1.97:
     part='HelmWheel'
    elif lo[0]>-.055 and hi[0]<.09 and lo[1]>.06 and hi[1]<.19 and lo[2]>1.68 and hi[2]<1.89:
     part='ThrottleLever'
   elif key=='whaler':
    if mi==3:
     part='OutboardPivot' if center[0]>0 else 'OutboardPivot2'
     # The three propeller blades and hub, behind the gearcase; exclude the skeg.
     if lo[1]>4.43 and hi[2]<-1.24:part+='Propeller'
    elif lo[0]>-.78 and hi[0]<-.25 and lo[1]>-.60 and hi[1]<-.20 and lo[2]>.15 and hi[2]<.65:
     part='HelmWheel'
    elif lo[0]>-.99 and hi[0]<-.76 and lo[1]>-.25 and hi[1]<-.10 and lo[2]>.30 and hi[2]<.50:
     part='ThrottleLever'
   else:
    # Source material 6 is the separate road trailer, including wheels and tongue.
    trailer=mi==9 or (hi[1]<-2.4 and lo[0]>-.3 and hi[0]<.3 and hi[2]<1.05)
    # Trailer guide posts and caps at either side of the stern.
    trailer=trailer or (abs(center[0])>.72 and lo[1]>2.25 and hi[1]<2.75 and hi[0]-lo[0]<.16 and hi[1]-lo[1]<.16)
    if trailer:removed+=len(tris);continue
    if lo[1]>2.42 and hi[2]<.87 and abs(center[0])<.5:
     part='OutboardPivot'
     if lo[1]>2.97 and hi[1]<3.15 and hi[2]<0 and lo[2]>-.32:part+='Propeller'
    elif lo[0]>.04 and hi[0]<.36 and lo[1]>.40 and hi[1]<.67 and lo[2]>1.08 and hi[2]<1.36:
     part='HelmWheel'
    # Original starboard lever, grip and trigger; the radio and control housing stay fixed.
    elif lo[0]>-.19 and hi[0]<-.08 and lo[1]>.426 and hi[1]<.65 and lo[2]>1.06 and hi[2]<1.28 and not (mi==3 and int(component)==32373) and not (mi==4 and int(component) in [42495,42396]):
     part='ThrottleLever'
   attrs={name:read(i) for name,i in p['attributes'].items() if name in ['POSITION','NORMAL','TEXCOORD_0']}
   sel=np.unique(tris);remap=np.full(len(pos),-1,dtype=np.int32);remap[sel]=np.arange(len(sel))
   attrs={name:arr[sel] for name,arr in attrs.items()};attrs['POSITION']=canonical(attrs['POSITION']);attrs['NORMAL']=attrs['NORMAL']@basis
   parts.setdefault(part,[]).append((p['material'],attrs,remap[tris].ravel().astype('<u4')))
   if part=='HelmWheel' and ((key=='grady' and mi==3 and int(component)==7255) or (key=='glacier' and mi==2 and int(component)==25487) or (key=='scout' and mi==4 and int(component)==29131) or (key=='whaler' and mi==5 and int(component)==15672)):wheel_reference=canonical(pts)
assert 'HelmWheel' in parts and 'OutboardPivot' in parts and 'ThrottleLever' in parts
# Fit bearing axes to the wheel geometry, not the whole boat or handle bounds.
wheel=wheel_reference if wheel_reference is not None else np.concatenate([p[1]['POSITION'] for p in parts['HelmWheel']]);wheel_center=(wheel.min(0)+wheel.max(0))/2
_,axes=np.linalg.eigh(np.cov((wheel-wheel_center).T));shaft=axes[:,0]
if shaft[2]<0:shaft=-shaft
x=np.array([1,0,0],dtype='f4');y=np.cross(shaft,x);y/=np.linalg.norm(y);x=np.cross(y,shaft);wheel_basis=np.column_stack([x,y,shaft])
pivots={'Hull':np.zeros(3),'HelmWheel':wheel_center}
for name,entries in parts.items():
 if name in pivots:continue
 pts=np.concatenate([entry[1]['POSITION'] for entry in entries]);center=(pts.min(0)+pts.max(0))/2
 if name.startswith('OutboardPivot') and not name.endswith('Propeller'):
  if key=='grady':center=canonical([.37 if name=='OutboardPivot' else -.37,1.0,-4.25])
  elif key=='glacier':center=canonical([.77 if name=='OutboardPivot' else -.77,3.86,.8])
  else:
   center[1]=canonical([0,0,-.30 if key=='whaler' else .55])[1]
   center[2]=canonical([0,3.85 if key=='whaler' else 2.55,0])[2]
 if name=='ThrottleLever':center[1]=pts[:,1].min()
 if name=='ThrottleLever' and key=='scout':center=canonical([-.134,.445,1.09])
 if name=='ThrottleLever' and key=='grady':center=canonical([-1.356,1.587,-.49])
 if name=='ThrottleLever' and key=='glacier':center=canonical([.017, .11,1.73])
 if name.endswith('Propeller'):
  if key=='grady':center=canonical([.3704 if name=='OutboardPivotPropeller' else -.3704,.05075,-5.08])
  elif key=='glacier':center=canonical([.77 if name=='OutboardPivotPropeller' else -.77,4.55,-.0243])
  elif key=='scout':center=canonical([0,3.05,-.135])
  else:center=canonical([.3525 if name=='OutboardPivotPropeller' else -.3525,4.55,-1.425])
 pivots[name]=center
buf=bytearray();views=[];acc=[]
def add(data,kind,index=False):
 buf.extend(b'\0'*(-len(buf)%4));offset=len(buf);data=data.astype('<u4' if index else '<f4');payload=data.tobytes();buf.extend(payload);views.append({'buffer':0,'byteOffset':offset,'byteLength':len(payload)})
 a={'bufferView':len(views)-1,'componentType':5125 if index else 5126,'count':len(data),'type':kind}
 if kind=='VEC3':a.update(min=data.min(0).tolist(),max=data.max(0).tolist())
 acc.append(a);return len(acc)-1
nodes=[{'name':key,'children':[]}];meshes=[]
for name,entries in parts.items():
 # Merge components by material before simplifying to avoid hundreds of draw calls.
 merged={}
 for mat,attrs,idx in entries:merged.setdefault(mat,[]).append((attrs,idx))
 primitives=[]
 for mat,groups in merged.items():
  attrs={};indices=[];base=0
  for values,idx in groups:
   indices.append(idx+base);base+=len(values['POSITION'])
   for attr,arr in values.items():attrs.setdefault(attr,[]).append(arr)
  attrs={attr:np.concatenate(arrays) for attr,arrays in attrs.items()};attrs['POSITION']-=pivots[name]
  if name=='HelmWheel':
   attrs['POSITION']=attrs['POSITION']@wheel_basis;attrs['NORMAL']=attrs['NORMAL']@wheel_basis
  primitives.append({'material':mat,'attributes':{attr:add(arr,{'POSITION':'VEC3','NORMAL':'VEC3','TEXCOORD_0':'VEC2'}[attr]) for attr,arr in attrs.items()},'indices':add(np.concatenate(indices),'SCALAR',True)})
 nd={'name':name,'mesh':len(meshes),'translation':pivots[name].tolist()}
 if name=='HelmWheel':
  transform=np.eye(4);transform[:3,:3]=wheel_basis;transform[:3,3]=pivots[name];nd.pop('translation');nd['matrix']=transform.T.ravel().tolist()
 nodes[0]['children'].append(len(nodes));nodes.append(nd);meshes.append({'name':name,'primitives':primitives})
# Propeller node transforms are relative to their outboard bearing.
for i,nd in enumerate(nodes):
 if nd['name'].endswith('Propeller'):
  motor_name=nd['name'].removesuffix('Propeller');parent=next(k for k,v in enumerate(nodes) if v['name']==motor_name)
  nodes[0]['children'].remove(i);nodes[parent].setdefault('children',[]).append(i);nd['translation']=(pivots[nd['name']]-pivots[motor_name]).tolist();nd['name']='Propeller'
for image in g.get('images',[]):
 v=g['bufferViews'][image['bufferView']];payload=binary[v.get('byteOffset',0):v.get('byteOffset',0)+v['byteLength']];buf.extend(b'\0'*(-len(buf)%4));off=len(buf);buf.extend(payload);views.append({'buffer':0,'byteOffset':off,'byteLength':len(payload)});image['bufferView']=len(views)-1
for mat in g['materials']:
 mat.pop('extensions',None)
 if 'glass' not in mat['name'].lower():mat['alphaMode']='MASK';mat['alphaCutoff']=.4
out={'asset':{'version':'2.0'},'scene':0,'scenes':[{'nodes':[0]}],'nodes':nodes,'meshes':meshes,'materials':g['materials'],'textures':g.get('textures',[]),'images':g.get('images',[]),'samplers':g.get('samplers',[]),'bufferViews':views,'accessors':acc,'buffers':[{'byteLength':len(buf)}]}
used_mats=sorted({p['material'] for m in out['meshes'] for p in m['primitives']})
mat_map={old:new for new,old in enumerate(used_mats)}
out['materials']=[out['materials'][i] for i in used_mats]
for m in out['meshes']:
 for p in m['primitives']:p['material']=mat_map[p['material']]
def tex_refs(value):
 if isinstance(value,dict):
  for k,v in value.items():
   if k.endswith('Texture') and isinstance(v,dict) and 'index' in v:yield v
   else:yield from tex_refs(v)
 elif isinstance(value,list):
  for v in value:yield from tex_refs(v)
refs=list(tex_refs(out['materials']));used_tex=sorted({r['index'] for r in refs});tex_map={old:new for new,old in enumerate(used_tex)}
for r in refs:r['index']=tex_map[r['index']]
out['textures']=[out['textures'][i] for i in used_tex]
used_images=sorted({t['source'] for t in out['textures']});image_map={old:new for new,old in enumerate(used_images)}
for t in out['textures']:t['source']=image_map[t['source']]
out['images']=[out['images'][i] for i in used_images]
with tempfile.TemporaryDirectory(prefix='ishaq-boat-') as folder:
 folder=Path(folder);(folder/'input.json').write_text(json.dumps(out));(folder/'input.bin').write_bytes(buf)
 subprocess.run([node,str(Path(__file__).with_name('simplify_boat.mjs')),str(folder),meshopt,key],check=True)
sources={
 'whaler':('285 Conquest Boston Whaler','285-conquest-boston-whaler-61e2b2fae81b4e858b401ce7ccc8d8d2'),
 'scout':("2004 17' Scout - Center Console",'2004-17-scout-center-console-185e7c1dbf254b57b42b1979c45e4117'),
 'grady':('Freedom 325 Grady White','freedom-325-grady-white-71ca8a73f97d44a98f92dd785e151b93'),
 'glacier':('Glacier Bay','glacier-bay-6c4e6c341c09466fa6d6aafb8d7312b0')}
report={'title':sources[key][0],'creator':'BoatUS Foundation','source':'https://sketchfab.com/3d-models/'+sources[key][1],'license':'CC BY 4.0','license_url':'https://creativecommons.org/licenses/by/4.0/','original_sha256':hashlib.sha256(raw).hexdigest(),'original_bytes':len(raw),'removed_trailer_triangles':removed,'parts':{name:sum(len(p[2])//3 for p in entries) for name,entries in parts.items()},'changes':'Separated original steering wheel, throttle levers, outboards and propellers; aligned/scaled for gameplay; simplified with attribute preservation; retained source 1k textures. Scout trailer removed and cockpit lever isolated from fixed radio and housing.','additional_permission':'Project owner confirmed permission on 2026-10-24.'}
Path('assets/models/boats/'+key+'-source.json').write_text(json.dumps(report,indent=2)+'\n');print(report['parts'],'removed',removed,'wheel',wheel_center,shaft)
