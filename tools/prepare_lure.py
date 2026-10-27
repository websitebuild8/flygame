"""Prepare the free Sketchfab GLB without changing its geometry or artwork."""
import struct,json,pathlib,hashlib,sys
src=pathlib.Path(sys.argv[1]);b=src.read_bytes();ln=struct.unpack_from('<I',b,12)[0];g=json.loads(b[20:20+ln]);offset=20+ln;bn=struct.unpack_from('<I',b,offset)[0];blob=b[offset+8:offset+8+bn]
out=pathlib.Path('assets/models/tackle');im=g['images'][0];v=g['bufferViews'][im['bufferView']];image=blob[v.get('byteOffset',0):v.get('byteOffset',0)+v['byteLength']];(out/'saltwater_lure.png').write_bytes(image)
# Repack geometry views so the externalized image is not duplicated in the GLB.
image_view=im['bufferView']
assert all(a.get('bufferView')!=image_view for a in g['accessors'])
packed=bytearray();views=[];remap={}
for index,view in enumerate(g['bufferViews']):
 if index==image_view:continue
 packed.extend(b'\0'*((-len(packed))%4))
 updated=dict(view);updated['byteOffset']=len(packed)
 begin=view.get('byteOffset',0);packed.extend(blob[begin:begin+view['byteLength']])
 remap[index]=len(views);views.append(updated)
for accessor in g['accessors']:
 if 'bufferView' in accessor:accessor['bufferView']=remap[accessor['bufferView']]
blob=bytes(packed);g['bufferViews']=views
g['images']=[{'uri':'saltwater_lure.png'}];g['buffers']=[{'byteLength':len(blob)}]
j=json.dumps(g,separators=(',',':')).encode();j+=b' '*((-len(j))%4);blob+=b'\0'*((-len(blob))%4)
(out/'saltwater_lure.glb').write_bytes(struct.pack('<III',0x46546c67,2,28+len(j)+len(blob))+struct.pack('<II',len(j),0x4e4f534a)+j+struct.pack('<II',len(blob),0x004e4942)+blob)
metadata={'title':'Blue Fishing lure with Treble Hooks','author':'davidg.dev','source':'https://sketchfab.com/3d-models/blue-fishing-lure-with-treble-hooks-1803688419f14b3eb961326006ea038b','license':'CC BY 4.0','license_url':'https://creativecommons.org/licenses/by/4.0/','download':'Free converted GLB, 1K texture, 2026-10-27','changes':'Embedded texture externalized for mobile compression; runtime scale/orientation, front nose eye and wrapped leader knot. No generative processing of the model.','original_sha256':hashlib.sha256(b).hexdigest()}
(out/'saltwater-lure-source.json').write_text(json.dumps(metadata,indent=2)+'\n')
(out/'SALTWATER-LURE-LICENSE.txt').write_text('Blue Fishing lure with Treble Hooks by davidg.dev\n'+metadata['source']+'\nCreative Commons Attribution 4.0\nhttps://creativecommons.org/licenses/by/4.0/\nFree download. Adapted for game scale/orientation; texture externalized and mobile import limited to 512px.\n')
