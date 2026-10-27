"""Convert an OSM extract into the compressed, north-aligned Kelaa game map."""
import xml.etree.ElementTree as ET
import json,math,pathlib,sys,hashlib
src=pathlib.Path(sys.argv[1]);root=ET.parse(src).getroot()
nodes={n.attrib['id']:n for n in root.findall('node')}
def tags(e):return {t.attrib['k']:t.attrib['v'] for t in e.findall('tag')}
def point(ref):
 n=nodes[ref];x=(float(n.attrib['lon'])-73.21551)*111320*math.cos(math.radians(6.95183));z=(6.95183-float(n.attrib['lat']))*111320
 return [round(2.3+(x+850)*.04,4),round(12+(z+1180)*.04,4)]
def feature(e):return {'osm_id':int(e.attrib['id']),'points':[point(n.attrib['ref']) for n in e.findall('nd')],'tags':tags(e)}
ways=root.findall('way');coast=next(w for w in ways if w.attrib['id']=='485114123')
data={'coast':feature(coast)['points'][:-1],'roads':[],'buildings':[],'landmarks':[],'vegetation':[],'harbour':[]}
for w in ways:
 t=tags(w);f=feature(w)
 if t.get('highway'):data['roads'].append(f)
 if t.get('building'):data['buildings'].append(f)
 if t.get('amenity') or t.get('leisure')=='pitch':data['landmarks'].append(f)
 if t.get('landuse')=='forest' or t.get('natural')=='wood':data['vegetation'].append(f)
 if t.get('landuse')=='harbour' or t.get('man_made') in ['pier','breakwater']:data['harbour'].append(f)
data['source']={'provider':'OpenStreetMap contributors','source_url':'https://api.openstreetmap.org/api/0.6/map?bbox=73.195,6.925,73.235,6.985','coastline_url':'https://www.openstreetmap.org/way/485114123','license':'ODbL 1.0','license_url':'https://opendatacommons.org/licenses/odbl/1-0/','attribution':'© OpenStreetMap contributors','copyright_url':'https://www.openstreetmap.org/copyright','retrieved':'2026-10-27','source_sha256':hashlib.sha256(src.read_bytes()).hexdigest(),'scale':'0.04 game units per geographic metre; north aligned; harbour approach anchored near existing home dock.','adaptation':'Mapped coastline/roads/footprints, simplified terrain; extra houses, facades, gardens and palms are fictional. Harbour approach and shop buildings adapted for gameplay. Not for navigation.'}
out=pathlib.Path('assets/maps/kelaa');out.mkdir(parents=True,exist_ok=True);(out/'kelaa.json').write_text(json.dumps(data,separators=(',',':'))+'\n')
(out/'MAP-LICENSE.txt').write_text('Kelaa map data © OpenStreetMap contributors\nhttps://www.openstreetmap.org/copyright\nOpen Data Commons Open Database License 1.0\nhttps://opendatacommons.org/licenses/odbl/1-0/\nDerived map database: kelaa.json. Original extract: source.osm (project repository).\nGeometry compressed for gameplay; additional buildings and decoration are fictional. Not for navigation.\n')
print('coast',len(data['coast']),'roads',len(data['roads']),'buildings',len(data['buildings']),'landmarks',len(data['landmarks']))
