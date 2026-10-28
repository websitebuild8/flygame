extends Node3D
## Original procedural equipment and audio, replaceable with authored assets.
const PLAYER_SCALE=preload("res://scripts/world_data.gd").BOAT_SCALE
var rig: Node3D
var crank: Node3D
var segments: Array[MeshInstance3D] = []
var ambience: AudioStreamPlayer
var reel_variants: Array[AudioStream] = []
var splash_variants: Array[AudioStream] = []
var splash_players: Array[AudioStreamPlayer] = []
var splash_sound_cursor=0
var reel_audio: AudioStreamPlayer
var effects: Dictionary = {}
var splash_rings: Array[MeshInstance3D] = []
var splash_age = 2.0
var splash_position = Vector3.ZERO
var enabled = false
var sound_enabled = true
var vibration_enabled = true:
	set(value):
		vibration_enabled=value
		if not value:stop_fight_haptics()
signal haptic_requested(duration: int,amplitude: float)
var fight_pulse_active=false
var fight_pulse_timer=0.0
var fight_pulse_second=false
var cast_age = 2.0
var line: MeshInstance3D
var line_mesh = ImmediateMesh.new()
var equipment: Node3D
var rotor: Node3D
var overhead = false
var bend_amount=0.0
var bend_velocity=0.0
var spray: Array[CPUParticles3D]=[]
var spray_cursor=0
var hands: Node3D
var routed_line_points=PackedVector3Array()
var strike_kick=0.0
var hook_rating=""
var hook_rating_time=0.0
var winding_speed=0.0
var spool: Node3D
var spool_rest=Vector3.ZERO
var cast_motion=preload("res://scripts/lure_cast.gd").new()
var lure: Node3D
var effects_quality=2

func hook_feedback(quality: float) -> void:
	strike_kick=1
	hook_rating="PERFECT HOOK" if quality>.8 else ("GOOD HOOK" if quality>.45 else "HOOKED")
	hook_rating_time=1.2
	haptic(70,.65)

func _ready() -> void:
	for key in ["reel", "splash", "bite", "snap", "payment"]:
		var player = AudioStreamPlayer.new()
		player.stream = load("res://assets/audio/%s.wav" % key)
		player.volume_db = -10 if key == "reel" else -4
		add_child(player)
		effects[key] = player
	reel_audio = effects.reel
	for suffix in ["01","04","07"]:
		var stream=load("res://assets/audio/supplied/audio_fishing_drawing%s.ogg" % suffix) as AudioStreamOggVorbis
		stream.loop=true
		reel_variants.append(stream)
	reel_audio.stream=reel_variants[0]
	effects.bite.stream=reel_variants[1].duplicate()
	effects.bite.stream.loop=false
	effects.bite.volume_db=-12
	for suffix in ["01","02","03","05"]:
		splash_variants.append(load("res://assets/audio/supplied/audio_fishing_drawing_hpevent_%s.ogg" % suffix))
	splash_players.append(effects.splash)
	for index in range(2):
		var splash_player=AudioStreamPlayer.new()
		add_child(splash_player);splash_players.append(splash_player)
	ambience=AudioStreamPlayer.new()
	var background=load("res://assets/audio/supplied/background.ogg") as AudioStreamOggVorbis
	background.loop=true
	ambience.stream=background;ambience.volume_db=-19
	add_child(ambience)
	for i in range(3):
		var particles=CPUParticles3D.new()
		particles.emitting=false
		particles.amount=24
		particles.lifetime=0.65
		particles.one_shot=true
		particles.explosiveness=0.95
		particles.direction=Vector3.UP
		particles.spread=42
		particles.gravity=Vector3(0,-7,0)*PLAYER_SCALE
		particles.initial_velocity_min=1.0*PLAYER_SCALE
		particles.initial_velocity_max=3.0*PLAYER_SCALE
		particles.scale_amount_min=0.7
		particles.scale_amount_max=1.8
		var drop=SphereMesh.new()
		drop.radius=0.025*PLAYER_SCALE
		drop.height=0.05*PLAYER_SCALE
		drop.radial_segments=6
		drop.rings=3
		particles.mesh=drop
		var droplet=StandardMaterial3D.new()
		droplet.albedo_color=Color("c3e5e4")
		droplet.roughness=0.2
		particles.material_override=droplet
		add_child(particles)
		spray.append(particles)
	for i in range(3):
		var ring = MeshInstance3D.new()
		var torus = TorusMesh.new()
		torus.inner_radius = 0.97
		torus.outer_radius = 1.0
		torus.rings = 20
		torus.ring_segments = 8
		ring.mesh = torus
		var mat = StandardMaterial3D.new()
		mat.albedo_color = Color(0.8, 0.98, 1, 0.7)
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		ring.material_override = mat
		ring.visible = false
		add_child(ring)
		splash_rings.append(ring)

func part(parent: Node3D, pos: Vector3, size: Vector3, color: Color) -> MeshInstance3D:
	return get_parent().box(parent, pos, size, color)

func attach_camera(camera: Camera3D) -> void:
	rig = Node3D.new()
	camera.add_child(rig)
	rig.scale=Vector3.ONE*PLAYER_SCALE
	rig.position = Vector3(-0.55,-0.18,-1.25)
	equip("island_reel","island_rod","mono")
	hands=preload("res://scripts/fishing_hands.gd").new()
	rig.add_child(hands)
	hands.body_scale=PLAYER_SCALE
	line = MeshInstance3D.new()
	line.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	line.mesh = line_mesh
	var mat = StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color("d5e4d5")
	line.material_override = mat
	get_parent().add_child(line)
	rig.visible = false
	lure=preload("res://scripts/fishing_lure.gd").new();add_child(lure);lure.scale=Vector3.ONE*PLAYER_SCALE;lure.visible=false

func haptic(duration: int, amplitude: float) -> void:
	if not vibration_enabled:return
	haptic_requested.emit(duration,amplitude)
	if OS.get_name() in ["Android", "iOS"]:
		Input.vibrate_handheld(duration, amplitude)

func play_effect(key: String) -> void:
	if sound_enabled:
		if key=="splash":
			var splash_player=splash_players[splash_sound_cursor]
			splash_sound_cursor=(splash_sound_cursor+1)%splash_players.size()
			splash_player.stream=splash_variants.pick_random()
			splash_player.pitch_scale=randf_range(.94,1.06)
			splash_player.volume_db=-9
			splash_player.play()
		else:
			effects[key].play()

func splash(at: Vector3) -> void:
	splash_position = Vector3(at.x,get_parent().surface.height(Vector2(at.x,at.z))+.006,at.z)
	splash_age = 0
	if not spray.is_empty():
		var particles=spray[spray_cursor]
		particles.position=splash_position
		particles.restart()
		particles.emitting=true
		spray_cursor=(spray_cursor+1)%spray.size()
	play_effect("splash")

func cast_feedback(at: Vector3) -> void:
	cast_age = 0
	cast_motion.begin(at,overhead)
	haptic(35, 0.3)

func bite_feedback() -> void:
	play_effect("bite")
	haptic(160, 0.8)

func finish(success: bool, at: Vector3) -> void:
	stop_fight_haptics()
	reel_audio.stop()
	line.visible=false
	line_mesh.clear_surfaces()
	if success:
		splash(at)
		haptic(100, 0.7)
	else:
		play_effect("snap")
		haptic(220, 1)

func update_feedback(delta: float, active: bool, pulling: bool, tension: float, target: Vector3) -> void:
	enabled = active
	rig.visible = active
	line.visible = active
	cast_age += delta
	if not get_parent().fishing and cast_motion.state!="ready":cast_motion.reset()
	lure.visible=active and (not get_parent().fishing or not get_parent().bite_announced)
	strike_kick=maxf(0,strike_kick-delta*2.8)
	hook_rating_time=maxf(0,hook_rating_time-delta)
	if active:
		var landing=get_parent().fight.landing_lift if get_parent().fishing else 0.0
		var raise_rod=cast_motion.rod_pitch()+landing*.30+strike_kick*.72
		rig.rotation.x=lerpf(rig.rotation.x,raise_rod,1-exp(-delta*(22 if cast_motion.is_casting() or strike_kick>.2 else 7)))
		var local=rig.get_parent().to_local(target)
		var aim=clampf(atan2(-local.x,-local.z),-0.5,0.5) if get_parent().fishing and get_parent().bite_announced else 0.0
		rig.rotation.y=lerpf(rig.rotation.y,aim,1-exp(-delta*4))
		var desired=0.12+tension*0.78+landing*0.55 if get_parent().bite_announced else cast_motion.bend_load()
		var dt=minf(delta,0.04)
		bend_velocity+=((desired-bend_amount)*65-bend_velocity*14)*dt
		bend_amount=clampf(bend_amount+bend_velocity*dt,0,1)
		var pump=sin(cast_age*3.4)*(.018+.065*tension)*(1-landing*.7)
		var power=get_parent().fight.power_time>0 and get_parent().fishing
		rig.position=Vector3(-.32+sin(cast_age*2.2)*tension*.012,-.30+pump+strike_kick*.06,-.68+pump*.3)*PLAYER_SCALE
		rig.rotation.x+=pump*0.65
		rig.rotation.z=sin(Time.get_ticks_msec()*0.004)*0.015*bend_amount
		if overhead and pulling:
			rig.rotation.x += sin(Time.get_ticks_msec()*0.009)*0.05
		if landing>.55 and not get_parent().landing_to_boat:
			var curve_tip=equipment.to_global(preload("res://scripts/rod_curve.gd").tip(bend_amount))
			var minimum=get_parent().surface.ceiling()+get_parent().hanging_clearance()+.04
			# Lift the entire rod/handle so both the short leader and the tail clear the sea.
			rig.position.y+=maxf(0,minimum-curve_tip.y)
		for i in range(segments.size()):
			var bend = float(i)/8.0
			var start = Vector3(0,0.1+float(i)*0.13-bend*bend*bend_amount*0.85,-float(i)*0.22)
			var next_bend = float(i+1)/8.0
			var end = Vector3(0,0.1+float(i+1)*0.13-next_bend*next_bend*bend_amount*0.85,-float(i+1)*0.22)
			segments[i].position = (start+end)*0.5
			segments[i].quaternion = Quaternion(Vector3.UP,(end-start).normalized())
			segments[i].scale.y=start.distance_to(end)/0.2555
		var authored=equipment.get_meta("authored_blank",null) as MeshInstance3D
		if authored:
			for surface in range(authored.mesh.get_surface_count()):
				(authored.get_surface_override_material(surface) as ShaderMaterial).set_shader_parameter("bend",bend_amount)
		winding_speed=lerpf(winding_speed,(19.0 if power else 10.0) if pulling else 0.0,1-exp(-delta*15))
		if winding_speed>.02:
			crank.rotate_object_local(crank.get_meta("spin_axis",Vector3.RIGHT),delta*winding_speed*(1.0 if overhead else -1.0))
			if overhead:
				rotor.rotation.x += delta*winding_speed*1.8
			else:
				rotor.rotate_object_local(rotor.get_meta("spin_axis",Vector3.BACK),-delta*winding_speed*2.3)
		var active_reel=equipment.get_meta("reel") as Node3D
		if overhead and active_reel.has_meta("level_wind"):
			var level_wind=active_reel.get_meta("level_wind") as Node3D
			level_wind.position=level_wind.get_meta("rest_position")+Vector3.RIGHT*sin(cast_age*3)*.09*minf(winding_speed,1)
		if spool and not overhead:
			var spindle=(rotor.global_basis*rotor.get_meta("spin_axis",Vector3.BACK)).normalized()
			var travel=spool.get_parent().global_basis.inverse()*spindle*.006
			spool.position=spool_rest+travel*sin(cast_age*5)*minf(winding_speed,1)
		if hands:
			hands.pose(rig.to_local(crank.to_global(crank.get_meta("grip_point",Vector3.ZERO))),pulling,overhead)
		if pulling and sound_enabled:
			reel_audio.pitch_scale=lerpf(1.12,0.78,tension)
			reel_audio.volume_db=lerpf(-14,-9,tension)
			if not reel_audio.playing:
				reel_audio.stream=reel_variants.pick_random()
				reel_audio.play()
		else:
			reel_audio.stop()
		line_mesh.clear_surfaces()
		line_mesh.surface_begin(Mesh.PRIMITIVE_LINES)
		routed_line_points.clear()
		var reel=equipment.get_meta("reel") as Node3D
		var lip=reel.get_meta("spool_lip") as Node3D if reel.has_meta("spool_lip") else null
		var roller=reel.get_meta("line_roller") as Node3D if reel.has_meta("line_roller") else null
		var start=lip.global_position if lip else spool.global_position
		routed_line_points.append(start)
		if roller and (get_parent().bite_announced or cast_motion.state not in ["windup","flight"]):routed_line_points.append(roller.global_position)
		var curve=preload("res://scripts/rod_curve.gd")
		for guide in curve.guides(overhead):routed_line_points.append(equipment.to_global(curve.point(guide,bend_amount)))
		for span in range(routed_line_points.size()-1):
			line_mesh.surface_add_vertex(routed_line_points[span])
			line_mesh.surface_add_vertex(routed_line_points[span+1])
		var tip=routed_line_points[-1]
		if get_parent().fishing and get_parent().bite_announced:get_parent().pose_hanging_fish(tip)
		cast_motion.step(delta,tip,cast_age)
		if cast_motion.splash_event:splash(cast_motion.destination)
		var endpoint=get_parent().line_target() if get_parent().fishing and get_parent().bite_announced else cast_motion.position
		lure.global_position=endpoint
		if cast_motion.state=="flight" and cast_motion.velocity.length_squared()>.01:
			lure.basis=Basis(Quaternion(Vector3.UP,cast_motion.velocity.normalized())).scaled(Vector3.ONE*PLAYER_SCALE)
		else:
			lure.basis=Basis.from_euler(Vector3(.1*sin(cast_age*2.1),cast_age*.35,.08*sin(cast_age*1.7))).scaled(Vector3.ONE*PLAYER_SCALE)
		var previous=tip
		for i in range(1,13):
			var t=float(i)/12
			var point=tip.lerp(endpoint,t)+Vector3.DOWN*sin(t*PI)*(0.0 if landing>.55 else (.025 if pulling or cast_motion.state=="ready" else (.32 if cast_motion.state=="flight" else .12)))
			line_mesh.surface_add_vertex(previous)
			line_mesh.surface_add_vertex(point)
			routed_line_points.append(point)
			previous=point
		line_mesh.surface_end()
	else:
		reel_audio.stop()
	splash_age += delta
	for i in range(splash_rings.size()):
		var age = splash_age - float(i) * 0.12
		var ring = splash_rings[i]
		ring.visible = age >= 0 and age < 1.2
		if ring.visible:
			ring.position = splash_position + Vector3(0, .006+float(i) * 0.001, 0)
			ring.scale = Vector3(1,.12,1) * (0.2 + age * 2.5)*PLAYER_SCALE
			(ring.material_override as StandardMaterial3D).albedo_color.a = (1.0 - age / 1.2) * 0.65

func _exit_tree() -> void:
	for player in effects.values()+splash_players+[ambience]:
		if is_instance_valid(player):
			player.stop()
			player.stream=null

func equip(reel_id: String, rod_id: String, line_id: String) -> void:
	if not rig:
		return
	if equipment:
		equipment.queue_free()
	var catalog = preload("res://scripts/gear_catalog.gd")
	var definition = catalog.item(reel_id)
	overhead = definition.kind=="overhead"
	equipment = preload("res://scripts/tackle_art.gd").rod(rig,definition.kind,reel_id,rod_id,line_id=="powerpro")
	segments.assign(equipment.get_meta("segments"))
	var reel = equipment.get_meta("reel") as Node3D
	crank = reel.get_meta("crank")
	rotor = reel.get_meta("rotor")
	spool=reel.get_meta("spool")
	spool_rest=spool.position
	if line:
		(line.material_override as StandardMaterial3D).albedo_color = Color("82d0a9") if line_id=="powerpro" else Color("d5e4d5")

func update_ambience(outdoors: bool) -> void:
	if outdoors and sound_enabled:
		if not ambience.playing:ambience.play()
	else:
		ambience.stop()

func apply_quality(quality: int) -> void:
	effects_quality=quality
	for particles in spray:
		particles.amount=[10,16,24][quality]

func stop_fight_haptics() -> void:
	if fight_pulse_active and OS.get_name() in ["Android","iOS"]:Input.vibrate_handheld(0)
	fight_pulse_active=false;fight_pulse_timer=0;fight_pulse_second=false

func update_fight_haptics(delta: float,on_hook: bool,load: float,running: bool,landing: bool) -> void:
	if not on_hook or not vibration_enabled:
		stop_fight_haptics();return
	fight_pulse_active=true
	fight_pulse_timer-=delta
	if fight_pulse_timer>0:return
	var strength=clampf(.30+load*.32+(.14 if running else 0),.3,.8)
	if landing:strength*=.75
	if fight_pulse_second:
		haptic(30,strength*.65)
		fight_pulse_timer=.60 if landing else (.28 if running else .48)
	else:
		haptic(65,strength)
		fight_pulse_timer=.13
	fight_pulse_second=not fight_pulse_second
