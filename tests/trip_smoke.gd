extends SceneTree
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("run_checks")

func check(condition: bool, explanation: String) -> void:
	if not condition:
		failures.append(explanation)

func run_checks() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	game.save_path = "user://market-smoke-test.json"
	root.add_child(game)
	game.set_physics_process(false)
	game.intro_visible = false
	game.intro.visible = false
	game.coins = 0
	game.pending_payment = 0
	game.catches = 0
	game.inventory = []
	game.hold_value = 0
	game.upgrade = 0
	game.boat.position = game.SPOT
	game.speed = 0
	game.cast()
	check(game.fishing and game.fishing_view,"Casting enters first-person fishing")
	game.fish_timer = 3
	game.reeling = true
	game._physics_process(0.1)
	check(game.progress > 0 and game.bite_announced,"Reeling retrieves the hooked fish")
	var tension_before = game.tension
	game.reeling = false
	game._physics_process(0.1)
	check(game.tension < tension_before,"Releasing lowers tension")
	for i in range(3):
		if i>0: game.cast()
		game.land_fish()
		game.close_catch()
	check(game.inventory.size() == 3 and game.unlocked,"Catches fill icebox and unlock waters")
	game.sell()
	check(not game.market_mode,"Market cannot open away from home")
	game.return_home()
	game.sell()
	check(game.market_mode,"Dock opens first-person market")
	var original_total = game.hold_value
	game.serve_customer()
	var owed = game.pending_payment
	check(owed > 0 and game.coins == 0 and game.inventory.size() == 2,"Handing over reserves payment without crediting twice")
	game.leave_fishing()
	game.load_trip()
	check(game.pending_payment == owed,"Uncollected payment survives save/load")
	await create_timer(0.45).timeout
	game.sell()
	game.serve_customer()
	check(game.coins == owed and game.pending_payment == 0,"Collecting credits one payment")
	game.serve_customer()
	check(game.coins == owed and game.inventory.size() == 2,"Rapid taps cannot serve during queue movement")
	await create_timer(0.8).timeout
	for i in range(2):
		game.serve_customer()
		await create_timer(0.4).timeout
		game.serve_customer()
		await create_timer(0.8).timeout
	check(game.coins == original_total and game.inventory.is_empty(),"All catches conserve their value through individual sales")
	game.serve_customer()
	check(game.coins == original_total,"Empty icebox cannot create coins")
	game.leave_fishing()
	game.buy_upgrade()
	check(game.upgrade == 1 and game.coins == original_total-100,"Market earnings buy an engine upgrade")
	# Exercise aggregate-value save migration from the original prototype.
	var legacy = FileAccess.open(game.save_path,FileAccess.WRITE)
	legacy.store_string(JSON.stringify({"coins":7,"catches":3,"hold_value":125,"upgrade":0}))
	legacy.close()
	game.load_trip()
	check(game.inventory.size() == 3 and game.hold_value == 125,"Legacy catch value migrates without loss")
	check(game.coins==7,"MVR display retains the existing saved balance")
	game.sell()
	game.interface.refresh()
	check(game.info.text.begins_with("MVR 7"),"HUD shows the MVR balance")
	game.market.set_species("Fresh catch")
	game.market.set_sale(true,false)
	check(not game.market.displayed_fish.visible,"Legacy catches never show a retired placeholder model")
	game.market.set_species("Giant trevally")
	game.market.set_sale(true,false)
	check(game.market.displayed_fish.visible,"Imported fish remain visible at the counter")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(game.save_path))
	game.queue_free()
	await create_timer(0.25).timeout
	if failures.is_empty():
		print("PASS: fishing, inventory, unlock, market access, queue, payment recovery, double-tap protection, upgrades, legacy saves")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)
