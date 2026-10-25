extends SceneTree
func _initialize():call_deferred("checks")
func checks():
	var game=load("res://scenes/main.tscn").instantiate();game.save_path="user://market-art-check.json";root.add_child(game);game.interface.start_trip();game.set_physics_process(false)
	assert(game.market.customers.size()==5,"Five customers remain queued")
	for person in game.market.customers:
		assert(person.get_meta("imported_model",false) and person.player,"Queue uses imported rigged characters with animation")
	assert(game.market.register.get_meta("imported_model",false),"Counter uses the imported cash register")
	var note=game.market.payment
	assert(note.get_meta("denomination")==100 and note.mesh.get_surface_count()==2,"Payment has both faces of the MVR 100 specimen")
	for surface in range(2):
		assert(note.mesh.surface_get_material(surface).albedo_texture,"Banknote faces have their actual artwork textures")
	game.coins=0;game.inventory=[{"species":"Yellowfin tuna","weight":8.2,"value":234}];game.hold_value=234
	game.return_home();game.sell();game._physics_process(.016)
	assert(game.market.seller_hands.visible and game.market.seller_hands.hands.get_meta("imported_model",false),"Market uses the same authored gloved hands")
	game.serve_customer();await create_timer(.5).timeout;game._physics_process(.016)
	assert(game.pending_payment==234 and game.market.payment.visible,"Note denomination does not replace the actual sale amount")
	assert(game.market.register_total.text=="MVR 234","Register shows the actual amount due")
	game.serve_customer();await create_timer(.5).timeout;game._physics_process(.016)
	assert(game.coins==234 and not game.market.payment.visible,"Collection credits the exact offer once")
	await create_timer(.9).timeout
	assert(game.market.customers.size()==5 and not game.market.queue_moving,"Animated customers complete the queue cycle")
	game.leave_fishing();game._physics_process(.016)
	assert(not game.market.seller_hands.visible,"Counter hands hide after leaving the market")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(game.save_path));game.free()
	print("PASS: rigged customer queue, imported register, two-sided MVR specimen, gloved counter hands, exact payment and queue cycling")
	quit()
