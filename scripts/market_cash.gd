extends Node3D
## Whole-rufiyaa tender using actual circulating note/coin denominations.
const DENOMINATIONS=[1000,500,100,50,20,10,5,2,1]
static var meshes: Dictionary={}
var amount=-1
static func breakdown(value: int) -> Dictionary:
	var remaining=maxi(value,0)
	var result={}
	for denomination in DENOMINATIONS:
		var count=remaining/denomination
		if count>0:result[denomination]=count
		remaining%=denomination
	return result
func set_amount(value: int) -> void:
	value=maxi(value,0)
	if amount==value:return
	amount=value;set_meta("total_mvr",value)
	for child in get_children():remove_child(child);child.queue_free()
	var tender=breakdown(value)
	var note_count=0
	for denomination in tender:
		if denomination>=5:note_count+=tender[denomination]
	var note_index=0;var coin_index=0
	for denomination in tender:
		var quantity=int(tender[denomination])
		var bundle=MultiMeshInstance3D.new()
		bundle.name="MVR%d_%s" % [denomination,"Notes" if denomination>=5 else "Coins"]
		bundle.set_meta("denomination",denomination);bundle.set_meta("quantity",quantity)
		var instances=MultiMesh.new();instances.transform_format=MultiMesh.TRANSFORM_3D
		instances.mesh=currency_mesh(denomination);instances.instance_count=quantity
		bundle.multimesh=instances;add_child(bundle)
		for index in range(quantity):
			var at: Vector3
			var angle: float
			if denomination>=5:
				var spread=mini(note_count,7)
				var slot=note_index%7
				at=Vector3((slot-float(spread-1)*.5)*.105,float(note_index)*.0005,-.05+float(slot%2)*.035)
				angle=(slot-float(spread-1)*.5)*.045
				note_index+=1
			else:
				at=Vector3(-.09+coin_index*.075,.0016,.17)
				angle=coin_index*.3;coin_index+=1
			instances.set_instance_transform(index,Transform3D(Basis(Vector3.UP,angle),at))
static func currency_mesh(denomination: int) -> ArrayMesh:
	if meshes.has(denomination):return meshes[denomination]
	var mesh=ArrayMesh.new()
	if denomination>=5:
		for side in range(2):
			var path="res://assets/models/market/mvr%d_%s.%s" % [denomination,"front" if side==0 else "back","jpg" if denomination==5 and side==1 else "png"]
			var texture=load(path) as Texture2D
			var arrays=[];arrays.resize(Mesh.ARRAY_MAX)
			var y=.0003 if side==0 else 0.0
			arrays[Mesh.ARRAY_VERTEX]=PackedVector3Array([Vector3(-.16,y,-.075),Vector3(.16,y,-.075),Vector3(.16,y,.075),Vector3(-.16,y,.075)])
			var uvs=PackedVector2Array([Vector2(0,0),Vector2(1,0),Vector2(1,1),Vector2(0,1)])
			# Preserve original portrait specimen scans; turn their UVs to lie across the counter.
			if texture.get_height()>texture.get_width():uvs=PackedVector2Array([Vector2(0,1),Vector2(0,0),Vector2(1,0),Vector2(1,1)])
			arrays[Mesh.ARRAY_TEX_UV]=uvs
			arrays[Mesh.ARRAY_NORMAL]=PackedVector3Array([Vector3.UP if side==0 else Vector3.DOWN,Vector3.UP if side==0 else Vector3.DOWN,Vector3.UP if side==0 else Vector3.DOWN,Vector3.UP if side==0 else Vector3.DOWN])
			arrays[Mesh.ARRAY_INDEX]=PackedInt32Array([0,2,1,0,3,2] if side==0 else [0,1,2,0,2,3])
			mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
			var material=StandardMaterial3D.new();material.albedo_texture=texture;material.roughness=.85
			mesh.surface_set_material(side,material)
	else:
		var cylinder=CylinderMesh.new();cylinder.top_radius=.029;cylinder.bottom_radius=.029;cylinder.height=.003;cylinder.radial_segments=32
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,cylinder.surface_get_arrays(0))
		var metal=StandardMaterial3D.new();metal.albedo_color=Color("b7ac73") if denomination==2 else Color("adb9b8");metal.metallic=.65;metal.roughness=.4
		mesh.surface_set_material(0,metal)
		var arrays=[];arrays.resize(Mesh.ARRAY_MAX)
		var vertices=PackedVector3Array([Vector3(0,.0017,0)]);var normals=PackedVector3Array([Vector3.UP]);var uvs=PackedVector2Array([Vector2(.5,.5)]);var indices=PackedInt32Array()
		for i in range(33):
			var angle=float(i)*TAU/32
			vertices.append(Vector3(cos(angle)*.029,.0017,sin(angle)*.029));normals.append(Vector3.UP);uvs.append(Vector2(.5+cos(angle)*.49,.5+sin(angle)*.49))
			if i<32:indices.append_array(PackedInt32Array([0,i+2,i+1]))
		arrays[Mesh.ARRAY_VERTEX]=vertices;arrays[Mesh.ARRAY_NORMAL]=normals;arrays[Mesh.ARRAY_TEX_UV]=uvs;arrays[Mesh.ARRAY_INDEX]=indices
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
		var face=StandardMaterial3D.new();face.albedo_texture=load("res://assets/models/market/mvr%d_coin.jpg" % denomination);face.roughness=.6
		mesh.surface_set_material(1,face)
	meshes[denomination]=mesh
	return mesh
