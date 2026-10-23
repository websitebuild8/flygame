extends SceneTree
const World=preload("res://scripts/world_data.gd")
const Art=preload("res://scripts/world_art.gd")
func _initialize() -> void: call_deferred("checks")
func checks() -> void:
	assert(World.FISH.size()==5,"Five imported fish species are catchable")
	for spot in World.SPOTS:
		assert(not spot.fish.is_empty(),"Every fishing spot retains catches")
		for index in spot.fish:
			assert(index>=0 and index<World.FISH.size(),"Spot indices match the species catalogue")
	var holder=Node3D.new()
	root.add_child(holder)
	for entry in World.FISH:
		var fish=Art.fish(holder,1,entry.name)
		assert(fish.get_script().resource_path!="res://scripts/fish_model.gd","Active fish never use procedural placeholders")
		var triangles=0
		for mesh_node in fish.find_children("*","MeshInstance3D",true,false):
			for surface in range(mesh_node.mesh.get_surface_count()):
				var arrays=mesh_node.mesh.surface_get_arrays(surface)
				triangles+=arrays[Mesh.ARRAY_INDEX].size()/3
				var material=mesh_node.get_active_material(surface)
				var texture=material.get_shader_parameter("skin_texture") if material is ShaderMaterial else material.albedo_texture
				if texture: assert(texture.get_width()<=1024,"Mobile colour textures remain at 1k")
				if entry.name=="Giant trevally": assert(texture,"Both scanned trevally surfaces retain colour textures")
		var budget={"Yellowfin tuna":10000,"Giant trevally":60000,"Skipjack tuna":80000,"Sailfish":30000,"Mahi-mahi":30000}[entry.name]
		assert(triangles>1000 and triangles<budget,"Imported fish stay within their measured mesh budgets")
		if entry.name=="Yellowfin tuna":
			assert(fish.player and fish.player.has_animation("Swim"),"Tuna retains its imported rig animation")
			assert(fish.player.get_animation("Swim").loop_mode==Animation.LOOP_LINEAR)
			var other=Art.fish(holder,1,entry.name)
			assert(fish.player.get_animation("Swim")!=other.player.get_animation("Swim"),"Tuna playback is independent")
		elif entry.name=="Giant trevally":
			assert(fish.skins.size()==2,"Trevally keeps both scanned texture regions")
			var other=Art.fish(holder,1,entry.name)
			assert(fish.skins[0]!=other.skins[0],"Trevally deformation is per-instance")
			fish.swim_intensity=2
			fish._process(.1)
			assert(fish.skins[0].get_shader_parameter("phase")>0,"Trevally tail moves while active")
		else:
			assert(not fish.skins.is_empty(),"New species retain independent swimming materials")
			var other=Art.fish(holder,1,entry.name)
			assert(fish.skins[0]!=other.skins[0],"New species do not share movement state")
			fish.swim_intensity=2
			fish._process(.1)
			assert(fish.skins[0].get_shader_parameter("phase")>0,"New species move while hooked")
	var available=[]
	for spot in World.SPOTS:
		for index in spot.fish:
			if index not in available:available.append(index)
	assert(available.size()==World.FISH.size(),"Every imported species can be caught somewhere")
	holder.queue_free()
	await process_frame
	print("PASS: imported-only catches, valid fishing spots, mesh budgets, 1k textures and independent movement for all five species")
	quit()
