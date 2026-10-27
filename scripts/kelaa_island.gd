extends Node3D
## OSM coastline/streets with original, deliberately stylised Maldivian architecture.
const Harbours=preload("res://scripts/island_harbours.gd")
const Map=preload("res://scripts/kelaa_map_data.gd")
var map=Map
var is_home=true
var island_title="HA. Kelaa"
var batches: Dictionary={}
var occupied: Array[Vector2]=[]
var rng=RandomNumberGenerator.new()
var cube_arrays: Array
var material: StandardMaterial3D
var road_lines: Array[PackedVector2Array]=[]
var landmark_bounds: Array[Rect2]=[]
var chunk_count=0
var grass_outline=PackedVector2Array()
var house_count=0
var mapped_landmarks: Array[String]=[]
var palm_count=0
func _ready() -> void:
	name="KelaaIsland" if is_home else island_title.replace("HA. ","")+"Island";rng.seed=485114123 if is_home else hash(island_title)
	material=StandardMaterial3D.new();material.vertex_color_use_as_albedo=true;material.roughness=.9
	cube_arrays=BoxMesh.new().get_mesh_arrays()
	for feature in map.data.roads:road_lines.append(map.points(feature.points))
	for feature in map.data.landmarks:landmark_bounds.append(map.polygon_bounds(map.points(feature.points)))
	terrain(map.coast,-.30,Color("ead4a0"))
	var inland=Geometry2D.offset_polygon(map.coast,-1.0)
	if not inland.is_empty():
		grass_outline=inland[0];terrain(grass_outline,.18,Color("b6bd83"))
	for feature in map.data.roads:road(map.points(feature.points),feature.tags.get("highway","")=="track")
	for feature in map.data.buildings:
		var polygon=map.points(feature.points);var bounds=map.polygon_bounds(polygon);var at=bounds.get_center()
		var size=Vector2(clampf(bounds.size.x,.70,2.1),clampf(bounds.size.y,.75,2.1))
		house(at,size,feature.tags.get("name",""));occupied.append(at)
	# Fill unmapped residential plots, without claiming these are real individual houses.
	for feature in map.data.roads:
		if feature.tags.get("highway","")!="residential":continue
		var points=map.points(feature.points)
		for i in range(points.size()-1):
			var direction=(points[i+1]-points[i]).normalized();var side=Vector2(-direction.y,direction.x)
			for step in range(maxi(1,int(points[i].distance_to(points[i+1])/2.6))):
				for sign_side in [-1,1]:
					if house_count>=(190 if is_home else 120):break
					var at=points[i]+direction*(step*2.6+1)+side*sign_side*1.15
					if (is_home and at.y>53) or not clear_plot(at):continue
					house(at,Vector2(rng.randf_range(.85,1.35),rng.randf_range(.8,1.3)),"",atan2(-direction.y,direction.x));occupied.append(at)
	for feature in map.data.landmarks:
		if feature.tags.has("name"):mapped_landmarks.append(feature.tags.name)
		if feature.tags.get("leisure","")=="pitch":pitch(map.polygon_bounds(map.points(feature.points)))
		elif not feature.tags.has("building") and feature.tags.get("amenity","") in ["school","hospital"]:
			var bounds=map.polygon_bounds(map.points(feature.points))
			house(bounds.get_center(),Vector2(clampf(bounds.size.x,1.7,3),clampf(bounds.size.y,1.7,3)),feature.tags.get("name",""))
	harbour_details()
	# Instanced palms/shrubs are shared meshes, grouped spatially for culling.
	vegetation()
	for key in batches:
		chunk_count+=1
		var node=MeshInstance3D.new();node.name="VillageChunk";node.mesh=batches[key].commit();node.material_override=material;add_child(node)
		node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		node.position=batches[key].get_meta("origin");node.visibility_range_end=230
	batches.clear() # Release the build-time SurfaceTool buffers; only committed meshes remain.
	set_meta("mapped_coast_points",map.coast.size());set_meta("houses",house_count);set_meta("palms",palm_count)
func batch(at: Vector3) -> SurfaceTool:
	var key=Vector2i(floori(at.x/16),floori(at.z/16))
	if not batches.has(key):
		var tool=SurfaceTool.new();tool.begin(Mesh.PRIMITIVE_TRIANGLES);tool.set_meta("origin",Vector3(key.x*16,0,key.y*16));batches[key]=tool
	return batches[key]
func box(at: Vector3,size: Vector3,color: Color,yaw: float=0,tilt: float=0) -> void:
	var tool=batch(at)
	var frame=Basis.from_euler(Vector3(0,yaw,tilt));var shape=frame*Basis.from_scale(size)
	var vertices: PackedVector3Array=cube_arrays[Mesh.ARRAY_VERTEX]
	var normals: PackedVector3Array=cube_arrays[Mesh.ARRAY_NORMAL]
	var indices: PackedInt32Array=cube_arrays[Mesh.ARRAY_INDEX]
	for index in indices:
		tool.set_color(color.srgb_to_linear());tool.set_normal(frame*normals[index]);tool.add_vertex(at+shape*vertices[index]-tool.get_meta("origin"))
func terrain(polygon: PackedVector2Array,height: float,color: Color) -> void:
	var indices=Geometry2D.triangulate_polygon(polygon)
	var tool=SurfaceTool.new();tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(0,indices.size(),3):
		for j in [0,2,1]:
			var at=polygon[indices[i+j]];tool.set_normal(Vector3.UP);tool.set_color(color.srgb_to_linear());tool.add_vertex(Vector3(at.x,height,at.y))
	for i in range(polygon.size()):
		var a=polygon[i];var b=polygon[(i+1)%polygon.size()]
		var normal=Vector3(b.y-a.y,0,a.x-b.x).normalized()
		for p in [Vector3(a.x,height,a.y),Vector3(b.x,-1.2,b.y),Vector3(b.x,height,b.y),Vector3(a.x,height,a.y),Vector3(a.x,-1.2,a.y),Vector3(b.x,-1.2,b.y)]:
			tool.set_color(color.darkened(.12).srgb_to_linear());tool.set_normal(normal);tool.add_vertex(p)
	var node=MeshInstance3D.new();node.name="MappedShore";node.mesh=tool.commit();node.material_override=material.duplicate();node.material_override.cull_mode=BaseMaterial3D.CULL_DISABLED;node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;add_child(node)
func road(points: PackedVector2Array,track: bool) -> void:
	for i in range(points.size()-1):
		for section in Geometry2D.intersect_polyline_with_polygon(PackedVector2Array([points[i],points[i+1]]),map.coast):
			for j in range(section.size()-1):
				var a=section[j];var b=section[j+1];var at=(a+b)*.5
				box(Vector3(at.x,.205,at.y),Vector3(a.distance_to(b),.018,.17 if track else .32),Color("d6c8a5") if track else Color("c4bda5"),atan2(-(b.y-a.y),b.x-a.x))
func clear_plot(at: Vector2) -> bool:
	if not Geometry2D.is_point_in_polygon(at,grass_outline):return false
	if is_home and Rect2(23,8,14,18).has_point(at):return false
	for p in occupied:
		if p.distance_squared_to(at)<3.0:return false
	for bounds in landmark_bounds:
		if bounds.grow(.7).has_point(at):return false
	for road_points in road_lines:
		for i in range(road_points.size()-1):
			if Geometry2D.get_closest_point_to_segment(at,road_points[i],road_points[i+1]).distance_squared_to(at)<.42*.42:return false
	return true
func house(at: Vector2,size: Vector2,title: String,yaw: float=0) -> void:
	if not Geometry2D.is_point_in_polygon(at,grass_outline) or (is_home and Map.Harbour.contains(at)):return
	house_count+=1
	var walls=[Color("e9deca"),Color("e0cba2"),Color("b6d8ce"),Color("d9b79c"),Color("c6d3dc")]
	var roofs=[Color("47898a"),Color("a76049"),Color("708b82"),Color("6f8294")]
	var h=rng.randf_range(.65,1.05);var wall=walls[rng.randi_range(0,walls.size()-1)];var roof=roofs[rng.randi_range(0,roofs.size()-1)]
	var origin=Vector3(at.x,.22,at.y);var frame=Basis(Vector3.UP,yaw)
	box(origin+Vector3(0,h*.5,0),Vector3(size.x,h,size.y),wall,yaw)
	# Two pitched metal roof sheets, slight overhang, shaded porch and blue shutters.
	for side in [-1,1]:
		box(origin+frame*Vector3(side*size.x*.255,h+.12,0),Vector3(size.x*.58,.055,size.y+.18),roof,yaw,-side*.30)
	box(origin+frame*Vector3(0,h*.36,-size.y*.505),Vector3(.24,h*.72,.025),Color("416d71"),yaw)
	for side in [-1,1]:
		box(origin+frame*Vector3(side*size.x*.31,h*.62,-size.y*.51),Vector3(.17,.22,.025),Color("82b4bb"),yaw)
		box(origin+frame*Vector3(side*size.x*.31,h*.62+.015,-size.y*.525),Vector3(.014,.21,.015),wall.darkened(.25),yaw)
	if house_count%3==0:
		box(origin+frame*Vector3(0,.20,-size.y*.65),Vector3(size.x+.30,.40,.055),wall.darkened(.08),yaw)
		box(origin+frame*Vector3(size.x*.60,.20,0),Vector3(.05,.40,size.y+.30),wall.darkened(.08),yaw)
	if "Miski" in title or "Masjid" in title:
		var p=origin+Vector3(size.x*.65,1.5,0)
		box(p,Vector3(.25,2.6,.25),Color("ece9d5"));box(p+Vector3(0,1.34,0),Vector3(.38,.13,.38),Color("448f87"))
		box(p+Vector3(0,1.58,0),Vector3(.075,.4,.075),Color("ded4a1"))
	if "Council" in title:box(origin+Vector3(0,h+.22,0),Vector3(.8,.18,.6),Color("427d85"))
func pitch(bounds: Rect2) -> void:
	if is_home and Map.Harbour.contains(bounds.get_center()):return
	var center=bounds.get_center();var size=bounds.size
	box(Vector3(center.x,.235,center.y),Vector3(size.x,.025,size.y),Color("7f9c70"))
	for side in [-1,1]:
		box(Vector3(center.x+side*size.x*.46,.255,center.y),Vector3(.04,.01,size.y*.92),Color("dfdfbd"))
		box(Vector3(center.x,.255,center.y+side*size.y*.46),Vector3(size.x*.92,.01,.04),Color("dfdfbd"))
func vegetation() -> void:
	var tree=SurfaceTool.new();tree.begin(Mesh.PRIMITIVE_TRIANGLES)
	# One reusable palm: tapered trunk and arching low-poly fronds.
	for i in range(7):
		var a=float(i)/7*TAU;var b=float(i+1)/7*TAU
		for p in [Vector3(cos(a)*.07,0,sin(a)*.07),Vector3(.12+cos(b)*.045,1.8,sin(b)*.045),Vector3(.12+cos(a)*.045,1.8,sin(a)*.045),Vector3(cos(a)*.07,0,sin(a)*.07),Vector3(cos(b)*.07,0,sin(b)*.07),Vector3(.12+cos(b)*.045,1.8,sin(b)*.045)]:
			tree.set_color(Color("9c8763").srgb_to_linear());tree.set_normal(Vector3(cos(a),0,sin(a)));tree.add_vertex(p)
	for i in range(7):
		var a=i*TAU/7;var forward=Vector3(cos(a),0,sin(a));var side=Vector3(-sin(a),0,cos(a))
		for step in range(3):
			var t=float(step)/3;var u=float(step+1)/3
			var p=Vector3(.12,1.8,0)+forward*t*.95+Vector3.UP*(sin(t*PI)*.15-t*t*.35)
			var q=Vector3(.12,1.8,0)+forward*u*.95+Vector3.UP*(sin(u*PI)*.15-u*u*.35)
			for v in [p-side*sin(t*PI)*.16,q-side*sin(u*PI)*.16,p+side*sin(t*PI)*.16,p+side*sin(t*PI)*.16,q-side*sin(u*PI)*.16,q+side*sin(u*PI)*.16]:
				tree.set_color((Color("467b52") if i%2 else Color("71955b")).srgb_to_linear());tree.set_normal(Vector3.UP);tree.add_vertex(v)
	var mesh=tree.commit();mesh.surface_set_material(0,material.duplicate());mesh.surface_get_material(0).cull_mode=BaseMaterial3D.CULL_DISABLED
	var groups: Dictionary={}
	for i in range(900 if is_home else 500):
		var p=Vector2(rng.randf_range(map.bounds.position.x,map.bounds.end.x),rng.randf_range(map.bounds.position.y,map.bounds.end.y))
		if not Geometry2D.is_point_in_polygon(p,grass_outline):continue
		var clear=true
		for at in occupied:
			if at.distance_squared_to(p)<2:clear=false;break
		if not clear:continue
		for bounds in landmark_bounds:
			if bounds.grow(.3).has_point(p):clear=false;break
		if clear:
			for path in road_lines:
				for j in range(path.size()-1):
					if Geometry2D.get_closest_point_to_segment(p,path[j],path[j+1]).distance_squared_to(p)<.3*.3:clear=false;break
				if not clear:break
		if not clear:continue
		var key=Vector2i(floori(p.x/16),floori(p.y/16))
		if not groups.has(key):groups[key]=[]
		var scale=rng.randf_range(.85,1.5)
		groups[key].append(Transform3D(Basis(Vector3.UP,rng.randf()*TAU).scaled(Vector3.ONE*scale),Vector3(p.x,.22,p.y)));palm_count+=1
	for key in groups:
		var node=MultiMeshInstance3D.new();node.name="PalmGrove";node.multimesh=MultiMesh.new();node.multimesh.transform_format=MultiMesh.TRANSFORM_3D;node.multimesh.mesh=mesh;node.multimesh.instance_count=groups[key].size()
		node.position=Vector3(key.x*16,0,key.y*16);node.visibility_range_end=230
		for i in range(groups[key].size()):
			var frame: Transform3D=groups[key][i];frame.origin-=node.position;node.multimesh.set_instance_transform(i,frame)
		node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;add_child(node)

func harbour_box(port: Dictionary,u: float,y: float,v: float,size: Vector3,color: Color) -> void:
	var p=Harbours.local_point(port,u,v)
	box(Vector3(p.x,y,p.y),size,color,atan2(-port.inward.y,port.inward.x))

func harbour_details() -> void:
	var port=Harbours.get_port(island_title)
	for wall in port.walls:
		var a: Vector2=wall[0];var b: Vector2=wall[1];var at=(a+b)*.5
		box(Vector3(at.x,.0,at.y),Vector3(a.distance_to(b),.9,1.2),Color("92968a"),atan2(-(b.y-a.y),b.x-a.x))
		box(Vector3(at.x,.48,at.y),Vector3(a.distance_to(b),.12,1.35),Color("c2c3b1"),atan2(-(b.y-a.y),b.x-a.x))
		var steps=maxi(1,int(a.distance_to(b)/1.8))
		for i in range(steps):
			var p=a.lerp(b,(i+.5)/steps)
			box(Vector3(p.x,-.28,p.y),Vector3(.9,.45,1.65),Color("858d84"),atan2(-(b.y-a.y),b.x-a.x)+.10*sin(i))
	harbour_box(port,port.land+.6,.25,0,Vector3(2.2,.55,port.half*2+1),Color("bcbba7"))
	for side in [-1,1]:harbour_box(port,port.land-2,.10,side*(port.half-4),Vector3(5,.25,1.1),Color("a99977"))
	for v in [-port.half+4,-4,4,port.half-4]:
		harbour_box(port,port.land-.6,.05,v,Vector3(.24,.7,.50),Color("313e40"))
		harbour_box(port,port.land+.1,.68,v,Vector3(.13,.35,.13),Color("536669"))
		harbour_box(port,port.land+.1,.83,v,Vector3(.35,.09,.15),Color("536669"))
	for v in [-port.half+5,port.half-5]:
		moored_boat(Harbours.local_point(port,port.land-4,v),atan2(-port.inward.y,port.inward.x))
	for side in [-1,1]:
		var color=Color("bf534d") if side<0 else Color("438b68")
		harbour_box(port,-port.depth,.88,side*port.gate,Vector3(.32,.9,.32),color)
		harbour_box(port,-port.depth,1.4,side*port.gate,Vector3(.38,.16,.38),color.lightened(.3))
	var roof=[Color("3c8584"),Color("b49c6f"),Color("427eaa"),Color("ab654c"),Color("55774b")][port.theme]
	for side in [-1,1]:
		harbour_box(port,port.land+3,1.0,side*5,Vector3(3.4,1.6,3.4),Color("e4dcc4"))
		harbour_box(port,port.land+3,1.90,side*5,Vector3(3.8,.20,3.8),roof)
		harbour_box(port,port.land+1.27,.95,side*5,Vector3(.04,1.35,1.0),roof.darkened(.15))
	var art=preload("res://scripts/world_art.gd")
	var at=Harbours.local_point(port,port.land+1.2,-5)
	var label=art.label(self,island_title.replace("HA. ","")+" FISH MARKET",Vector3(at.x,2.25,at.y),18)
	label.rotation.y=atan2(-port.inward.y,port.inward.x)-PI/2
	label.visibility_range_end=60

func moored_boat(at: Vector2,yaw: float=0) -> void:
	var frame=Basis(Vector3.UP,yaw)
	var tool=batch(Vector3(at.x,0,at.y));var origin=tool.get_meta("origin") as Vector3
	var outline=[Vector2(-.22,.60),Vector2(.22,.60),Vector2(.25,-.25),Vector2(0,-.70),Vector2(-.25,-.25)]
	for i in range(outline.size()):
		var a: Vector2=outline[i];var b: Vector2=outline[(i+1)%outline.size()]
		var normal=Vector3(b.y-a.y,0,a.x-b.x).normalized()
		for p in [Vector3(a.x,-.35,a.y),Vector3(b.x,-.35,b.y),Vector3(b.x*.7,-.60,b.y*.85),Vector3(a.x,-.35,a.y),Vector3(b.x*.7,-.60,b.y*.85),Vector3(a.x*.7,-.60,a.y*.85)]:
			tool.set_color(Color("d1e0d9").srgb_to_linear());tool.set_normal(normal);tool.add_vertex(Vector3(at.x,0,at.y)+frame*p-origin)
	box(Vector3(at.x,-.40,at.y),Vector3(.35,.05,.95),Color("baaa83"),yaw)
	for z in [-.2,.25]:box(Vector3(at.x,-.31,at.y)+frame*Vector3(0,0,z),Vector3(.40,.04,.12),Color("6d8f8b"),yaw)
	box(Vector3(at.x,-.38,at.y)+frame*Vector3(0,0,.67),Vector3(.12,.23,.16),Color("3c4c50"),yaw)
