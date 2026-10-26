extends SceneTree
func _initialize():call_deferred("checks")
func checks():
	var game=load("res://scenes/main.tscn").instantiate()
	game.save_path="user://graphics-check.json"
	root.add_child(game)
	game.set_physics_process(false)
	for quality in range(3):
		game.graphics_quality=quality
		game.graphics_shadows=false
		game.apply_graphics()
		assert(is_equal_approx(root.scaling_3d_scale,[.6,.8,1.0][quality]))
		assert(game.ocean_mesh.subdivide_width==[32,64,100][quality])
		game.day_cycle.hours=12
		game.day_cycle.apply_lighting()
		assert(not game.day_cycle.sun.shadow_enabled,"Day cycle must respect shadows off")
	game.graphics_quality=1
	game.graphics_shadows=true
	game.apply_graphics()
	assert(game.day_cycle.sun.shadow_enabled)
	game.save_trip()
	game.graphics_quality=0;game.graphics_shadows=false
	game.load_trip()
	assert(game.graphics_quality==1 and game.graphics_shadows,"Graphics choices persist")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(game.save_path))
	game.free()
	print("PASS: quality presets, resolution, ocean detail, independent shadows and saved preferences")
	quit()
