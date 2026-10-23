extends SceneTree
func _initialize():call_deferred("convert")
func convert():
	var args=OS.get_cmdline_user_args()
	assert(args.size()==2,"Usage: -- SOURCE_FOLDER OUTPUT.glb")
	var doc=FBXDocument.new()
	var state=FBXState.new()
	var err=doc.append_from_file(args[0].path_join("Coryphaena_hippurus.fbx"),state)
	assert(err==OK,"FBX source import failed")
	var scene=doc.generate_scene(state)
	root.add_child(scene)
	var image=Image.load_from_file(args[0].path_join("Corypheaena_hippuris_textura.png"))
	image.resize(1024,1024,Image.INTERPOLATE_LANCZOS)
	var texture=ImageTexture.create_from_image(image)
	for mesh in scene.find_children("*","MeshInstance3D",true,false):
		print(mesh.name," ",mesh.global_transform*mesh.get_aabb())
		for surface in range(mesh.mesh.get_surface_count()):
			var mat=StandardMaterial3D.new();mat.albedo_texture=texture;mat.roughness=.38
			mesh.mesh.surface_set_material(surface,mat)
	var gltf=GLTFDocument.new();var gs=GLTFState.new()
	assert(gltf.append_from_scene(scene,gs)==OK)
	assert(gltf.write_to_filesystem(gs,args[1])==OK)
	quit()
