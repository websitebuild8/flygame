extends Node3D
var game: Node3D
var displays: Array[SubViewport]=[]
var contents: Array[Control]=[]
var tick=0.0
var has_map=false
func configure(owner_game: Node3D,id: String):
	game=owner_game
	var specs=preload("res://scripts/cockpit_screen_mounts.gd").MOUNTS.get(id,[])
	for index in range(specs.size()):
		var viewport=SubViewport.new();viewport.size=Vector2i(400,240);viewport.disable_3d=true
		viewport.render_target_update_mode=SubViewport.UPDATE_ONCE;add_child(viewport);displays.append(viewport)
		var content=preload("res://scripts/cockpit_screen_content.gd").new()
		content.game=game;content.chart=index>0;content.portrait=id=="skiff"
		content.size=Vector2(400,240);viewport.add_child(content);contents.append(content)
		if index>0:has_map=true
		var corners=specs[index]
		var a=Vector3(corners[0][0],corners[0][1],corners[0][2])
		var b=Vector3(corners[1][0],corners[1][1],corners[1][2])
		var c=Vector3(corners[2][0],corners[2][1],corners[2][2])
		var normal=(b-a).cross(c-a).normalized()
		if normal.z<0:normal=-normal
		var offset=normal*.002
		var arrays=[];arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX]=PackedVector3Array([a+offset,b+offset,c+offset,b+offset,b+c-a+offset,c+offset])
		arrays[Mesh.ARRAY_TEX_UV]=PackedVector2Array([Vector2(0,0),Vector2(1,0),Vector2(0,1),Vector2(1,0),Vector2(1,1),Vector2(0,1)])
		var mesh=MeshInstance3D.new();mesh.name="NavigationScreen" if index>0 else "EngineScreen"
		mesh.mesh=ArrayMesh.new();mesh.mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
		mesh.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var material=StandardMaterial3D.new();material.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
		material.cull_mode=BaseMaterial3D.CULL_DISABLED;material.albedo_texture=viewport.get_texture()
		material.texture_filter=BaseMaterial3D.TEXTURE_FILTER_LINEAR
		mesh.material_override=material;add_child(mesh)
func _process(delta: float):
	tick+=delta
	if tick<.1 or not game:return
	tick=0
	if not game.first_person_driving or game.intro_visible or game.market_mode or game.shop_mode or not game.app_active or game.interface.menu_visible:return
	for index in range(displays.size()):
		contents[index].queue_redraw();displays[index].render_target_update_mode=SubViewport.UPDATE_ONCE
