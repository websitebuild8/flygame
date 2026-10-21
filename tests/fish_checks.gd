extends SceneTree
func _initialize() -> void:
	call_deferred("checks")
func checks() -> void:
	var models={}
	for entry in preload("res://scripts/world_data.gd").FISH:
		var fish=preload("res://scripts/fish_model.gd").new()
		root.add_child(fish)
		fish.setup(entry.name)
		models[entry.name]=fish
		for i in range(201):
			var shape=fish.profile(float(i)/200)
			assert(shape.is_finite() and shape.x>0 and shape.y>0,"Species profile must stay finite and closed: "+entry.name)
		assert(fish.tail and fish.get_child_count()>10,"Every species has fins and facial anatomy")
	var tuna=models["Yellowfin tuna"]
	assert(models["Giant trevally"].profile(.2).y>tuna.profile(.2).y*1.3,"Trevally needs a steep, deep forehead")
	assert(models["Great barracuda"].profile(.4).y<tuna.profile(.4).y*.6,"Barracuda needs a narrow elongated body")
	assert(models["Marble grouper"].profile(.13).x>tuna.profile(.13).x*1.3,"Grouper needs a broad head")
	for fish in models.values(): fish.queue_free()
	await process_frame
	print("PASS: all 15 fish build with valid anatomy; trevally, barracuda and grouper have distinct silhouettes")
	quit()
