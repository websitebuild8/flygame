extends Node3D
## Original procedural equipment and audio, replaceable with authored assets.
var rig: Node3D
var crank: Node3D
var segments: Array[MeshInstance3D] = []
var reel_audio: AudioStreamPlayer
var effects: Dictionary = {}
var splash_rings: Array[MeshInstance3D] = []
var splash_age = 2.0
var splash_position = Vector3.ZERO
var enabled = false
var sound_enabled = true
var vibration_enabled = true
var pulse_time = 0.0
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

func _ready() -> void:
	for key in ["reel", "splash", "bite", "snap", "payment"]:
		var player = AudioStreamPlayer.new()
		player.stream = load("res://assets/audio/%s.wav" % key)
		player.volume_db = -10 if key == "reel" else -4
		add_child(player)
		effects[key] = player
	reel_audio = effects.reel
	var stream = reel_audio.stream as AudioStreamWAV
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = stream.data.size() / 2
	for i in range(3):
		var particles=CPUParticles3D.new()
		particles.emitting=false
		particles.amount=24
		particles.lifetime=0.65
		particles.one_shot=true
		particles.explosiveness=0.95
		particles.direction=Vector3.UP
		particles.spread=42
		particles.gravity=Vector3(0,-7,0)
		particles.initial_velocity_min=1.0
		particles.initial_velocity_max=3.0
		particles.scale_amount_min=0.7
		particles.scale_amount_max=1.8
		var drop=SphereMesh.new()
		drop.radius=0.025
		drop.height=0.05
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
		torus.inner_radius = 0.85
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
	rig.position = Vector3(-0.55,-0.18,-1.25)
	equip("island_reel","island_rod","mono")
	line = MeshInstance3D.new()
	line.mesh = line_mesh
	var mat = StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color("d5e4d5")
	line.material_override = mat
	get_parent().add_child(line)
	rig.visible = false

func haptic(duration: int, amplitude: float) -> void:
	if vibration_enabled and OS.get_name() in ["Android", "iOS"]:
		Input.vibrate_handheld(duration, amplitude)

func play_effect(key: String) -> void:
	if sound_enabled:
		effects[key].play()

func splash(at: Vector3) -> void:
	splash_position = Vector3(at.x,-0.5,at.z)
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
	splash(at)
	haptic(35, 0.3)

func bite_feedback() -> void:
	play_effect("bite")
	haptic(160, 0.8)

func finish(success: bool, at: Vector3) -> void:
	reel_audio.stop()
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
	pulse_time -= delta
	if active:
		var landing=get_parent().fight.landing_lift if get_parent().fishing else 0.0
		var raise_rod=sin(minf(cast_age, 0.7) / 0.7 * PI)*0.7+landing*0.16
		rig.rotation.x=lerpf(rig.rotation.x,raise_rod,1-exp(-delta*5))
		var local=rig.get_parent().to_local(target)
		var aim=clampf(atan2(-local.x,-local.z),-0.4,0.4)
		rig.rotation.y=lerpf(rig.rotation.y,aim,1-exp(-delta*4))
		var desired=0.12+tension*0.78+landing*0.55 if get_parent().bite_announced else 0.0
		var dt=minf(delta,0.04)
		bend_velocity+=((desired-bend_amount)*65-bend_velocity*14)*dt
		bend_amount=clampf(bend_amount+bend_velocity*dt,0,1)
		var pump=sin(cast_age*3.4)*(0.018+0.055*tension)*(1-landing*0.7)
		rig.position=Vector3(-0.55,-0.18+pump,-1.25+pump*0.3)
		rig.rotation.x+=pump*0.65
		rig.rotation.z=sin(Time.get_ticks_msec()*0.004)*0.015*bend_amount
		if overhead and pulling:
			rig.rotation.x += sin(Time.get_ticks_msec()*0.009)*0.05
		for i in range(segments.size()):
			var bend = float(i)/8.0
			var start = Vector3(0,0.1+float(i)*0.13-bend*bend*bend_amount*0.85,-float(i)*0.22)
			var next_bend = float(i+1)/8.0
			var end = Vector3(0,0.1+float(i+1)*0.13-next_bend*next_bend*bend_amount*0.85,-float(i+1)*0.22)
			segments[i].position = (start+end)*0.5
			segments[i].quaternion = Quaternion(Vector3.UP,(end-start).normalized())
			segments[i].scale.y=start.distance_to(end)/0.2555
		if pulling:
			crank.rotate_object_local(crank.get_meta("spin_axis",Vector3.RIGHT),delta*13)
			if overhead:
				rotor.rotation.x += delta*20
			else:
				rotor.rotate_object_local(rotor.get_meta("spin_axis",Vector3.BACK),delta*20)
		if pulling and sound_enabled:
			reel_audio.pitch_scale=lerpf(1.12,0.78,tension)
			reel_audio.volume_db=lerpf(-14,-9,tension)
			if not reel_audio.playing:
				reel_audio.play()
		else:
			reel_audio.stop()
		if pulling and tension > 0.75 and pulse_time <= 0:
			haptic(45, 0.5)
			pulse_time = 0.35
		line_mesh.clear_surfaces()
		line_mesh.surface_begin(Mesh.PRIMITIVE_LINES)
		line_mesh.surface_add_vertex(segments[-1].global_position)
		line_mesh.surface_add_vertex(target)
		line_mesh.surface_end()
	else:
		reel_audio.stop()
	splash_age += delta
	for i in range(splash_rings.size()):
		var age = splash_age - float(i) * 0.12
		var ring = splash_rings[i]
		ring.visible = age >= 0 and age < 1.2
		if ring.visible:
			ring.position = splash_position + Vector3(0, float(i) * 0.015, 0)
			ring.scale = Vector3.ONE * (0.2 + age * 2.5)
			(ring.material_override as StandardMaterial3D).albedo_color.a = (1.0 - age / 1.2) * 0.65

func _exit_tree() -> void:
	for player in effects.values():
		player.stop()

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
	if line:
		(line.material_override as StandardMaterial3D).albedo_color = Color("82d0a9") if line_id=="powerpro" else Color("d5e4d5")
