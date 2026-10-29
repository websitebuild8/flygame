extends SceneTree
const World=preload("res://scripts/world_data.gd")
func _initialize():call_deferred("checks")
func checks():
	var game=load("res://scenes/main.tscn").instantiate()
	game.save_path="user://new-species-market-checks.json"
	root.add_child(game)
	game.set_physics_process(false)
	game.intro_visible=false
	game.intro.visible=false
	game.inventory=[]
	game.hold_value=0
	game.coins=0
	game.pending_payment=0
	game.boat.position=game.SPOT
	for index in [2,3,4,5,6]:
		game.cast()
		assert(game.fishing,"New species can enter the existing catch flow")
		game.clear_hooked_fish()
		game.active_species=World.FISH[index]
		game.active_catch=preload("res://scripts/catch_profile.gd").roll(game.active_species,game.rng)
		game.fish_actor=game.Art.fish(game,.1,game.active_species.name)
		game.land_fish()
		assert(game.inventory[-1].species==World.FISH[index].name,"Catch stores the new species identity")
		assert(game.catch_model.species_name==World.FISH[index].name,"Landed display uses that species' model")
		game.close_catch()
	game.return_home()
	game.sell()
	assert(game.market_mode,"Imported catches can enter the island market")
	var expected=game.hold_value
	for index in [2,3,4,5,6]:
		game.interface.refresh()
		assert(game.market.shown_species==World.FISH[index].name,"Market counter shows the correct fish")
		assert(game.market.displayed_fish.visible,"New fish is visible while offered for sale")
		game.serve_customer()
		await create_timer(.45).timeout
		assert(game.pending_payment>0,"Customer owes MVR for the fish")
		game.serve_customer()
		await create_timer(.85).timeout
	assert(game.inventory.is_empty() and game.coins==expected,"All new species sell for exactly their stored MVR value")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(game.save_path))
	game.queue_free()
	await create_timer(.3).timeout
	print("PASS: skipjack, sailfish, mahi-mahi, jobfish and grouper catch identities, showcase models, market previews and MVR sales")
	quit()
