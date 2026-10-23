"""Split the CC BY Bora Ozakaltun outboard's propeller into a rotating node.
Usage: python3 tools/prepare_outboard.py /path/boat_motor.glb
The original download remains untouched; textures/geometry are retained.
"""
import json,struct,sys,hashlib
from pathlib import Path
raw=Path(sys.argv[1]).read_bytes();n=struct.unpack_from('<I',raw,12)[0];g=json.loads(raw[20:20+n]);data=bytearray(raw[28+n:])
def read(k):
 a=g['accessors'][k];v=g['bufferViews'][a['bufferView']];o=v.get('byteOffset',0)+a.get('byteOffset',0);w={'VEC3':3,'SCALAR':1}[a['type']];fmt={5126:'f',5125:'I',5123:'H'}[a['componentType']]
 return [struct.unpack_from('<'+fmt*w,data,o+i*struct.calcsize(fmt)*w) for i in range(a['count'])]
p=g['meshes'][0]['primitives'][0];vertices=read(p['attributes']['POSITION']);indices=[x[0]for x in read(p['indices'])];parents=list(range(len(vertices)));same={}
def find(a):
 while parents[a]!=a:parents[a]=parents[parents[a]];a=parents[a]
 return a
def union(a,b):parents[find(a)]=find(b)
for i,pos in enumerate(vertices):
 key=tuple(round(x,5)for x in pos)
 if key in same:union(i,same[key])
 else:same[key]=i
for i in range(0,len(indices),3):union(indices[i],indices[i+1]);union(indices[i],indices[i+2])
groups={}
for i,pos in enumerate(vertices):groups.setdefault(find(i),[]).append(pos)
selected=set()
for component,points in groups.items():
 lo=[min(p[k]for p in points)for k in range(3)];hi=[max(p[k]for p in points)for k in range(3)]
 if hi[1]<-.16 and hi[2]<-.15 and lo[1]>-.35:selected.add(component)
assert selected,'Propeller geometry was not identified'
prop=[];body=[]
for i in range(0,len(indices),3):(prop if find(indices[i])in selected else body).extend(indices[i:i+3])
points=[vertices[i]for i in set(prop)];pivot=[(min(p[k]for p in points)+max(p[k]for p in points))/2 for k in range(3)]
def add(payload,count,kind,component):
 data.extend(b'\0'*(-len(data)%4));offset=len(data);data.extend(payload);g['bufferViews'].append({'buffer':0,'byteOffset':offset,'byteLength':len(payload)});g['accessors'].append({'bufferView':len(g['bufferViews'])-1,'componentType':component,'count':count,'type':kind});return len(g['accessors'])-1
p['indices']=add(struct.pack('<'+'I'*len(body),*body),len(body),'SCALAR',5125)
prop_positions=[tuple(p[k]-pivot[k]for k in range(3))for p in vertices]
position=add(b''.join(struct.pack('<fff',*p)for p in prop_positions),len(vertices),'VEC3',5126)
g['accessors'][position].update(min=[min(p[k]for p in prop_positions)for k in range(3)],max=[max(p[k]for p in prop_positions)for k in range(3)])
attrs=dict(p['attributes']);attrs['POSITION']=position
prop_index=add(struct.pack('<'+'I'*len(prop),*prop),len(prop),'SCALAR',5125)
g['meshes'].append({'name':'RotatingPropeller','primitives':[{'attributes':attrs,'indices':prop_index,'material':p['material'],'mode':4}]})
g['nodes'][2]['children'].append(len(g['nodes']));g['nodes'].append({'name':'Propeller','mesh':1,'translation':pivot})
g['buffers'][0]['byteLength']=len(data);data.extend(b'\0'*(-len(data)%4));j=json.dumps(g,separators=(',',':')).encode();j+=b' '*(-len(j)%4)
output=struct.pack('<IIIII',0x46546c67,2,28+len(j)+len(data),len(j),0x4e4f534a)+j+struct.pack('<II',len(data),0x004e4942)+data
Path('assets/models/boats/outboard.glb').write_bytes(output)
Path('assets/models/boats/outboard-source.json').write_text(json.dumps({'creator':'Bora Ozakaltun (metadata alias paraverun)','source':g['asset']['extras']['source'],'license':'CC BY 4.0','license_url':'https://creativecommons.org/licenses/by/4.0/','original_sha256':hashlib.sha256(raw).hexdigest(),'changes':'Split existing propeller geometry into a separately rotating node; source 1k textures retained. Runtime size, centre and mounting orientation adapted.'},indent=2)+'\n')
print('Prepared outboard:',len(body)//3,'body triangles,',len(prop)//3,'rotating propeller triangles')
