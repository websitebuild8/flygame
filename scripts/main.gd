extends Node3D

const Art = preload("res://scripts/world_art.gd")
const World = preload("res://scripts/world_data.gd")
const Catalog = preload("res://scripts/gear_catalog.gd")

const SAVE_PATH = "user://trip.json"
var save_path = SAVE_PATH
const DOCK = Vector3(World.Harbour.HOME.x,0,World.Harbour.HOME.y) # Moor beside the jetty, clear of its posts and planks.
const SPOT = Vector3(0, 0, -45)
var boat: Node3D
var camera: Camera3D
var helm_hands: Node3D
var status: Label
var info: Label
var fish_button: Button
var message = "Set your course for the blue-and-white fishing buoy."
var coins = 0
var catches = 0
var hold_value = 0
var upgrade = 0
var unlocked = false
var speed = 0.0
var elapsed = 0.0
var fishing = false
var landing_to_boat=false
var fish_timer = 0.0
var progress = 0.0
var tension = 0.0
var reeling = false
var rng = RandomNumberGenerator.new()
var fishing_view = false
var bite_announced = false
var space_was_down = false
var feedback: Node3D
var driving_controls: Control
var tension_bar: ProgressBar
var landing_bar: ProgressBar
var fishing_meters: VBoxContainer
var hint_label: Label
var inventory: Array = []
var pending_payment = 0
var market_mode = false
var active_market_island="HA. Kelaa"
var market: Node3D
var market_button: Button
var upgrade_button: Button
var drive_button: Button
var home_button: Button
var market_action: Button
var catch_overlay: PanelContainer
var catch_text: Label
var catch_model: Node3D
var intro: PanelContainer
var intro_visible = true
var hud: Control
var drive = preload("res://scripts/boat_drive.gd").new()
var interface: CanvasLayer
var engine_audio: Node
var wake: Node3D
var owned_items: Array = ["island_reel","island_rod","mono"]
var equipped = {"Reels":"island_reel","Rods":"island_rod","Line":"mono"}
var boat_parts: Array = []
var shop_mode = false
var shop: Node3D
var app_active = true
var navigation=preload("res://scripts/sea_navigation.gd").new()
var day_cycle: Node
var graphics_quality = 0 if OS.has_feature("mobile") else 2
var graphics_shadows = not OS.has_feature("mobile")
var ocean_mesh: PlaneMesh
var saved_hours=8.0
var saved_waypoint: Array=[]
var route_tick=0.0
var autosave_tick=0.0
var owned_boats: Array=["skiff"]
var equipped_boat="skiff"
var boat_visual: Node3D
var first_person_driving=false
var camera_mode=0
const CAMERA_NAMES=["External","POV","Bird’s-eye","Close external"]
var cockpit_displays: Node3D
var traffic: Node3D
var collision_cooldown=0.0
var water_port=""
var shallow_life: RefCounted
var surface=preload("res://scripts/water_surface.gd").new()
var catch_fill: OmniLight3D
var active_spot: Dictionary={}
var active_species: Dictionary={}
var active_catch: Dictionary={}
var hook_clock=0.0
var fishing_camera_offset=Vector3.ZERO
var fishing_camera_look=Vector3.ZERO
var catch_show_age=0.0
var cosmetics=preload("res://scripts/cosmetics.gd").new()
var trip_progress=preload("res://scripts/trip_progress.gd").new()
var experience=preload("res://scripts/angler_xp.gd").new()
var spot_challenges=preload("res://scripts/spot_challenges.gd").new()
var saved_challenge_pose: Array=[]

func hook_timing() -> float:
	return .5+.5*sin(hook_clock*3.8)

func power_reel() -> void:
	if fishing and fight.request_power():
		message="POWER REEL!"
		feedback.haptic(90,.75)
var fight=preload("res://scripts/fish_fight.gd").new()
var fish_actor: Node3D
var fish_splash_timer=0.0
var fishing_buoys: Array[Node3D]=[]
var waypoint_marker: Node3D

func _ready() -> void:
	rng.randomize()
	load_trip()
	build_world()
	build_ui()
	feedback = load("res://scripts/fishing_feedback.gd").new()
	add_child(feedback)
	feedback.attach_camera(camera)
	apply_equipment()
	hud.visible = false
	market = load("res://scripts/market.gd").new()
	add_child(market)
	catch_model = Art.fish(camera, 0.8)
	catch_model.position = Vector3(0, -0.1, -3)
	catch_model.basis = (Basis(Vector3(0,0,1),-PI/2) * Basis(Vector3.UP,PI/2)).scaled(Vector3.ONE*0.8*float(active_catch.get("size",1)))
	catch_model.visible = false
	engine_audio = preload("res://scripts/engine_audio.gd").new()
	add_child(engine_audio)
	wake = preload("res://scripts/boat_wake.gd").new()
	add_child(wake)
	shop = preload("res://scripts/island_shop.gd").new()
	add_child(shop)
	navigation.configure(unlocked)
	if saved_waypoint.size()==2:
		set_waypoint(Vector2(float(saved_waypoint[0]),float(saved_waypoint[1])),"Saved waypoint")
	apply_graphics()
	update_scene_activity()
	traffic=preload("res://scripts/sea_traffic.gd").new();add_child(traffic);traffic.configure(self)
	restore_challenge_position()

func update_scene_activity() -> void:
	# Keep every asset; suspend the off-screen shops and their skeletal animations.
	for entry in [[market,market_mode],[shop,shop_mode]]:
		var room=entry[0] as Node3D
		if room:
			room.visible=entry[1]
			room.process_mode=Node.PROCESS_MODE_INHERIT if entry[1] else Node.PROCESS_MODE_DISABLED

func material(color: Color) -> StandardMaterial3D:
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.7
	return mat

func box(parent: Node3D, pos: Vector3, size: Vector3, color: Color) -> MeshInstance3D:
	var node = MeshInstance3D.new()
	var mesh = BoxMesh.new()
	mesh.size = size
	node.mesh = mesh
	node.material_override = material(color)
	parent.add_child(node)
	node.position = pos
	return node

func build_world() -> void:
	var environment = WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.background_mode = Environment.BG_SKY
	environment.environment.sky = Sky.new()
	var sky = ProceduralSkyMaterial.new()
	sky.sky_top_color = Color("367eb6")
	sky.sky_horizon_color = Color("f1d5b3")
	sky.ground_horizon_color = Color("f1d5b3")
	sky.ground_bottom_color = Color("548c9b")
	environment.environment.sky.sky_material = sky
	environment.environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color = Color.WHITE
	environment.environment.ambient_light_energy = 0.4
	environment.environment.fog_enabled=true
	environment.environment.fog_density=0.0011
	add_child(environment)
	var sun = DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-25, -40, 0)
	sun.light_color = Color("ffdfaf")
	sun.light_energy = 0.95
	sun.shadow_enabled=true
	sun.directional_shadow_max_distance=110
	add_child(sun)
	var ocean = MeshInstance3D.new()
	var plane = PlaneMesh.new()
	ocean_mesh=plane
	plane.size = Vector2(1800,1800)
	plane.subdivide_width = 100
	plane.subdivide_depth = 100
	ocean.mesh = plane
	var water = ShaderMaterial.new()
	water.shader = load("res://shaders/ocean.gdshader")
	water.set_shader_parameter("coast_map",load("res://assets/maps/ocean/coastal_depth.png"))
	water.set_shader_parameter("sand_texture",load("res://assets/textures/ocean/seabed_sand.webp"))
	water.set_shader_parameter("ripple_normal",load("res://assets/textures/ocean/ripple_normal.png"))
	shallow_life=preload("res://scripts/shallow_life.gd").new()
	ocean.material_override = water
	add_child(ocean)
	ocean.position.y = -0.6
	for island in World.ISLANDS:
		if island.name=="HA. Kelaa":
			add_child(preload("res://scripts/kelaa_island.gd").new())
		else:
			add_child(preload("res://scripts/neighbour_island.gd").new(island.name))
	day_cycle=preload("res://scripts/day_cycle.gd").new()
	day_cycle.sun=sun
	day_cycle.environment=environment.environment
	day_cycle.sky=sky
	day_cycle.water=water
	day_cycle.hours=saved_hours
	add_child(day_cycle)
	var star_root=Node3D.new()
	add_child(star_root)
	day_cycle.stars=star_root
	var star_mesh=MeshInstance3D.new()
	star_root.add_child(star_mesh)
	var positions=PackedVector3Array()
	var star_random=RandomNumberGenerator.new()
	star_random.seed=403
	for i in range(180):
		var direction=Vector3(star_random.randf_range(-1,1),star_random.randf_range(0.1,1),star_random.randf_range(-1,1)).normalized()
		positions.append(direction*1800)
	var star_arrays=[]
	star_arrays.resize(Mesh.ARRAY_MAX)
	star_arrays[Mesh.ARRAY_VERTEX]=positions
	var star_geometry=ArrayMesh.new()
	star_geometry.add_surface_from_arrays(Mesh.PRIMITIVE_POINTS,star_arrays)
	star_mesh.mesh=star_geometry
	var star_material=ShaderMaterial.new()
	var star_shader=Shader.new()
	star_shader.code="shader_type spatial; render_mode unshaded, fog_disabled; void vertex(){POINT_SIZE=2.0;} void fragment(){ALBEDO=vec3(0.7,0.8,1.0);}"
	star_material.shader=star_shader
	star_mesh.material_override=star_material
	day_cycle.moon=Art.oval(self,Vector3(-170,130,-360),Vector3.ONE*12,Color("cedbec"))
	var moon_mat=day_cycle.moon.material_override as StandardMaterial3D
	moon_mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	day_cycle.apply_lighting()
	var cloud_layer=MeshInstance3D.new()
	add_child(cloud_layer)
	var cloud_plane=PlaneMesh.new()
	cloud_plane.size=Vector2(1800,1800)
	cloud_layer.mesh=cloud_plane
	cloud_layer.position=Vector3(0,90,-150)
	var cloud_material=ShaderMaterial.new()
	cloud_material.shader=preload("res://shaders/clouds.gdshader")
	var noise=FastNoiseLite.new()
	noise.seed=742
	noise.frequency=0.012
	var texture=NoiseTexture2D.new()
	texture.width=512
	texture.height=512
	texture.seamless=true
	texture.noise=noise
	cloud_material.set_shader_parameter("cloud_noise",texture)
	cloud_layer.material_override=cloud_material
	day_cycle.clouds=cloud_material
	for spot in World.SPOTS:
		var buoy=preload("res://scripts/fishing_buoy.gd").new()
		buoy.position=Vector3(spot.at.x,0,spot.at.y)
		add_child(buoy);fishing_buoys.append(buoy)
		Art.label(self,spot.name,Vector3(spot.at.x,1.1,spot.at.y),22)
	for point in [Vector3(23,2,7),Vector3(23,2,25),Vector3(28,2,15)]:
		var light=OmniLight3D.new()
		add_child(light)
		light.position=point
		light.light_color=Color("ffcc8a")
		light.omni_range=12
		day_cycle.harbor_lights.append(light)
		var bulb=Art.oval(self,point,Vector3.ONE*0.12,Color("ffd69b"))
		(bulb.material_override as StandardMaterial3D).emission_enabled=true
		(bulb.material_override as StandardMaterial3D).emission=Color("ffc580")
	waypoint_marker=Node3D.new()
	add_child(waypoint_marker)
	var pin=Art.pole(waypoint_marker,Vector3(0,-0.5,0),Vector3(0,6,0),0.05,Color("f5c278"))
	(pin.material_override as StandardMaterial3D).emission_enabled=true
	(pin.material_override as StandardMaterial3D).emission=Color("f5c278")
	waypoint_marker.visible=false
	boat = Node3D.new()
	add_child(boat)
	boat.position = DOCK
	apply_boat()
	camera = Camera3D.new()
	add_child(camera)
	camera.current = true
	camera.fov = 65
	camera.near=.01
	camera.position = boat.position + Vector3(0, 10, 15)
	camera.look_at(boat.position)
	helm_hands=preload("res://scripts/helm_hands.gd").new()
	camera.add_child(helm_hands)
	helm_hands.configure(boat_visual)
	day_cycle.apply_lighting()

func build_ui() -> void:
	interface = preload("res://scripts/trip_hud.gd").new()
	add_child(interface)
	interface.build(self)

func _physics_process(delta: float) -> void:
	elapsed += delta
	collision_cooldown=maxf(0,collision_cooldown-delta)
	if market_mode:market.animate(elapsed)
	feedback.update_ambience(not intro_visible and not market_mode and not shop_mode and app_active and not interface.menu_visible and not interface.map_visible)
	if interface.menu_visible or interface.map_visible or not app_active:
		feedback.reel_audio.stop()
		feedback.stop_fight_haptics()
		engine_audio.update_audio(delta,0,0,false,feedback.sound_enabled)
		interface.refresh()
		return
	if intro_visible:
		engine_audio.update_audio(delta,0,0,false,feedback.sound_enabled)
		camera.position = DOCK + Vector3(10,6,13)
		camera.look_at(Vector3(20,1,24))
		return
	feedback.update_fight_haptics(delta,fishing and bite_announced and fight.hooked,tension,fight.running,landing_to_boat or fight.landing_lift>.65)
	update_port_water()
	day_cycle.advance(delta)
	surface.phase=elapsed;surface.roughness=day_cycle.roughness;surface.subdivisions=ocean_mesh.subdivide_width
	day_cycle.water.set_shader_parameter("wave_time",elapsed)
	day_cycle.water.set_shader_parameter("rough_sea",surface.roughness)
	if traffic:traffic.update(delta,not market_mode and not shop_mode)
	day_cycle.update_rain(camera.global_position,not shop_mode and not market_mode)
	shallow_life.update(delta,camera.position,elapsed,day_cycle.water,graphics_quality)
	autosave_tick+=delta
	if autosave_tick>30:
		autosave_tick=0
		save_trip()
	camera.cull_mask=1 if fishing_view else 3
	if catch_overlay.visible:
		engine_audio.update_audio(delta,0,0,false,feedback.sound_enabled)
		catch_show_age+=delta
		update_catch_presentation()
		feedback.update_feedback(delta,false,false,0,line_target())
		return
	spot_challenges.advance(delta,current_challenge_spot())
	for buoy in fishing_buoys:buoy.advance(delta,day_cycle.roughness)
	var space_down = Input.is_physical_key_pressed(KEY_SPACE)
	if space_down and not space_was_down and not fishing and not market_mode and not shop_mode:
		fishing_action()
	space_was_down = space_down
	var pulling = (reeling or space_down or fight.power_time>0) and fishing and fish_timer >= 2.5
	if fishing:
		speed = 0
		if landing_to_boat:
			feedback.update_feedback(delta,true,false,tension,line_target())
			interface.refresh()
			return
		fish_timer += delta
		if fish_timer < 2.5:
			message = ("Dropping jig…" if feedback.overhead else "Casting…") if feedback.cast_motion.is_casting() else "Bait in the water… wait for a bite."
		else:
			if not bite_announced:
				bite_announced = true
				feedback.bite_feedback()
				feedback.splash(line_target())
			hook_clock+=delta
			if not fight.hooked and pulling:
				var quality=clampf(1-absf(hook_timing()-.83)/.33,0,1)
				fight.strike(quality)
				feedback.hook_feedback(quality)
			var reel_stats = Catalog.item(str(equipped.Reels))
			var rod_stats = Catalog.item(str(equipped.Rods))
			var line_stats = Catalog.item(str(equipped.Line))
			fight.step(delta,pulling,float(reel_stats.retrieve),float(reel_stats.drag),float(rod_stats.power),float(line_stats.strength))
			tension=fight.tension
			progress=fight.progress
			update_hooked_fish(delta)
			message = "%s · %s · %d m away" % [active_species.get("name","Fish"),"MAKING A RUN" if fight.running else "Hold to reel",int(fight.position.distance_to(boat.position))]
			if not fight.hooked:message="Bite! Tap HOOK when the marker reaches the green zone."
			if fight.landing_lift>0.55:
				message="%s is clear of the water. Put fish on boat." % active_species.name
			if tension >= 1 or fight.escaped:
				fishing = false
				feedback.finish(false,line_target())
				clear_hooked_fish()
				message = "The fish escaped on slack line. Keep some pressure on." if fight.escaped else "The line snapped. Ease off the reel next time."

	elif not fishing_view and not market_mode and not shop_mode:
		var keyboard_steer = float(Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT))-float(Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT))
		var keyboard_throttle = float(Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP))-float(Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN))
		if keyboard_throttle != 0:
			driving_controls.lever_value = clampf(driving_controls.lever_value+keyboard_throttle*delta*0.55,-1,1)
		if Input.is_physical_key_pressed(KEY_N):
			driving_controls.neutral()
		var vessel=World.vessel(equipped_boat)
		drive.base_speed=minf(float(vessel.speed),4.0) if not World.Harbours.containing(Vector2(boat.position.x,boat.position.z)).is_empty() else float(vessel.speed)
		drive.handling=float(vessel.handling)
		drive.acceleration_multiplier=float(vessel.accel)
		drive.performance_propeller = "propeller" in boat_parts
		drive.set_lever(driving_controls.lever_value)
		drive.step(delta,keyboard_steer if keyboard_steer!=0 else driving_controls.wheel_command,upgrade)
		speed = drive.speed
		var wheel=boat_visual.get_node("HelmWheel") as Node3D
		wheel.basis=wheel.get_meta("rest_basis",Basis.IDENTITY)*Basis(Vector3.BACK,-drive.steering*2.3)
		update_outboards(delta)
		var old_yaw=boat.rotation.y
		boat.rotation.y += drive.yaw_rate()*delta
		var next = boat.position - boat.basis.z * speed * delta
		var from=Vector2(boat.position.x,boat.position.z);var to=Vector2(next.x,next.z)
		var blocked=not preload("res://scripts/marine_collision.gd").sweep_hull(from,to,old_yaw,boat.rotation.y,equipped_boat,unlocked)
		var boat_hit=traffic!=null and traffic.hull_motion_blocked(from,to,old_yaw,boat.rotation.y,equipped_boat)
		blocked=blocked or boat_hit
		if blocked and collision_cooldown<=0:
			message="Boat ahead. Reverse or steer clear." if boat_hit else "Quay or shallow water. Reverse and steer clear."
			feedback.haptic(45,.35);collision_cooldown=.8
		if not unlocked and next.x>World.EAST_UNLOCK:
			message="Catch 3 fish to unlock eastern waters."
		if not blocked and Vector2(next.x, next.z).length() < World.SEA_RADIUS:
			boat.position = next
		else:
			boat.rotation.y=old_yaw
			speed = 0
			drive.speed = 0
	boat.position.y = surface.height(Vector2(boat.position.x,boat.position.z))-surface.BASE
	boat.rotation.z = lerpf(boat.rotation.z,-drive.steering*absf(speed)*0.009+sin(elapsed*1.1)*day_cycle.roughness*0.035,1-exp(-delta*3))
	boat.rotation.x = lerpf(boat.rotation.x,-clampf(absf(speed)/12,0,1)*0.035,1-exp(-delta*2))
	preload("res://scripts/outboard_waterline.gd").update(boat_visual,surface)
	var driving = not fishing_view and not market_mode and not shop_mode
	engine_audio.update_audio(delta,drive.rpm,speed,driving,feedback.sound_enabled,drive.engine_running)
	wake.update_wake(delta,boat.global_position,boat.basis.z,speed if driving else 0,preload("res://scripts/outboard_waterline.gd").positions(boat_visual),drive.rpm if driving and drive.engine_running else 0,drive.gear if driving and drive.engine_running else 0)
	driving_controls.wheel_display = drive.steering
	driving_controls.shown_speed = absf(speed)
	driving_controls.shown_gear = drive.gear_name()
	driving_controls.shown_rpm = drive.rpm
	driving_controls.shift_waiting = drive.shift_waiting
	driving_controls.queue_redraw()
	route_tick+=delta
	if route_tick>0.6:
		route_tick=0
		navigation.update(Vector2(boat.position.x,boat.position.z))
	waypoint_marker.visible=navigation.has_destination and driving
	if navigation.has_destination:
		waypoint_marker.position=Vector3(navigation.destination.x,0,navigation.destination.y)
	if shop_mode:
		shop.pose_camera(camera)
	elif market_mode:
		market.pose_camera(camera)
	elif fishing_view:
		camera.position=boat_visual.get_node("FishingView").global_position if boat_visual.has_node("FishingView") else boat_visual.to_global(Vector3(0,1.55,-1.7))
		var forward=-boat.basis.z
		var view_target=camera.position+forward*12+Vector3(0,-0.6,0)
		var focus=fight.position-camera.position if fishing and bite_announced else forward*12
		var cast_pitch=feedback.cast_motion.camera_pitch()
		# Track angles rather than world offsets: close fish should stay in frame too.
		var forward_distance=maxf(.15,focus.dot(forward))
		var yaw=clampf(atan2(focus.dot(boat.basis.x),forward_distance),-.45,.45) if fishing and bite_announced else 0.0
		var pitch=clampf(atan2(focus.y,forward_distance),-.55,.42) if fishing and bite_announced else -.05
		var desired_look=Vector3(yaw,pitch,0)
		fishing_camera_look=fishing_camera_look.lerp(desired_look,1-exp(-delta*5.0))
		view_target=camera.position+forward*12+boat.basis.x*tan(fishing_camera_look.x)*12
		view_target.y+=tan(fishing_camera_look.y+cast_pitch)*12
		var load=tension if fishing and bite_announced else 0.0
		var kick=feedback.strike_kick
		var burst=fight.power_time>0 and fishing
		var bob=Vector3(sin(elapsed*5.1)*load*.018,sin(elapsed*4.4)*(.012+load*.018)+kick*.08+cast_pitch*.10, kick*.16+cast_pitch*.15)*World.BOAT_SCALE
		fishing_camera_offset=fishing_camera_offset.lerp(bob,1-exp(-delta*5))
		camera.position+=fishing_camera_offset
		camera.position.y=maxf(camera.position.y,surface.height(Vector2(camera.position.x,camera.position.z))+.24)
		view_target.y+=kick*.6
		camera.look_at(view_target)
		camera.rotate_object_local(Vector3.BACK,sin(elapsed*3.5)*load*.018-kick*.035-cast_pitch*.08+(sin(elapsed*12)*.012 if burst else 0.0))
		camera.fov=lerpf(camera.fov,77.0 if burst else (75.0 if feedback.cast_motion.is_casting() else (73.0 if kick>.1 else 70.0)),1-exp(-delta*5))
	elif first_person_driving:
		camera.position=boat_visual.get_node("DrivingView").global_position if boat_visual.has_node("DrivingView") else boat_visual.to_global(Vector3(0.53,1.30,1.37))
		camera.look_at(camera.position-boat.basis.z*35+Vector3(0,-4,0))
	else:
		camera.fov=55 if camera_mode==2 else 70
		var desired=boat.position+boat.basis.z*7+Vector3(0,4,0)
		if camera_mode==2:desired=boat.position+Vector3(0,24,.01)
		elif camera_mode==3:desired=boat.position+boat.basis.z*3.2+boat.basis.x*1.0+Vector3(0,1.6,0)
		camera.position=camera.position.lerp(desired,1-exp(-delta*5))
		camera.look_at(boat.position+Vector3(0,-.25,0),Vector3.FORWARD if camera_mode==2 else Vector3.UP)
	camera.h_offset=1.2 if shop_mode else 0.0
	market.update_hands(camera,market_mode)
	driving_controls.pov=first_person_driving and driving
	driving_controls.cockpit_screen=cockpit_displays!=null and not cockpit_displays.displays.is_empty()
	if driving_controls.pov:
		var transform=driving_controls.get_global_transform_with_canvas().affine_inverse()
		driving_controls.pov_wheel=transform*camera.unproject_position(boat_visual.get_node("HelmWheel").global_position)
		var wheel_node=boat_visual.get_node("HelmWheel")
		var wheel_edge=camera.unproject_position(wheel_node.global_position+camera.global_basis.x*wheel_node.global_basis.x.length()*0.18)
		driving_controls.pov_wheel_radius=maxf(87,(transform*wheel_edge).distance_to(driving_controls.pov_wheel))
		driving_controls.pov_lever=transform*camera.unproject_position(helm_hands.lever.to_global(helm_hands.lever_grip))
	feedback.update_feedback(delta, fishing_view and not market_mode, pulling, tension if fishing else 0.0, line_target())
	helm_hands.update_pose(delta,first_person_driving and driving and not intro_visible,drive.steering)
	interface.refresh()

func fishing_action() -> void:
	cast(not fishing_view)

func cast(preview_only: bool=false) -> void:
	if fishing or market_mode or shop_mode or intro_visible or catch_overlay.visible:
		return
	if inventory.size()>=icebox_capacity():
		message = "Your icebox is full. Sell your catch or upgrade storage."
		return
	active_spot=World.nearest(boat.position)
	if Vector2(boat.position.x,boat.position.z).distance_to(active_spot.at)>14:
		message="Choose a fishing spot on the map and approach its buoy."
		return
	if catches<int(active_spot.unlock):
		message="%s unlocks after %d catches." % [active_spot.name,active_spot.unlock]
		return
	if absf(speed) > 1 or (drive.engine_running and drive.gear != 0):
		message = "Select neutral and let the boat slow before casting."
		return
	if drive.engine_running:
		drive.reset()
		driving_controls.neutral()
	else:
		drive.speed=0
		speed=0
	if preview_only:
		fishing_view=true
		feedback.cast_motion.reset()
		fishing_camera_look=Vector3(0,-.05,0);fishing_camera_offset=Vector3.ZERO
		message="Jig ready. Tap DROP to lower it." if feedback.overhead else "Lure ready. Tap CAST to send it out."
		return
	var species_index=int(active_spot.fish[rng.randi_range(0,active_spot.fish.size()-1)])
	active_species=World.FISH[species_index]
	active_catch=preload("res://scripts/catch_profile.gd").roll(active_species,rng)
	hook_clock=0
	fight=preload("res://scripts/fish_fight.gd").new()
	fight.set_species(str(active_species.name))
	fight.start(boat.position,-boat.basis.z,float(active_catch.strength),World.BOAT_SCALE)
	fight.individual_phase=rng.randf_range(-PI,PI)
	fight.hooked=false
	clear_hooked_fish()
	fish_actor=Art.fish(self,0.45*World.BOAT_SCALE*float(active_catch.size),str(active_species.name))
	fish_actor.position=fight.position
	fish_actor.visible=false
	fish_actor.swim_intensity=2.0
	fishing = true
	fishing_view = true
	bite_announced = false
	feedback.cast_feedback(line_target())
	fish_timer = 0
	progress = 0
	tension = 0

func can_put_fish_on_boat() -> bool:
	return fishing and not landing_to_boat and bite_announced and fight.landing_lift>=0.65 and fish_actor!=null and hooked_fish_bottom()>surface.height(Vector2(fish_actor.position.x,fish_actor.position.z))+.025

func put_fish_on_boat() -> void:
	if not can_put_fish_on_boat(): return
	landing_to_boat=true
	reeling=false
	message="Bringing your catch aboard…"
	interface.refresh()
	var target=boat_visual.to_global(Vector3(-0.3,0.7,-0.8))
	var tween=create_tween()
	tween.tween_property(fish_actor,"position",target,0.65).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(fish_actor,"rotation:x",0.2,0.65)
	tween.tween_callback(func():
		landing_to_boat=false
		land_fish()
	)

func toggle_engine() -> void:
	if fishing_view or shop_mode or market_mode: return
	if drive.engine_running:
		drive.engine_running=false
		message="Engine off. Let the boat stop before fishing or entering harbour."
	elif absf(driving_controls.lever_value)>drive.NEUTRAL_DETENT:
		message="Select neutral before starting the engine."
	else:
		drive.engine_running=true
		message="Engine started."
	interface.refresh()

func land_fish() -> void:
	if not fishing: return
	fishing = false
	reeling = false
	feedback.finish(true, line_target())
	var definition=active_species if not active_species.is_empty() else World.FISH[0]
	var species=str(definition.name)
	# Preserve an individual's weight and offer from hook through market payment.
	if active_catch.get("species","")!=species:
		active_catch=preload("res://scripts/catch_profile.gd").roll(definition,rng)
	var value=int(active_catch.value)
	clear_hooked_fish()
	catches += 1
	hold_value += value
	var weight = float(active_catch.weight)
	inventory.append({"species":species,"value":value,"weight":weight})
	var discovery=trip_progress.record_catch({"species":species,"value":value,"weight":weight},str(active_spot.get("name","Open water")))
	var xp_gain=gain_xp(20+mini(int(weight),15)+(40 if discovery.new_species else 0)+(20 if discovery.record else 0))
	interface.catch_xp.text="+%d XP"%xp_gain.xp+(" · LEVEL %d!"%xp_gain.level if xp_gain.level_up else "")+("\nGift: "+", ".join(xp_gain.gifts) if not xp_gain.gifts.is_empty() else "")
	spot_challenges.record({"species":species,"weight":weight,"value":value},str(active_spot.get("id","")),day_cycle.hours)
	if not spot_challenges.result.is_empty() and spot_challenges.result.success:interface.catch_xp.text+="\nChallenge complete!"
	catch_text.text = "%s\n%s\n%.1f kg   ·   MVR %d\nMarket offer · MVR %.2f / kg" % [active_catch.grade,species,weight,value,float(value)/weight]
	interface.catch_medal.visible=discovery.new_species or discovery.record or active_catch.grade=="TROPHY" or (not spot_challenges.result.is_empty() and spot_challenges.result.success)
	interface.catch_medal.texture=preload("res://scripts/ui_art.gd").medal(0 if discovery.new_species else 2)
	if discovery.new_species:catch_text.text="NEW SPECIES DISCOVERED\n"+catch_text.text
	elif discovery.record:catch_text.text="NEW PERSONAL BEST\n"+catch_text.text
	catch_model.queue_free()
	catch_model = Art.fish(camera,0.8*float(active_catch.size),species)
	catch_model.position = Vector3(-0.8,0,-3)
	catch_model.basis = (Basis(Vector3(0,0,1),-PI/2) * Basis(Vector3.UP,PI/2)).scaled(Vector3.ONE*0.8*float(active_catch.get("size",1)))
	catch_model.rotate(Vector3.UP,-0.24)
	catch_show_age=0
	update_catch_presentation()
	catch_overlay.visible = true
	hud.visible = false
	catch_model.visible = true
	feedback.rig.visible = false
	unlocked = catches >= 3
	if navigation.region_open!=unlocked:
		navigation.configure(unlocked)
	message = "%s landed! Worth MVR %d. Return to the dock to sell.%s" % [species, value, " Eastern waters unlocked!" if catches == 3 else ""]
	save_trip()

func close_catch() -> void:
	hud.visible = true
	catch_overlay.visible = false
	catch_model.visible = false
	if catch_fill:catch_fill.visible=false
	message = "Catch stored on ice. Cast again or return to the island market."

func at_home_dock() -> bool:
	return not World.Harbours.berth_at(Vector2(boat.position.x,boat.position.z)).is_empty()

func sell() -> void:
	if fishing or catch_overlay.visible:
		return
	if not at_home_dock():
		message = "Enter an island harbour and approach its inner berth to visit the market."
		return
	if absf(speed)>1 or (drive.engine_running and drive.gear!=0):
		message = "Select neutral and slow down before entering the market."
		return
	leave_fishing()
	speed = 0
	active_market_island=World.Harbours.berth_at(Vector2(boat.position.x,boat.position.z))
	market.set_island(active_market_island)
	market_mode = true
	update_scene_activity()
	message = "Welcome to the island market. Serve your fresh catch to the queue."

func serve_customer() -> void:
	if not market_mode or market.queue_moving or market.handing_over:
		return
	if pending_payment > 0:
		var amount = pending_payment
		coins += amount
		pending_payment = 0
		save_trip()
		market.collect_cash()
		feedback.play_effect("payment")
		market.advance_queue()
		feedback.haptic(45,0.4)
		message = "Received MVR %d. Thank you, Ishaq!" % amount
	elif not inventory.is_empty():
		var item: Dictionary = inventory.pop_front()
		trip_progress.deliver(item,active_market_island)
		pending_payment = int(item.value)
		hold_value = maxi(0,hold_value-pending_payment)
		save_trip()
		market.hand_over()
		message = "%s sold. Collect MVR %d from the counter." % [item.species,pending_payment]
	else:
		message = "Your icebox is empty. Head out for another fishing trip."

func buy_upgrade() -> void:
	if not at_home_dock():
		message = "Boat upgrades are available at the home dock."
	elif upgrade >= 2:
		message = "Your boat engine is fully upgraded."
	elif coins < item_price("engine"):
		message = "Earn MVR %d to upgrade the engine." % item_price("engine")
	else:
		coins -= item_price("engine")
		upgrade += 1
		message = "Engine upgraded! Your boat now travels faster."
		save_trip()

func line_target() -> Vector3:
	if landing_to_boat and fish_actor:
		return fish_actor.to_global(fish_actor.get_meta("mouth_local",Vector3(0,0,-1.2)))
	if fishing and bite_announced and fish_actor:
		return fish_actor.to_global(fish_actor.get_meta("mouth_local",Vector3(0,0,-1.2)))
	return Vector3(boat.position.x, -0.52, boat.position.z) - boat.basis.z * 18.0

func leave_fishing() -> void:
	if landing_to_boat: return
	clear_hooked_fish()
	drive.reset()
	driving_controls.neutral()
	driving_controls.release_pointers()
	speed = 0
	camera.position = boat.position + boat.basis.z * 7 + Vector3(0,4,0)
	camera.look_at(boat.position)
	market_mode = false
	shop_mode = false
	update_scene_activity()
	if interface:
		interface.hide_shop()
	fishing = false
	fishing_view = false
	reeling = false
	message = "Neutral selected. Slide the throttle to get underway."

func plot_home_course() -> void:
	if landing_to_boat:return
	if catch_overlay.visible:close_catch()
	if fishing_view or market_mode or shop_mode:leave_fishing()
	if not set_waypoint(World.Harbour.HOME,"Kelaa inner berth"):
		message="Move clear of the quay, then plot the route to Kelaa harbour."

func return_home() -> void:
	leave_fishing()
	speed = 0
	boat.position = DOCK
	boat.rotation = Vector3.ZERO
	camera.position = DOCK + Vector3(0,7,12)
	camera.look_at(DOCK)
	message = "Back at the dock. Sell your catch or upgrade your boat."

func save_trip() -> void:
	var file = FileAccess.open(save_path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify({"experience_xp":experience.total,"spot_challenges":spot_challenges.snapshot(),"challenge_pose":[boat.position.x,boat.position.z,boat.rotation.y] if boat and not spot_challenges.active.is_empty() else [],"progression":trip_progress.snapshot(),"cosmetic_styles":cosmetics.snapshot(),"graphics_quality": graphics_quality, "graphics_shadows": graphics_shadows, "coins": coins, "catches": catches, "hold_value": hold_value, "upgrade": upgrade, "inventory": inventory, "pending_payment": pending_payment,"owned_items":owned_items,"equipped":equipped,"boat_parts":boat_parts,"owned_boats":owned_boats,"equipped_boat":equipped_boat,"hours":day_cycle.hours if day_cycle else saved_hours,"waypoint":[navigation.destination.x,navigation.destination.y] if navigation.has_destination else []}))

func load_trip() -> void:
	if not FileAccess.file_exists(save_path):
		return
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(save_path))
	if parsed is Dictionary:
		experience.restore(parsed.get("experience_xp",20*maxi(0,int(parsed.get("catches",0)))))
		spot_challenges.restore(parsed.get("spot_challenges",{}))
		saved_challenge_pose=parsed.get("challenge_pose",[]) if parsed.get("challenge_pose",[]) is Array else []
		cosmetics.angler_level=experience.status().level
		trip_progress.restore(parsed.get("progression",{}))
		cosmetics.restore(parsed.get("cosmetic_styles",{}))
		graphics_quality=clampi(int(parsed.get("graphics_quality",graphics_quality)),0,2)
		graphics_shadows=bool(parsed.get("graphics_shadows",graphics_shadows))
		coins = maxi(0, int(parsed.get("coins", 0)))
		catches = maxi(0, int(parsed.get("catches", 0)))
		hold_value = maxi(0, int(parsed.get("hold_value", 0)))
		upgrade = clampi(int(parsed.get("upgrade", 0)), 0, 2)
		pending_payment = maxi(0,int(parsed.get("pending_payment",0)))
		inventory = []
		if parsed.get("inventory") is Array:
			for item in parsed.inventory:
				if item is Dictionary and int(item.get("value",0)) > 0:
					inventory.append({"species":str(item.get("species","Fresh fish")),"value":int(item.value),"weight":float(item.get("weight",1.0))})
		elif hold_value > 0:
			# Preserve older saves: split aggregate value into market portions.
			var remaining = hold_value
			while remaining > 0:
				var portion = mini(remaining,50)
				inventory.append({"species":"Fresh catch","value":portion,"weight":1.0})
				remaining -= portion
		hold_value = 0
		for item in inventory:
			hold_value += int(item.value)
		if not parsed.has("progression"):
			for item in inventory:trip_progress.record_catch(item,"Earlier catch",false)
		owned_items = ["island_reel","island_rod","mono"]
		for id in parsed.get("owned_items",[]):
			if id is String and not Catalog.item(id).is_empty() and id not in owned_items:
				owned_items.append(id)
		boat_parts = []
		for id in parsed.get("boat_parts",[]):
			if id in ["propeller","icebox"] and id not in boat_parts:
				boat_parts.append(id)
		equipped = {"Reels":"island_reel","Rods":"island_rod","Line":"mono"}
		var saved_equipped = parsed.get("equipped",{})
		if saved_equipped is Dictionary:
			for category in equipped:
				var id = str(saved_equipped.get(category,equipped[category]))
				var definition = Catalog.item(id)
				if id in owned_items and definition.get("category")==category:
					equipped[category] = id
		if Catalog.item(str(equipped.Reels)).kind != Catalog.item(str(equipped.Rods)).kind:
			equipped.Reels = "island_reel"
			equipped.Rods = "island_rod"
		owned_boats=["skiff"]
		for id in parsed.get("owned_boats",[]):
			if Catalog.item(str(id)).get("category")=="Boats" and id not in owned_boats:
				owned_boats.append(id)
		equipped_boat=str(parsed.get("equipped_boat","skiff"))
		if equipped_boat not in owned_boats:
			equipped_boat="skiff"
		saved_hours=fposmod(float(parsed.get("hours",8.0)),24.0)
		saved_waypoint=parsed.get("waypoint",[])
		unlocked = catches >= 3
		if day_cycle:
			day_cycle.hours=saved_hours
			day_cycle.apply_lighting()
		if boat:
			apply_boat()
		apply_equipment()
		update_boat_parts()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode==KEY_R and not interface.menu_visible and not interface.map_visible:
		power_reel()
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode==KEY_M and not intro_visible and not catch_overlay.visible and not shop_mode and not market_mode:
		interface.toggle_map()
		get_viewport().set_input_as_handled()
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode==KEY_ESCAPE:
		if interface.map_visible:
			interface.toggle_map()
		elif not intro_visible and not catch_overlay.visible:
			interface.toggle_menu()
			get_viewport().set_input_as_handled()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_IN:
		app_active = true
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		app_active = false
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and feedback:
		feedback.stop_fight_haptics()
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and driving_controls:
		driving_controls.release_pointers()
		driving_controls.neutral()
		drive.set_lever(0)
		reeling = false

func icebox_capacity() -> int:
	return int(World.vessel(equipped_boat).storage)+(14 if "icebox" in boat_parts else 0)

func apply_equipment() -> void:
	if feedback:
		feedback.equip(str(equipped.Reels),str(equipped.Rods),str(equipped.Line))
		apply_gear_styles()

func open_shop(category: String = "Reels") -> void:
	if fishing or catch_overlay.visible or not at_home_dock() or absf(speed)>1 or (drive.engine_running and drive.gear!=0):
		message = "Approach an island harbour berth in neutral to visit its shops."
		return
	leave_fishing()
	shop_mode = true
	update_scene_activity()
	interface.show_shop(category)
	message = "Welcome to the boat workshop." if category=="Boat" else "Welcome to the tackle house. Browse gear for your next trip."

func item_price(id: String) -> int:
	return 100*(upgrade+1) if id=="engine" else int(Catalog.item(id).get("price",0))

func item_owned(id: String) -> bool:
	if Catalog.item(id).get("category")=="Boats":
		return id in owned_boats
	return upgrade>=2 if id=="engine" else (id in boat_parts if id in ["propeller","icebox"] else id in owned_items)

func equip_item(id: String) -> bool:
	if id in owned_boats:
		equipped_boat=id
		apply_boat()
		message="%s is ready at the dock." % World.vessel(id).name
		save_trip()
		return true
	var item = Catalog.item(id)
	if item.is_empty() or id not in owned_items:
		return false
	var selection = equipped.duplicate()
	selection[item.category] = id
	if item.category in ["Reels","Rods"]:
		var other = "Rods" if item.category=="Reels" else "Reels"
		if Catalog.item(str(selection[other])).kind!=item.kind:
			var match_id = ""
			for candidate in Catalog.ITEMS:
				if candidate.category==other and candidate.kind==item.kind and candidate.id in owned_items:
					match_id = candidate.id
					break
			if match_id.is_empty():
				message = "Owned. Add a matching %s to use this %s setup." % [other.to_lower(),item.kind]
				return false
			selection[other] = match_id
	equipped = selection
	apply_equipment()
	message = "%s equipped for your next trip." % item.name
	save_trip()
	return true

func purchase_item(id: String) -> bool:
	if not shop_mode:
		return false
	var item = Catalog.item(id)
	if item.is_empty():
		return false
	if item_owned(id):
		return equip_item(id) if item.category!="Boat" else false
	if catches<int(item.get("unlock",0)):
		message="Unlock this boat by catching %d fish." % int(item.unlock)
		return false
	var price = item_price(id)
	if coins<price:
		message = "You need MVR %d more." % (price-coins)
		return false
	coins -= price
	if item.category=="Boats":
		owned_boats.append(id)
		equip_item(id)
	elif id=="engine":
		upgrade += 1
	elif item.category=="Boat":
		boat_parts.append(id)
	else:
		owned_items.append(id)
		if equip_item(id):
			feedback.play_effect("payment")
			save_trip()
			return true
	message = "%s purchased." % item.name if item.category=="Boat" else message
	update_boat_parts()
	feedback.play_effect("payment")
	save_trip()
	return true

func update_boat_parts() -> void:
	if boat and boat_visual and boat_visual.has_node("Icebox"):
		boat_visual.get_node("Icebox").scale = Vector3(1.2,1.12,1.25) if "icebox" in boat_parts else Vector3.ONE

func apply_boat() -> void:
	if not boat:
		return
	if boat_visual:
		boat.remove_child(boat_visual)
		boat_visual.queue_free()
	boat_visual=preload("res://scripts/boat_models.gd").build(boat,equipped_boat)
	cockpit_displays=preload("res://scripts/cockpit_displays.gd").new()
	boat_visual.add_child(cockpit_displays)
	cockpit_displays.configure(self,equipped_boat)
	# Own-vessel geometry uses a separate view layer so fishing has an unobstructed view.
	for part in boat_visual.find_children("*","GeometryInstance3D",true,false):part.layers=2
	if helm_hands:helm_hands.configure(boat_visual)
	if driving_controls:
		driving_controls.set_skin(equipped_boat)
		driving_controls.configure_models(boat_visual)
	update_boat_parts()
	preload("res://scripts/cosmetic_art.gd").apply(boat_visual,"Boats",cosmetics.style(cosmetics.selected(equipped_boat)))
	boat.position.y=surface.height(Vector2(boat.position.x,boat.position.z))-surface.BASE
	preload("res://scripts/outboard_waterline.gd").update(boat_visual,surface)

func update_outboards(delta: float) -> void:
	for node_name in ["OutboardPivot","OutboardPivot2"]:
		if boat_visual.has_node(node_name):
			var motor=boat_visual.get_node(node_name)
			motor.rotation.y=lerpf(motor.rotation.y,drive.steering*0.52,1-exp(-delta*7))
			motor.get_node("Propeller").rotation.z+=delta*drive.rpm*35*drive.gear*(1 if drive.engine_running else 0)
	var lever=boat_visual.get_node("ThrottleLever") as Node3D
	preload("res://scripts/throttle_pose.gd").apply(lever,driving_controls.lever_value)
	if boat_visual.has_node("ThrottleLever2"):
		preload("res://scripts/throttle_pose.gd").apply(boat_visual.get_node("ThrottleLever2"),driving_controls.lever_value)

func set_waypoint(at: Vector2,title: String) -> bool:
	if navigation.set_destination(Vector2(boat.position.x,boat.position.z),at,title):
		message="Course set: %s. Follow the route on your chart." % title
		save_trip()
		return true
	return false

func clear_hooked_fish() -> void:
	if fish_actor:
		fish_actor.queue_free()
		fish_actor=null

func update_hooked_fish(delta: float) -> void:
	if not fish_actor:
		return
	fish_actor.visible=true
	if fight.landing_lift<=.55:fish_actor.position=fight.position
	var direction=fight.velocity
	if fight.landing_lift>0.55:
		var hanging=Basis.from_euler(Vector3(PI/2,boat.rotation.y,sin(fight.age*5)*0.08)).get_rotation_quaternion()
		fish_actor.basis=Basis(hanging).scaled(Vector3.ONE*.45*World.BOAT_SCALE*float(active_catch.get("size",1)))
	elif direction.length()>0.01:
		var facing=direction.normalized()
		if absf(facing.dot(Vector3.UP))<.95:
			var desired=Basis.looking_at(facing,Vector3.UP).get_rotation_quaternion()
			var rotation_now=fish_actor.basis.orthonormalized().get_rotation_quaternion()
			fish_actor.basis=Basis(rotation_now.slerp(desired,1-exp(-delta*7))).scaled(Vector3.ONE*.45*World.BOAT_SCALE*float(active_catch.get("size",1)))
	fish_actor.swim_intensity=2.5 if fight.running else 1.4
	fish_splash_timer-=delta
	if fight.splash_event or (fight.running and fish_splash_timer<=0):
		feedback.splash(Vector3(fight.position.x,-0.5,fight.position.z))
		fish_splash_timer=1.1

func toggle_driving_camera() -> void:
	if fishing_view or market_mode or shop_mode:
		return
	camera_mode=((1 if first_person_driving else camera_mode)+1)%4
	first_person_driving=camera_mode==1
	driving_controls.release_pointers()
	message="Camera: "+CAMERA_NAMES[camera_mode]

func camera_label() -> String:
	return CAMERA_NAMES[1 if first_person_driving else (0 if camera_mode==1 else camera_mode)]

func apply_graphics() -> void:
	# UI remains native resolution; only the 3D scene is scaled.
	get_viewport().scaling_3d_scale=[0.60,0.80,1.0][graphics_quality]
	Engine.max_fps=30 if graphics_quality==0 else 60
	Engine.physics_ticks_per_second=30 if graphics_quality==0 else 60
	for rocks in get_tree().get_nodes_in_group("harbour_rock_groups"):rocks.apply_quality(graphics_quality)
	if feedback:feedback.apply_quality(graphics_quality)
	if interface:interface.apply_glass_quality(graphics_quality)
	if ocean_mesh:
		ocean_mesh.subdivide_width=[32,64,100][graphics_quality]
		ocean_mesh.subdivide_depth=[32,64,100][graphics_quality]
	if day_cycle:
		day_cycle.shadows_allowed=graphics_shadows
		day_cycle.effects_quality=graphics_quality
		day_cycle.sun.directional_shadow_max_distance=[30.0,60.0,110.0][graphics_quality]
		day_cycle.water.set_shader_parameter("detail_quality",float(graphics_quality))
		day_cycle.apply_lighting()

func update_port_water() -> void:
	var at=Vector2(boat.position.x,boat.position.z)
	var best: Dictionary=World.Harbours.get_port("HA. Kelaa");var distance=INF
	for port in World.Harbours.all_ports():
		if at.distance_squared_to(port.origin)<distance:best=port;distance=at.distance_squared_to(port.origin)
	if water_port==best.name:return
	water_port=best.name
	surface.port=best
	day_cycle.water.set_shader_parameter("harbour_origin",best.origin)
	day_cycle.water.set_shader_parameter("harbour_inward",best.inward)
	day_cycle.water.set_shader_parameter("harbour_size",Vector3(best.depth,best.land,best.half))

func location_name() -> String:
	var at=Vector2(boat.position.x,boat.position.z)
	for island in World.ISLANDS:
		if at.distance_to(island.at)<island.radius+70:return island.name.to_upper()
	return "HAA ALIF WATERS"

func hooked_fish_bottom() -> float:
	if not fish_actor:return -INF
	var bounds: AABB=fish_actor.get_meta("fish_bounds")
	return (fish_actor.global_transform*bounds).position.y

func hanging_clearance() -> float:
	if not fish_actor:return .3
	var bounds: AABB=fish_actor.get_meta("fish_bounds")
	return bounds.size.z*fish_actor.scale.x+.20

func pose_hanging_fish(tip: Vector3) -> void:
	if not fish_actor or fight.landing_lift<=.55 or landing_to_boat:return
	var mouth=tip+Vector3.DOWN*.16
	var local_mouth: Vector3=fish_actor.get_meta("mouth_local")
	fish_actor.position=mouth-fish_actor.basis*local_mouth
	fight.position=fish_actor.position
	fish_actor.swim_intensity=.25

func update_catch_presentation() -> void:
	# Raise the showcase camera above the sea instead of displaying half the fish through water.
	var bounds: AABB=catch_model.get_meta("fish_bounds")
	if not catch_fill:
		catch_fill=OmniLight3D.new();camera.add_child(catch_fill);catch_fill.position=Vector3(-1,1,-1);catch_fill.omni_range=5;catch_fill.light_energy=.8;catch_fill.shadow_enabled=false
	catch_fill.visible=true
	camera.position=boat.position+Vector3.UP*(surface.ceiling()-boat.position.y+bounds.size.z*catch_model.scale.x*.55+.35)
	camera.look_at(camera.position-boat.basis.z*12)
	camera.fov=65
	catch_model.position=Vector3(-.8,sin(catch_show_age*2)*.025,-3)
	catch_model.rotation.z=-PI/2+sin(catch_show_age*2.7)*.025

func apply_gear_styles():
	var painter=preload("res://scripts/cosmetic_art.gd")
	painter.apply(feedback.equipment,"Rods",cosmetics.style(cosmetics.selected(str(equipped.Rods))))
	painter.apply(feedback.equipment.get_meta("reel"),"Reels",cosmetics.style(cosmetics.selected(str(equipped.Reels))))
func equip_style(item: String,style: String) -> bool:
	if not item_owned(item) or not cosmetics.choose(item,style):return false
	if item==equipped_boat:preload("res://scripts/cosmetic_art.gd").apply(boat_visual,"Boats",cosmetics.style(style))
	if feedback:apply_gear_styles()
	save_trip();return true

func harbour_for_rewards() -> String:
	if fishing or catch_overlay.visible or absf(speed)>1 or (drive.engine_running and drive.gear!=0):return ""
	return World.Harbours.berth_at(Vector2(boat.position.x,boat.position.z))
func accept_contract(id: String) -> bool:
	if not trip_progress.accept(id,harbour_for_rewards()):return false
	message="Deliver %s to %s for your contract bonus."%[trip_progress.active.species,trip_progress.active.island]
	save_trip();return true
func claim_contract() -> int:
	var reward=trip_progress.claim(harbour_for_rewards())
	if reward>0:coins+=reward;gain_xp(60);save_trip();message="Contract complete · MVR %d bonus!"%reward
	return reward
func claim_weekly_reward() -> int:
	if harbour_for_rewards().is_empty():return 0
	var reward=trip_progress.claim_weekly()
	if reward>0:coins+=reward;gain_xp(120);save_trip();message="Weekly challenge complete · MVR %d!"%reward
	return reward

func gain_xp(amount: int) -> Dictionary:
	var result=experience.add(amount)
	cosmetics.angler_level=result.level
	result["gifts"]=[]
	for gift in [[5,"Reef bronze"],[10,"Atoll silver"],[15,"Ocean gold"]]:
		if result.before<gift[0] and result.level>=gift[0]:result.gifts.append(gift[1])
	return result
func current_challenge_spot() -> String:
	var nearest=World.nearest(boat.position)
	return str(nearest.id) if Vector2(boat.position.x,boat.position.z).distance_to(nearest.at)<=18 else ""
func can_start_spot_challenge(id: String) -> bool:
	var definition=spot_challenges.definition(id)
	if definition.is_empty() or intro_visible or market_mode or shop_mode or fishing or catch_overlay.visible or absf(speed)>1 or (drive.engine_running and drive.gear!=0):return false
	var nearest=World.nearest(boat.position)
	if nearest.id!=definition.spot or Vector2(boat.position.x,boat.position.z).distance_to(nearest.at)>14:return false
	if catches<int(nearest.unlock) or experience.status().level<int(definition.get("level",1)):return false
	if definition.get("night",false) and day_cycle.hours>=6 and day_cycle.hours<18:return false
	return spot_challenges.active.is_empty() and (spot_challenges.result.is_empty() or not spot_challenges.result.success)
func start_spot_challenge(id: String) -> bool:
	if not can_start_spot_challenge(id):return false
	var ok=spot_challenges.start(id,current_challenge_spot(),experience.status().level,day_cycle.hours,catches)
	if ok:message="Challenge started · "+spot_challenges.definition(id).name;save_trip()
	return ok
func claim_spot_reward() -> Dictionary:
	var prize=spot_challenges.claim()
	if prize.is_empty():return {}
	coins+=int(prize.mvr);var gain=gain_xp(int(prize.xp));prize["level_up"]=gain.level_up;prize["level"]=gain.level;prize["gifts"]=gain.gifts
	message="%d stars · +%d XP · MVR %d"%[prize.stars,prize.xp,prize.mvr];save_trip();return prize
func restore_challenge_position():
	if spot_challenges.active.is_empty():return
	if saved_challenge_pose.size()!=3:spot_challenges.finish(false,"Session position unavailable");return
	var point=Vector2(float(saved_challenge_pose[0]),float(saved_challenge_pose[1]));var yaw=float(saved_challenge_pose[2]);var definition=spot_challenges.definition(spot_challenges.active.id)
	if not point.is_finite() or not is_finite(yaw) or point.distance_to(spot_challenges.spot(definition.spot).at)>18 or not World.water(point,unlocked,.35):spot_challenges.finish(false,"Return to the buoy to retry");return
	boat.position=Vector3(point.x,surface.height(point)-surface.BASE,point.y);boat.rotation=Vector3(0,yaw,0);drive.engine_running=false;drive.reset();driving_controls.neutral()
