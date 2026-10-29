"""Reduce the converted reference rig to a lightweight live outfit.
Input is written by tools/bake_deep_blue.gd; source animations remain in the
showcase. This step freezes geometry only, retaining separate mechanical parts.
"""
import collections,json,math
from pathlib import Path
source=json.loads(Path('/tmp/deep-blue-baked.json').read_text())
rod=next(m for m in source['meshes'] if 'Rod' in m['name'])
reel=next(m for m in source['meshes'] if 'Reel' in m['name'])
def bounds(vertices):return [[min(v[k] for v in vertices),max(v[k] for v in vertices)] for k in range(3)]
def center(vertices):return [(a+b)/2 for a,b in bounds(vertices)]
def components(surface):
 vertices=surface['vertices'];parent=list(range(len(vertices)));known={}
 def find(i):
  while parent[i]!=i:parent[i]=parent[parent[i]];i=parent[i]
  return i
 def union(i,j):parent[find(i)]=find(j)
 for i,v in enumerate(vertices):
  key=tuple(round(x,5) for x in v)
  if key in known:union(i,known[key])
  else:known[key]=i
 for i in range(0,len(surface['indices']),3):
  a,b,c=surface['indices'][i:i+3];union(a,b);union(a,c)
 groups=collections.defaultdict(list)
 for i in range(len(vertices)):groups[find(i)].append(i)
 return sorted(groups.values(),key=len,reverse=True)
rs=rod['surfaces'][0];islands=components(rs)
# Seven lower ceramic rings plus the terminal ring. Repeated seam vertices are
# welded for island detection; rim X extrema locate each symmetric hole centre.
rims=[ids for ids in islands if len(ids)==269]
assert len(rims)==7
rims.sort(key=lambda ids:center([rs['vertices'][i] for i in ids])[1])
rims.append(next(ids for ids in islands if len(ids)==200))
holes=[]
for ids in rims:
 points=[rs['vertices'][i] for i in ids];left=min(points,key=lambda p:p[0]);right=max(points,key=lambda p:p[0]);holes.append([(a+b)/2 for a,b in zip(left,right)])
base_y=min(v[1] for v in rs['vertices']);factor=2.7/(holes[-1][1]-base_y)
shaft_z=sum(p['origin'][2] for p in rod['pivots'].values())/len(rod['pivots'])
axis=[0,.47,-.882666];length=math.sqrt(sum(a*a for a in axis));axis=[a/length for a in axis];radial=[0,-axis[2],axis[1]];base=[0,-.04,.38]
def rod_point(p):return [base[k]+axis[k]*(p[1]-base_y)*factor-radial[k]*(p[2]-shaft_z)*factor-(p[0]*factor if k==0 else 0) for k in range(3)]
def rod_normal(p):return [axis[k]*p[1]-radial[k]*p[2]-(p[0] if k==0 else 0) for k in range(3)]

def subset(surface,indices,point,direction,reverse=False):
 old=sorted(set(indices));mapping={index:i for i,index in enumerate(old)};triangles=[mapping[i] for i in indices]
 if reverse:
  for i in range(0,len(triangles),3):triangles[i+1],triangles[i+2]=triangles[i+2],triangles[i+1]
 return {'vertices':[point(surface['vertices'][i]) for i in old],'normals':[direction(surface['normals'][i]) for i in old],'uv':[surface['uv'][i] for i in old],'indices':triangles}
parts={'rod':subset(rs,rs['indices'],rod_point,rod_normal)}
# Reel captured in its stationary housing frame. X/Y/Z below are the physical
# side/up/spindle axes. Swapping X and Z selects right-hand retrieve; winding
# is reversed to retain the same handedness after that mirror.
spool_axis_y=reel['pivots']['Bone_Reel_Bobbin']['origin'][1]
def reel_point(p):return [p[2]*factor,(p[1]-spool_axis_y)*factor,p[0]*factor]
def reel_normal(p):return [p[2],p[1],p[0]]
ss=reel['surfaces'][0];islands=components(ss)
# The source Bobbin bone drives both spool and rotor geometry. Separate the
# actual spool/drag cap from rotor cup, bail wire and roller for a real spinning
# retrieve (the spool reciprocates instead of rotating with the bail).
spool_ids=set()
roller_ids=None
for ids in islands:
 group=ss['groups'][ids[0]]
 if group=='Bone_Reel_Bobbin' and len(ids) in [1056,457,42]:spool_ids.update(ids)
 if group=='Bone_Reel_Bobbin' and len(ids)==228:roller_ids=ids
assert spool_ids and roller_ids is not None
triangles=collections.defaultdict(list)
for i in range(0,len(ss['indices']),3):
 face=ss['indices'][i:i+3];groups={ss['groups'][j] for j in face};assert len(groups)==1,groups;group=groups.pop()
 if group=='Bone_Reel_Wheel':name='body'
 elif group=='Bone_Reel_Handle':name='crank'
 elif group=='X':name='knob'
 elif group=='Bone_Reel_Bobbin':
  membership=[j in spool_ids for j in face];assert all(membership) or not any(membership);name='spool' if all(membership) else 'rotor'
 else:raise ValueError('Unexpected source component: '+group)
 triangles[name].extend(face)
for name,indices in triangles.items():parts[name]=subset(ss,indices,reel_point,reel_normal,True)
body_bounds=bounds(parts['body']['vertices']);handle_bounds=bounds(parts['crank']['vertices'])
# Set the reversible handle outboard of the housing while leaving its authored
# axle cap seated within the side cover. No extra primitive axle is necessary.
shift=body_bounds[0][1]*.5-handle_bounds[0][0]
for name in ['crank','knob']:
 for v in parts[name]['vertices']:v[0]+=shift
crank_pivot=reel_point(reel['pivots']['Bone_Reel_Handle']['origin']);crank_pivot[0]+=shift
rotor_pivot=reel_point(reel['pivots']['Bone_Reel_Bobbin']['origin'])
grip=center(parts['knob']['vertices'])
for name,pivot in [('crank',crank_pivot),('knob',grip),('rotor',rotor_pivot)]:
 for v in parts[name]['vertices']:
  for k in range(3):v[k]-=pivot[k]
# Mounting face is the highest plane of the fixed reel foot.
vertices=parts['body']['vertices'];top=max(v[1] for v in vertices);foot=[v for v in vertices if v[1]>top-.001];mount=center(foot);mount[1]=top
spool_bounds=bounds(parts['spool']['vertices']);lip=[rotor_pivot[0],rotor_pivot[1],spool_bounds[2][0]+.002*factor]
roller_points=[reel_point(ss['vertices'][i]) for i in roller_ids];roller=center(roller_points);roller[2]=min(v[2] for v in roller_points)+.002*factor
meta={'guides':[rod_point(p) for p in holes],'tip':rod_point(holes[-1]),'mount_foot':mount,'crank_pivot':crank_pivot,'rotor_pivot':rotor_pivot,'knob_origin':[grip[k]-crank_pivot[k] for k in range(3)],'grip_point':[grip[k]-crank_pivot[k] for k in range(3)],'line_roller':[roller[k]-rotor_pivot[k] for k in range(3)],'spool_lip':lip,'spool_travel':.008*factor,'rotor_ratio':5.0,'handle_side_shift':shift,'source_scale':factor,'shaft_z':shaft_z}
result={'parts':parts,'metadata':meta}
Path('/tmp/deep-blue-live.json').write_text(json.dumps(result,separators=(',',':')))
Path('assets/models/reference/deep-blue-live-adaptation.json').write_text(json.dumps({'metadata':meta,'parts':{k:{'vertices':len(v['vertices']),'triangles':len(v['indices'])//3} for k,v in parts.items()},'method':'Show-pose rod and Waiting-pose reel; unskinned canonical meshes; eight measured ceramic-hole centres; right-hand mirror; rigid mechanical separation with 5:1 bail ratio; source textures reused.'},indent=2))
print(json.dumps({'metadata':meta,'parts':{k:len(v['indices'])//3 for k,v in parts.items()}},indent=2))
