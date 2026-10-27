"""Convert real OSM coastlines/streets into spaced game island data."""
import pathlib,json,xml.etree.ElementTree as E,math,hashlib,sys
configs={'filladhoo':('Filladhoo','19879519',(260,-230),50),'vashafaru':('Vashafaru','19879406',(-90,-350),47),'dhidhdhoo':('Dhidhdhoo','19879294',(-350,210),45),'baarah':('Baarah','19879757',(300,210),60)}
out=pathlib.Path('assets/maps/neighbours');source_dir=pathlib.Path(sys.argv[1]) if len(sys.argv)>1 else out;all_data={}
for slug,(name,way_id,center,radius) in configs.items():
 source=source_dir/(slug+'.osm');raw=source.read_bytes();(out/(slug+'.osm')).write_bytes(raw);r=E.fromstring(raw);nodes={n.attrib['id']:(float(n.attrib['lon']),float(n.attrib['lat'])) for n in r.findall('node')}
 def tags(e):return {t.attrib['k']:t.attrib['v'] for t in e.findall('tag')}
 ways=r.findall('way');coast=next(w for w in ways if w.attrib['id']==way_id);rawcoast=[nodes[n.attrib['ref']] for n in coast.findall('nd')][:-1];lon=sum(p[0] for p in rawcoast)/len(rawcoast);lat=sum(p[1] for p in rawcoast)/len(rawcoast)
 def metric(ref):a,b=nodes[ref];return((a-lon)*111320*math.cos(math.radians(lat)),(lat-b)*111320)
 ps=[metric(n.attrib['ref']) for n in coast.findall('nd')][:-1];lo=[min(p[k] for p in ps) for k in [0,1]];hi=[max(p[k] for p in ps) for k in [0,1]];mid=[(a+b)/2 for a,b in zip(lo,hi)];scale=radius*2/max(b-a for a,b in zip(lo,hi))
 def point(ref):p=metric(ref);return[round(center[k]+(p[k]-mid[k])*scale,4) for k in [0,1]]
 def feature(w):return{'osm_id':int(w.attrib['id']),'points':[point(n.attrib['ref']) for n in w.findall('nd')],'tags':tags(w)}
 data={'coast':[point(n.attrib['ref']) for n in coast.findall('nd')][:-1],'roads':[],'buildings':[],'landmarks':[],'harbour':[],'name':'HA. '+name}
 for w in ways:
  t=tags(w);f=feature(w)
  if t.get('highway'):data['roads'].append(f)
  if t.get('building') and len(data['buildings'])<100:data['buildings'].append(f)
  if t.get('amenity') or t.get('leisure')=='pitch':data['landmarks'].append(f)
  if t.get('man_made') in ['breakwater','pier','quay'] or t.get('landuse')=='harbour':data['harbour'].append(f)
 for node_id,node in ((n.attrib['id'],n) for n in r.findall('node')):
  if tags(node).get('leisure')=='marina':data['harbour'].append({'osm_id':int(node_id),'points':[point(node_id)],'tags':tags(node)})
 data['source']={'provider':'© OpenStreetMap contributors','license':'ODbL 1.0','license_url':'https://opendatacommons.org/licenses/odbl/1-0/','copyright_url':'https://www.openstreetmap.org/copyright','coastline_url':'https://www.openstreetmap.org/way/'+way_id,'retrieved':'2026-10-27','original_sha256':hashlib.sha256(raw).hexdigest(),'adaptation':'Compressed coast/streets and selected footprints. Positions spaced for gameplay, not real-world inter-island distances. Extra architecture is fictional.'}
 all_data['HA. '+name]=data;print(name,'coast',len(data['coast']),'roads',len(data['roads']),'buildings',len(data['buildings']))
(out/'islands.json').write_text(json.dumps(all_data,separators=(',',':'))+'\n');(out/'MAP-LICENSE.txt').write_text('© OpenStreetMap contributors\nhttps://www.openstreetmap.org/copyright\nODbL 1.0 https://opendatacommons.org/licenses/odbl/1-0/\nDerived geometry: islands.json. Original extracts: *.osm in the project repository.\nCompressed shapes and fictional game placements, not a navigational chart.\n')
