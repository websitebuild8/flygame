extends SceneTree
var failures: Array[String] = []
func _initialize() -> void:
	call_deferred("checks")
func check(condition: bool, text: String) -> void:
	if not condition:
		failures.append(text)
func checks() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	game.save_path = "user://gear-checks.json"
	root.add_child(game)
	game.set_physics_process(false)
	game.intro_visible = false
	game.intro.visible = false
	game.coins = 2000
	game.owned_items = ["island_reel","island_rod","mono"]
	game.equipped = {"Reels":"island_reel","Rods":"island_rod","Line":"mono"}
	game.boat_parts = []
	game.upgrade = 0
	game.return_home()
	check(not game.purchase_item("ocea"),"Gear cannot be purchased outside a shop")
	game.open_shop("Reels")
	check(game.shop_mode and game.interface.shop_panel.visible,"Dock opens island tackle shop")
	check(game.purchase_item("ocea"),"Earned coins buy overhead reel")
	check(game.coins==1680 and game.equipped.Reels=="island_reel","Incompatible reel is owned but does not silently equip on spinning rod")
	check(game.purchase_item("grappler"),"Jigging rod can be purchased")
	check(game.equipped.Reels=="ocea" and game.equipped.Rods=="grappler","Buying a compatible rod equips a complete jigging outfit")
	check(game.feedback.overhead,"First-person equipment switches to overhead model")
	var before = game.coins
	game.purchase_item("ocea")
	check(game.coins==before,"Equipping owned gear never charges again")
	game.purchase_item("powerpro")
	check(game.equipped.Line=="powerpro","Braid equips after purchase")
	game.purchase_item("propeller")
	game.purchase_item("icebox")
	check(game.icebox_capacity()==24 and "propeller" in game.boat_parts,"Boat parts change capacity and performance options")
	game.purchase_item("engine")
	check(game.upgrade==1 and game.item_price("engine")==200,"Engine stages have escalating game prices")
	game.save_trip()
	game.owned_items = []
	game.boat_parts = []
	game.equipped = {}
	game.load_trip()
	check(game.equipped.Reels=="ocea" and game.equipped.Line=="powerpro" and game.icebox_capacity()==24,"Ownership and loadout persist through saves")
	var imported=preload("res://scripts/tackle_art.gd").reel(game,"spinning","island_reel")
	check(imported.get_meta("imported_model",false),"Starter reel uses the imported textured model")
	check(is_instance_valid(imported.get_meta("crank")) and is_instance_valid(imported.get_meta("rotor")),"Imported reel keeps independent animation pivots")
	var crank=imported.get_meta("crank") as Node3D
	var rotor=imported.get_meta("rotor") as Node3D
	var spool=imported.get_meta("spool") as MeshInstance3D
	var body=imported.find_child("Object001_rod06_0",true,false) as MeshInstance3D
	var body_rest=body.global_transform
	var spool_rest=spool.global_transform
	var spool_center=spool.to_global(spool.get_aabb().get_center())
	var shaft=rotor.global_basis.x.normalized()
	check((spool_center-rotor.global_position).cross(shaft).length()<0.015,"Bail shaft stays aligned with the fixed spool centre")
	check(absf(shaft.dot(crank.global_basis.z.normalized()))<0.01,"Handle shaft is perpendicular to spool shaft")
	var rotor_mesh=rotor.get_child(0) as MeshInstance3D
	var rotor_rest=rotor_mesh.global_transform
	for step in range(24):
		crank.rotate_object_local(crank.get_meta("spin_axis"),TAU/24)
		rotor.rotate_object_local(rotor.get_meta("spin_axis"),TAU/24)
		check(body.global_transform.is_equal_approx(body_rest) and spool.global_transform.is_equal_approx(spool_rest),"Winding keeps the reel housing and spool fixed")
	check(rotor_mesh.global_transform.is_equal_approx(rotor_rest),"Bail completes a full revolution without drifting")
	imported.queue_free()
	game.equip_item("island_reel")
	check(game.equipped.Rods=="island_rod","Switching back to spinning equips compatible rod")
	game.leave_fishing()
	game.boat.position = game.SPOT
	game.speed = 0
	game.cast()
	game.fish_timer = 3
	game.reeling = true
	game._physics_process(0.1)
	var starter_progress = game.progress
	game.fishing = false
	game.fishing_view = false
	game.equip_item("ocea")
	game.cast()
	game.fish_timer = 3
	game.reeling = true
	game._physics_process(0.1)
	check(game.progress>starter_progress,"Upgraded tackle changes actual retrieval mechanics")
	game.leave_fishing()
	game.return_home()
	game.open_shop("Boat")
	game.coins = 0
	check(not game.purchase_item("engine") and game.upgrade==1,"Insufficient coins cannot buy an upgrade")
	game.leave_fishing()
	game.boat.position = game.SPOT
	game.open_shop("Boat")
	check(not game.shop_mode,"Shore shops cannot open out at sea")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(game.save_path))
	game.queue_free()
	await create_timer(0.3).timeout
	if failures.is_empty():
		print("PASS: shore shop access, coin purchases, rod/reel compatibility, overhead models, owned-item equip, boat parts, loadout saves, fishing bonuses")
		quit(0)
	else:
		for message in failures:
			push_error(message)
		quit(1)
