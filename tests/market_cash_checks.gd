extends SceneTree
const Cash=preload("res://scripts/market_cash.gd")
func _initialize():call_deferred("checks")
func checks():
	assert(Cash.breakdown(120)=={100:1,20:1})
	assert(Cash.breakdown(125)=={100:1,20:1,5:1})
	assert(Cash.breakdown(234)=={100:2,20:1,10:1,2:2})
	for value in range(5001):
		var tender=Cash.breakdown(value);var total=0
		for denomination in tender:total+=denomination*tender[denomination]
		assert(total==value,"Every whole-rufiyaa price has exact tender")
	var cash=Cash.new();root.add_child(cash)
	for value in [1,2,4,5,10,20,50,100,120,125,234,500,1000,1687,12799]:
		cash.set_amount(value)
		var total=0
		for bundle in cash.get_children():
			var denomination=int(bundle.get_meta("denomination"))
			total+=denomination*bundle.multimesh.instance_count
			assert(bundle.multimesh.instance_count==bundle.get_meta("quantity"))
			var mesh=bundle.multimesh.mesh
			assert(mesh.get_surface_count()==2)
			assert(mesh.surface_get_material(1).albedo_texture,"Both note faces and coin denomination have real artwork")
		assert(total==value and cash.get_meta("total_mvr")==value,"Visible money equals the sale amount")
	cash.set_amount(0);assert(cash.get_child_count()==0)
	cash.free()
	var game=load("res://scenes/main.tscn").instantiate();game.save_path="user://cash-check.json";root.add_child(game);game.interface.start_trip();game.set_physics_process(false)
	game.coins=0;game.pending_payment=120;game.return_home();game.sell();game.interface.refresh()
	assert(game.market.payment.visible and game.market.payment.get_meta("total_mvr")==120)
	game.save_trip();game.pending_payment=0;game.load_trip();game.interface.refresh()
	assert(game.market.payment.get_meta("total_mvr")==120,"Pending exact tender survives save restoration")
	game.serve_customer();game.interface.refresh()
	assert(game.coins==120 and not game.market.payment.visible,"Collecting cash credits and clears the exact amount")
	await create_timer(.9).timeout
	assert(game.coins==120,"Collection animation never changes the credited amount")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(game.save_path));game.queue_free();await process_frame
	print("PASS: exact denomination breakdown, real note/coin meshes, payment restoration and exact collection")
	quit()
