extends Node
var beacon_clock=0.0
var lighting_tick=0.0
var shadows_allowed = true
var effects_quality = 2
var hours = 8.0
const DAY_SECONDS = 1200.0
var sun: DirectionalLight3D
var environment: Environment
var sky: ProceduralSkyMaterial
var water: ShaderMaterial
var harbor_lights: Array[OmniLight3D] = []
var day_amount = 1.0
var stars: Node3D
var moon: Node3D
var clouds: ShaderMaterial
var weather=0
var weather_age=0.0
var cover=0.0
var roughness=0.0
var rain_amount=0.0
var rain: CPUParticles3D
const WEATHER_NAMES=["Sunny","Cloudy","Rain showers","Rough sea"]
const CONDITIONS=[Vector3(0,0,0),Vector3(0.75,0.2,0),Vector3(0.95,0.5,1),Vector3(0.85,1,0.65)]

func advance(delta: float) -> void:
	beacon_clock+=delta
	weather_age+=delta
	if weather_age>=150: next_weather()
	var target: Vector3=CONDITIONS[weather]
	var blend=1-exp(-delta*0.35)
	cover=lerpf(cover,target.x,blend)
	roughness=lerpf(roughness,target.y,blend)
	rain_amount=lerpf(rain_amount,target.z,blend)
	hours = fposmod(hours+delta*24.0/DAY_SECONDS,24.0)
	lighting_tick+=delta
	if lighting_tick>=[.20,.10,.05][effects_quality]:
		lighting_tick=0
		apply_lighting()

func apply_lighting() -> void:
	var height = sin((float(hours)-6.0)/24.0*TAU)
	day_amount = smoothstep(-0.14,0.3,height)
	var sunset = (1-smoothstep(0.0,0.4,absf(height)))*day_amount
	sun.rotation_degrees = Vector3(-height*75,-45+(hours-12)*9,0)
	sun.light_energy = lerpf(0.08,0.78,day_amount)
	sun.shadow_enabled=shadows_allowed and day_amount>0.2
	sun.light_color = Color("a5bde8").lerp(Color("fff4dc"),day_amount).lerp(Color("ffb177"),sunset*0.6)
	if height<0:
		sun.rotation_degrees.x = -35
	environment.ambient_light_color = Color("7293bb").lerp(Color("e2ebdf"),day_amount)
	environment.ambient_light_energy = lerpf(0.22,0.30,day_amount)
	sky.sky_top_color = Color("07142e").lerp(Color("388fc3"),day_amount)
	sky.sky_horizon_color = Color("253a60").lerp(Color("c3e4e0"),day_amount).lerp(Color("f2b58b"),sunset*0.7)
	sky.ground_horizon_color=sky.sky_horizon_color
	sky.ground_bottom_color=Color("092237").lerp(Color("35868f"),day_amount)
	environment.fog_light_color=sky.sky_horizon_color
	sun.light_energy*=1-cover*0.65
	sky.sky_top_color=sky.sky_top_color.lerp(Color("485d70")*lerpf(0.2,1,day_amount),cover*0.8)
	sky.sky_horizon_color=sky.sky_horizon_color.lerp(Color("87969e")*lerpf(0.25,1,day_amount),cover*0.75)
	sky.ground_horizon_color=sky.sky_horizon_color
	environment.fog_density=0.0011+cover*0.0025+rain_amount*0.002
	environment.fog_light_color=sky.sky_horizon_color
	if stars: stars.visible=day_amount<0.2 and cover<0.6
	if moon: moon.visible=day_amount<0.3 and cover<0.8
	if clouds:
		clouds.set_shader_parameter("cover",cover)
		clouds.set_shader_parameter("daylight",day_amount)
		clouds.set_shader_parameter("sunset",sunset)
	water.set_shader_parameter("daylight",day_amount)
	water.set_shader_parameter("rough_sea",roughness)
	water.set_shader_parameter("rain",rain_amount)
	for beacon in get_tree().get_nodes_in_group("harbour_beacons"):beacon.update_light(1-day_amount,beacon_clock)
	for light in harbor_lights:
		light.light_energy = (1-day_amount)*1.8

func clock_text() -> String:
	var total = int(hours*60)%1440
	return "%02d:%02d" % [total/60,total%60]

func next_phase() -> void:
	hours = 12.0 if hours>=6 and hours<10 else (18.5 if hours>=10 and hours<17 else (22.0 if hours>=17 and hours<21 else 6.5))
	apply_lighting()

func weather_name() -> String:
	return WEATHER_NAMES[weather]

func next_weather() -> void:
	weather=(weather+1)%WEATHER_NAMES.size()
	weather_age=0

func update_rain(at: Vector3, outdoors: bool) -> void:
	if not rain:
		rain=CPUParticles3D.new()
		add_child(rain)
		rain.emitting=false
		rain.amount=420
		rain.lifetime=0.8
		rain.emission_shape=CPUParticles3D.EMISSION_SHAPE_BOX
		rain.emission_box_extents=Vector3(12,0.2,12)
		rain.direction=Vector3(-0.12,-1,0)
		rain.spread=4
		rain.initial_velocity_min=15
		rain.initial_velocity_max=21
		rain.gravity=Vector3(0,-5,0)
		rain.local_coords=false
		var drop=BoxMesh.new()
		drop.size=Vector3(0.012,0.22,0.012)
		rain.mesh=drop
		var material=StandardMaterial3D.new()
		material.albedo_color=Color(0.72,0.84,0.89,0.5)
		material.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
		material.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
		rain.material_override=material
	rain.global_position=at+Vector3(0,8,0)
	rain.emitting=outdoors and rain_amount>0.1
	var density=int((50+int(rain_amount*7)*50)*[0.25,0.55,1.0][effects_quality])
	if rain.amount!=density: rain.amount=density
