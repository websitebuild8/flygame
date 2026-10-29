#!/usr/bin/env python3
"""Selected, owner-authorized Unity resources -> glTF 2.0; never executes game code.
Run with /home/ahusan/ft/venv/bin/python, which already contains UnityPy/Pillow.
Unity streamed polynomial curves are sampled at 30 Hz; dense/constant curves
are decoded separately. Curve bindings are resolved by CRC32 of actual hierarchy
paths. Unsupported bindings fail instead of silently creating broken animation.
"""
import argparse,bisect,collections,hashlib,io,json,math,struct,zlib
from pathlib import Path
import UnityPy
from UnityPy.helpers.MeshHelper import MeshHandler
from PIL import Image

def xyz(v):return [v.x,v.y,v.z]
def quat(v):return [v.x,v.y,v.z,v.w]
def normal(q):
 n=math.sqrt(sum(v*v for v in q));return [v/n for v in q] if n else [0,0,0,1]
def qmul(a,b):
 x,y,z,w=a;X,Y,Z,W=b
 return [w*X+x*W+y*Z-z*Y,w*Y-x*Z+y*W+z*X,w*Z+x*Y-y*X+z*W,w*W-x*X-y*Y-z*Z]
def euler_zxy(v):
 x,y,z=[a*math.pi/360 for a in v]
 return qmul([0,math.sin(y),0,math.cos(y)],qmul([math.sin(x),0,0,math.cos(x)],[0,0,math.sin(z),math.cos(z)]))
def reflect(v,kind):
 if kind=='translation':return [v[0],v[1],-v[2]]
 if kind=='rotation':return normal([-v[0],-v[1],v[2],v[3]])
 return list(v)

def transform_of(go):return next(c.component.read() for c in go.m_Component if c.component.type.name=='Transform')
def animator_root(renderer):
 t=transform_of(renderer.m_GameObject.read())
 while t:
  for c in t.m_GameObject.read().m_Component:
   if c.component.type.name=='Animator':return t,c.component.read().m_Controller.read()
  t=t.m_Father.read() if t.m_Father else None
 raise ValueError('No animator root')

def decode_clip(tree):
 muscle=tree['m_MuscleClip'];data=muscle['m_Clip']['data'];stream=data['m_StreamedClip'];dense=data['m_DenseClip'];const=data['m_ConstantClip']['data']
 raw=struct.pack('<'+'I'*len(stream['data']),*stream['data']);at=0;curves=collections.defaultdict(list)
 while at<len(raw):
  time,count=struct.unpack_from('<fI',raw,at);at+=8
  for _ in range(count):
   index,a,b,c,d=struct.unpack_from('<I4f',raw,at);at+=20
   # The first (-FLT_MAX) frame initializes channels; it is not an actual key.
   curves[index].append((time,[a,b,c,d]))
 stream_count=stream['curveCount'];dense_count=dense['m_CurveCount'];total=stream_count+dense_count+len(const)
 duration=muscle['m_StopTime']-muscle['m_StartTime']
 keys={i:[x[0] for x in entries] for i,entries in curves.items()}
 def scalar(index,time):
  if index<stream_count:
   entries=curves[index];k=max(0,bisect.bisect_right(keys[index],time)-1);t,coeff=entries[k]
   if t<-.001:return coeff[3]
   dt=max(0,time-t);a,b,c,d=coeff
   return ((a*dt+b)*dt+c)*dt+d
  if index<stream_count+dense_count:
   column=index-stream_count;sample=(time-dense['m_BeginTime'])*dense['m_SampleRate'];i=max(0,min(dense['m_FrameCount']-1,int(sample)));j=min(i+1,dense['m_FrameCount']-1);f=max(0,min(1,sample-i));values=dense['m_SampleArray']
   return values[i*dense_count+column]*(1-f)+values[j*dense_count+column]*f
  return const[index-stream_count-dense_count]
 return duration,total,scalar

class Writer:
 def __init__(self,texture_limit=1024):
  self.texture_limit=texture_limit
  self.doc={'asset':{'version':'2.0','generator':'Ishaq selected-resource converter'},'scene':0,'scenes':[{'nodes':[]}],'nodes':[],'meshes':[],'skins':[],'animations':[],'materials':[],'textures':[],'images':[],'samplers':[{'magFilter':9729,'minFilter':9987,'wrapS':10497,'wrapT':10497}],'buffers':[{}],'bufferViews':[],'accessors':[]}
  self.bin=bytearray();self.texture_cache={};self.material_cache={};self.stats=[]
 def blob(self,data,target=None):
  while len(self.bin)%4:self.bin.append(0)
  index=len(self.doc['bufferViews']);view={'buffer':0,'byteOffset':len(self.bin),'byteLength':len(data)}
  if target:view['target']=target
  self.doc['bufferViews'].append(view);self.bin.extend(data);return index
 def accessor(self,rows,kind,component=5126,target=None):
  flat=[n for row in rows for n in row] if kind!='SCALAR' else rows
  fmt={5126:'f',5123:'H',5125:'I'}[component];view=self.blob(struct.pack('<'+fmt*len(flat),*flat),target)
  item={'bufferView':view,'componentType':component,'count':len(rows),'type':kind}
  if kind in ['VEC3','SCALAR'] and component==5126:
   values=[[v] for v in rows] if kind=='SCALAR' else rows
   item['min']=[min(v[i] for v in values) for i in range(len(values[0]))];item['max']=[max(v[i] for v in values) for i in range(len(values[0]))]
  self.doc['accessors'].append(item);return len(self.doc['accessors'])-1
 def texture(self,tex,role):
  key=(tex.object_reader.path_id,role)
  if key in self.texture_cache:return self.texture_cache[key]
  image=tex.image.convert('RGBA');original=image.size;image.thumbnail((self.texture_limit,self.texture_limit),Image.Resampling.LANCZOS)
  if role=='normal':
   extrema=image.getextrema()
   if extrema[0][0]>240 and extrema[3][0]<240:
    pixels=[]
    for r,g,b,a in image.getdata():
     x=a/127.5-1;y=g/127.5-1;z=math.sqrt(max(0,1-x*x-y*y));pixels.append((a,g,round((z*.5+.5)*255),255))
    image.putdata(pixels)
   image=image.convert('RGB')
  elif role=='metallic':
   # Unity: red = metallic, alpha = smoothness. glTF: green = roughness, blue = metallic.
   image.putdata([(0,255-a,r,255) for r,g,b,a in image.getdata()]);image=image.convert('RGB')
  else:
   if image.getextrema()[3][0]==255:image=image.convert('RGB')
  output=io.BytesIO();image.save(output,format='PNG',optimize=True)
  view=self.blob(output.getvalue());idx=len(self.doc['images']);self.doc['images'].append({'name':tex.m_Name+'_'+role,'bufferView':view,'mimeType':'image/png'});self.doc['textures'].append({'source':idx,'sampler':0});self.texture_cache[key]=idx
  self.stats.append({'texture':tex.m_Name,'role':role,'original':original,'converted':image.size,'png_bytes':len(output.getvalue())});return idx
 def material(self,source):
  key=source.object_reader.path_id
  if key in self.material_cache:return self.material_cache[key]
  props={k:v for k,v in source.m_SavedProperties.m_TexEnvs};floats=dict(source.m_SavedProperties.m_Floats)
  item={'name':source.m_Name,'pbrMetallicRoughness':{'metallicFactor':max(0,min(1,float(floats.get('_Metallic',.15)))),'roughnessFactor':max(.25,min(1,1-float(floats.get('_Smoothness',.5))))},'doubleSided':False}
  for alternatives,role,field in [(['_BaseMap','_MainTex'],'base','baseColorTexture'),(['_BumpMap'],'normal','normalTexture'),(['_MetallicGlossMap'],'metallic','metallicRoughnessTexture')]:
   env=next((props[k] for k in alternatives if k in props and props[k].m_Texture),None)
   if env:
    tex=env.m_Texture.read();record={'index':self.texture(tex,role)}
    if role=='normal':record['scale']=.6;item[field]=record
    else:item['pbrMetallicRoughness'][field]=record
    if role=='metallic':item['pbrMetallicRoughness']['metallicFactor']=1;item['pbrMetallicRoughness']['roughnessFactor']=1
  idx=len(self.doc['materials']);self.doc['materials'].append(item);self.material_cache[key]=idx;return idx
 def save(self,path):
  self.doc['buffers'][0]['byteLength']=len(self.bin)
  # Empty optional arrays are invalid in strict glTF validators.
  for key in ['meshes','skins','animations','textures','images','materials','samplers']:
   if not self.doc[key]:del self.doc[key]
  js=json.dumps(self.doc,separators=(',',':'),allow_nan=False).encode();js+=b' '*((-len(js))%4);self.bin+=b'\0'*((-len(self.bin))%4)
  out=struct.pack('<III',0x46546c67,2,12+8+len(js)+8+len(self.bin))+struct.pack('<II',len(js),0x4e4f534a)+js+struct.pack('<II',len(self.bin),0x004e4942)+self.bin
  path.write_bytes(out);return len(out)

def convert(bundle,mesh_names,clip_names,out,texture_limit=1024):
 env=UnityPy.load(str(bundle));selected=[]
 for ob in env.objects:
  if ob.type.name=='SkinnedMeshRenderer':
   r=ob.read()
   if r.m_Mesh.read().m_Name in mesh_names:selected.append(r)
 assert len(selected)==len(mesh_names),(mesh_names,len(selected))
 top,controller=animator_root(selected[0]);rootid=top.object_reader.path_id
 needed={rootid};transforms={};paths={};allpaths={}
 def gather(t,path=''):
  tid=t.object_reader.path_id;transforms[tid]=t;paths[tid]=path;allpaths[zlib.crc32(path.encode())]=tid
  for ptr in t.m_Children:
   child=ptr.read();name=child.m_GameObject.read().m_Name;gather(child,path+'/'+name if path else name)
 gather(top)
 def require(t):
  tid=t.object_reader.path_id
  if tid in needed:return
  needed.add(tid)
  if tid!=rootid and t.m_Father:require(t.m_Father.read())
 for r in selected:
  require(transform_of(r.m_GameObject.read()))
  for bone in r.m_Bones:require(bone.read())
 writer=Writer(texture_limit);nodes={}
 for tid,t in transforms.items():
  if tid not in needed:continue
  nodes[tid]=len(writer.doc['nodes']);writer.doc['nodes'].append({'name':t.m_GameObject.read().m_Name,'translation':reflect(xyz(t.m_LocalPosition),'translation'),'rotation':reflect(quat(t.m_LocalRotation),'rotation'),'scale':xyz(t.m_LocalScale)})
 for tid,index in nodes.items():
  children=[nodes[c.path_id] for c in transforms[tid].m_Children if c.path_id in nodes]
  if children:writer.doc['nodes'][index]['children']=children
 writer.doc['scenes'][0]['nodes']=[nodes[rootid]]
 for r in selected:
  mesh=r.m_Mesh.read();h=MeshHandler(mesh);h.process();attributes={'POSITION':writer.accessor([reflect(v,'translation') for v in h.m_Vertices],'VEC3',target=34962)}
  if h.m_Normals:attributes['NORMAL']=writer.accessor([reflect(v[:3],'translation') for v in h.m_Normals],'VEC3',target=34962)
  if h.m_UV0:attributes['TEXCOORD_0']=writer.accessor([[v[0],1-v[1]] for v in h.m_UV0],'VEC2',target=34962)
  assert h.m_BoneIndices
  if h.m_BoneWeights is None:
   assert all(len(row)==1 for row in h.m_BoneIndices), 'Missing non-rigid skin weights'
   h.m_BoneWeights=[(1.0,0.0,0.0,0.0)]*h.m_VertexCount
  joints=[list(row)+[0]*(4-len(row)) for row in h.m_BoneIndices]
  attributes['JOINTS_0']=writer.accessor(joints,'VEC4',5123,34962)
  weights=[]
  for row in h.m_BoneWeights:
   total=sum(row);assert total>.99 and total<1.01;weights.append([v/total for v in row])
  attributes['WEIGHTS_0']=writer.accessor(weights,'VEC4',target=34962)
  prims=[];triangles=0
  for i,indices in enumerate(h.get_triangles()):
   flat=[v for a,b,c in indices for v in (c,b,a)];triangles+=len(indices)
   prims.append({'attributes':attributes,'indices':writer.accessor(flat,'SCALAR',5123,34963),'material':writer.material(r.m_Materials[min(i,len(r.m_Materials)-1)].read())})
  mid=len(writer.doc['meshes']);writer.doc['meshes'].append({'name':mesh.m_Name,'primitives':prims})
  matrices=[]
  for b in mesh.m_BindPose:
   # Column-major serialization and reflection on both sides.
   matrices.append([getattr(b,'e%d%d'%(i,j))*(-1 if (i==2) != (j==2) else 1) for j in range(4) for i in range(4)])
  skin=len(writer.doc['skins']);writer.doc['skins'].append({'name':mesh.m_Name+'_skin','joints':[nodes[b.path_id] for b in r.m_Bones],'inverseBindMatrices':writer.accessor(matrices,'MAT4')})
  node=writer.doc['nodes'][nodes[transform_of(r.m_GameObject.read()).object_reader.path_id]];node['mesh']=mid;node['skin']=skin
  writer.stats.append({'mesh':mesh.m_Name,'vertices':h.m_VertexCount,'triangles':triangles,'bones':len(r.m_Bones)})
 seen=set()
 for pair in controller.m_Clips:
  clip=(pair.m_OverrideClip if pair.m_OverrideClip else pair.m_OriginalClip).read()
  if clip.m_Name not in clip_names or clip.object_reader.path_id in seen:continue
  seen.add(clip.object_reader.path_id);tree=clip.object_reader.read_typetree();duration,total,sample=decode_clip(tree)
  frames=max(1,math.ceil(duration*30));times=[min(i/30,duration) for i in range(frames+1)];time_accessor=writer.accessor(times,'SCALAR');animation={'name':clip.m_Name,'samplers':[],'channels':[]};index=0;skipped=0
  for binding in tree['m_ClipBindingConstant']['genericBindings']:
   attr=binding['attribute'];width=4 if attr==2 else 3 if attr in [1,3,4] else 1
   tid=allpaths.get(binding['path']);start=index;index+=width
   if tid not in nodes:skipped+=1;continue
   assert binding['typeID']==4 and attr in [1,2,3,4],binding
   kind={1:'translation',2:'rotation',3:'scale',4:'rotation'}[attr];values=[]
   for time in times:
    value=[sample(start+j,time) for j in range(width)]
    if attr==4:value=euler_zxy(value)
    value=reflect(value,kind)
    if kind=='rotation' and values and sum(a*b for a,b in zip(value,values[-1]))<0:value=[-v for v in value]
    values.append(value)
   # Constant tracks need two samples, not a full 30-Hz stream.
   constant=all(max(abs(a-b) for a,b in zip(v,values[0]))<1e-6 for v in values)
   if constant:values=[values[0],values[-1]];input_accessor=writer.accessor([0,duration],'SCALAR')
   else:input_accessor=time_accessor
   output=writer.accessor(values,'VEC4' if kind=='rotation' else 'VEC3');sid=len(animation['samplers']);animation['samplers'].append({'input':input_accessor,'output':output,'interpolation':'LINEAR'});animation['channels'].append({'sampler':sid,'target':{'node':nodes[tid],'path':kind}})
  assert index==total,(clip.m_Name,index,total)
  writer.doc['animations'].append(animation);writer.stats.append({'animation':clip.m_Name,'duration':duration,'tracks':len(animation['channels']),'excluded_unneeded_bindings':skipped})
 assert {a['name'] for a in writer.doc['animations']}==set(clip_names)
 out.parent.mkdir(parents=True,exist_ok=True);size=writer.save(out)
 report={'texture_limit':texture_limit,'source_bundle':str(bundle),'source_sha256':hashlib.sha256(bundle.read_bytes()).hexdigest(),'output':out.name,'output_sha256':hashlib.sha256(out.read_bytes()).hexdigest(),'glb_bytes':size,'stats':writer.stats,'authorization':'User states app owner approved reuse; recorded in conversation. Not a public asset license.','conversion':'Selected skin, materials and animation. Coordinate reflection Z; UV V flip; PNG textures <=1024; streamed/dense/constant curves sampled at30Hz; quaternion continuity; no Unity shaders or code copied.'}
 out.with_suffix('.source.json').write_text(json.dumps(report,indent=2));print(json.dumps(report,indent=2))

if __name__=='__main__':
 p=argparse.ArgumentParser();p.add_argument('--source',type=Path,default=Path('/home/ahusan/ft/split_UnityDataAssetPack/assets'));p.add_argument('--output',type=Path,default=Path('assets/models/reference'))
 p.add_argument('--asset',action='append',choices=['yellowfin','deep_blue','rusty_jobfish','giant_grouper'],help='Select one or more migrations; defaults to the original tuna/outfit pair')
 p.add_argument('--texture-size',type=int,choices=[256,512,1024],help='Override texture cap; grouper defaults to 512, other selections to 1024')
 args=p.parse_args()
 fish_clips=['Swim01','Pulling01','Show01','Hurt01','Jump01']
 selections={
  'yellowfin':('fishfp_assets_packpreloadpack101_*.bundle',['F_yellowfintuna'],fish_clips),
  'deep_blue':('rodfp_assets_all_*.bundle',['Rod_deepblue','Reel_deepblue'],['Waiting01','Reeling01','Throwing01','Pulling01','Show01']),
  'rusty_jobfish':('fishfp_assets_packpreloadpack102_*.bundle',['F_rustyjobfish'],fish_clips),
  'giant_grouper':('fishfp_assets_packpreloadpack102_*.bundle',['F_giantgrouper'],fish_clips)
 }
 for name in args.asset or ['yellowfin','deep_blue']:
  pattern,meshes,clips=selections[name]
  convert(next(args.source.glob(pattern)),meshes,clips,args.output/(name+'.glb'),args.texture_size or (512 if name=='giant_grouper' else 1024))
