#!/usr/bin/env python3
"""Read selected owner-supplied Unity resources; never executes application code.
Run with the pre-existing /home/ahusan/ft/venv/bin/python UnityPy environment.
Writes a bounded, source-hashed inspection record, not runtime observations.
"""
import collections, hashlib, json
from pathlib import Path
import UnityPy
from UnityPy.helpers.MeshHelper import MeshHandler
ROOT=Path('/home/ahusan/ft/split_UnityDataAssetPack/assets')
PATTERNS=['fishfp_assets_packpreload_*.bundle','fishingaquarium_assets_all_*.bundle','fishingaquariumscene_assets_aquarium02_*.bundle','panelfp_assets_eventfishhuntingpanel_*.bundle','panelfp_assets_eventfishhuntingaim_*.bundle','stages_assets_smallgameact_*.bundle']
SCRIPT_NAMES={'Crossbow','CrossbowArrow','ShooterFishAct','AquariumCameraManager','EventFishHuntingPanel','EventFishHuntingAim','AquariumObstacleManager','FogController','FishMovement','FishingAquariumAct'}
def parents(go):
 t=next(c.component.read() for c in go.m_Component if c.component.type.name in ['Transform','RectTransform']);result=[]
 while t:
  result.append(t.m_GameObject.read().m_Name)
  t=t.m_Father.read() if t.m_Father else None
 return result
record={'source_root':str(ROOT),'scope':'Six selected resource bundles; static parsed resources and serialized configuration, not original app execution','bundles':[]}
for pattern in PATTERNS:
 for path in ROOT.glob(pattern):
  env=UnityPy.load(str(path));item={'file':path.name,'bytes':path.stat().st_size,'sha256':hashlib.sha256(path.read_bytes()).hexdigest(),'types':dict(collections.Counter(ob.type.name for ob in env.objects)),'meshes':[],'animations':[],'textures':[],'scripts':[]}
  for ob in env.objects:
   if ob.type.name=='Mesh':
    r=ob.read();h=MeshHandler(r);h.process();item['meshes'].append({'name':r.m_Name,'path_id':ob.path_id,'vertices':h.m_VertexCount,'triangles':sum(len(s) for s in h.get_triangles())})
   elif ob.type.name in ['Texture2D','AnimationClip']:
    r=ob.read();entry={'name':r.m_Name,'path_id':ob.path_id}
    if ob.type.name=='Texture2D':entry.update(width=r.m_Width,height=r.m_Height)
    item['textures' if ob.type.name=='Texture2D' else 'animations'].append(entry)
   elif ob.type.name=='MonoBehaviour':
    r=ob.read()
    try:name=r.m_Script.read().m_Name
    except (FileNotFoundError,ValueError,AttributeError):continue
    if name not in SCRIPT_NAMES:continue
    entry={'name':name,'path_id':ob.path_id,'game_object':r.m_GameObject.read().m_Name}
    try:
     tree=ob.read_typetree();entry['serialized_keys']=list(tree);entry['scalar_configuration']={k:v for k,v in tree.items() if isinstance(v,(float,int,str,bool)) and not k.startswith('m_')}
     entry['numeric_array_configuration']={k:v for k,v in tree.items() if isinstance(v,list) and v and all(isinstance(n,(float,int)) for n in v)}
     entry['reference_fields']={k:v for k,v in tree.items() if isinstance(v,dict) and 'm_PathID' in v and not k.startswith('m_')}
    except Exception as exc:entry['typetree_error']=str(exc)
    item['scripts'].append(entry)
  record['bundles'].append(item)
output=Path('docs/diving-reference-inventory.json');output.write_text(json.dumps(record,indent=2)+'\n');print(output)
