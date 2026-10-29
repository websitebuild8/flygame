extends RefCounted
var world_scale=1.0
var origin = Vector3.ZERO
var forward = Vector3.FORWARD
var side = Vector3.RIGHT
var position = Vector3.ZERO
var velocity = Vector3.ZERO
var progress = 0.0
var tension = 0.0
var age = 0.0
var difficulty = 1.0
var running = false
var jumping = false
var splash_event = false
var above_water = false
var landing_lift = 0.0
var landing_age = 0.0
var hooked=true
var hook_quality=0.0
var power_charge=0.0
var power_time=0.0
var slack_time=0.0
var escaped=false
var run_distance=0.0
var individual_phase=0.0
var pull_strength=0.0
const BEHAVIOURS={
 "Yellowfin tuna":{"run_rate":.72,"threshold":.45,"distance":5.5,"sweep":.72,"dart":1.0,"jump_cycle":9.0,"jump_height":.18,"tip":"Long, steady runs · ease off during surges"},
 "Giant trevally":{"run_rate":1.35,"threshold":.64,"distance":4.0,"sweep":1.15,"dart":1.2,"jump_cycle":8.0,"jump_height":0.0,"tip":"Short powerful pulls · watch the tension"},
 "Skipjack tuna":{"run_rate":1.6,"threshold":.70,"distance":3.0,"sweep":1.0,"dart":1.65,"jump_cycle":7.5,"jump_height":1.15,"tip":"Quick darts · keep a steady retrieve"},
 "Sailfish":{"run_rate":.85,"threshold":.48,"distance":6.0,"sweep":1.25,"dart":.9,"jump_cycle":6.2,"jump_height":2.5,"tip":"Wide runs and jumps · keep pressure between leaps"},
 "Mahi-mahi":{"run_rate":1.25,"threshold":.65,"distance":4.0,"sweep":1.15,"dart":1.4,"jump_cycle":5.3,"jump_height":2.1,"tip":"Fast turns and frequent jumps · avoid slack"},
 "Rusty jobfish":{"run_rate":1.05,"threshold":.57,"distance":2.8,"sweep":.62,"dart":.85,"jump_cycle":10.5,"jump_height":0.0,"tip":"Deep, steady pulls · lift gently and keep pressure"},
 "Giant grouper":{"run_rate":.58,"threshold":.35,"distance":3.3,"sweep":.42,"dart":.63,"jump_cycle":11.0,"jump_height":0.0,"tip":"Heavy pulls · ease pressure during long surges"}
}
var behaviour: Dictionary={}
func set_species(species: String):behaviour=BEHAVIOURS.get(species,{}).duplicate()


func strike(quality: float) -> void:
	if hooked:return
	hooked=true
	hook_quality=clampf(quality,0,1)
	progress+=hook_quality*.055
	tension=.18

func request_power() -> bool:
	if not hooked or power_charge<1 or power_time>0 or landing_lift>.1:return false
	power_charge=0
	power_time=1.35
	tension=maxf(.12,tension-.22)
	return true

func start(at: Vector3, direction: Vector3, strength: float, scene_scale: float=1.0) -> void:
	world_scale=scene_scale
	origin=at
	forward=Vector3(direction.x,0,direction.z).normalized()
	side=Vector3(-forward.z,0,forward.x)
	difficulty=strength
	position=origin+forward*18
	position.y=-1.0

func step(delta: float, reeling: bool, retrieve: float, drag: float, rod: float, line_strength: float) -> void:
	if not hooked or escaped:return
	age+=delta
	power_time=maxf(0,power_time-delta)
	running = sin(age*float(behaviour.get("run_rate",1.0)))>float(behaviour.get("threshold",.65))
	var run = 1.0 if running else 0.0
	tension=clampf(tension+delta*((0.26+run*0.22)*difficulty/(drag*line_strength) if reeling else -0.48),0,1)
	var previous_progress=progress
	var boost=2.4 if power_time>0 else 1.0
	pull_strength=130*retrieve*rod*(1-run*.35)*boost if reeling else 0.0
	progress=clampf(progress+delta*(0.13*retrieve*rod*(1-run*0.35)*boost if reeling else -(0.012+run*0.015)),0,1)
	if reeling and tension>.2 and tension<.78:
		power_charge=minf(1,power_charge+delta*.32)
	slack_time=slack_time+delta if not reeling and tension<.08 and landing_lift<.1 else 0.0
	escaped=slack_time>6
	if landing_lift>=0.65: progress=maxf(progress,previous_progress)
	landing_lift=smoothstep(0.78,0.98,progress)
	if progress>=1.0: landing_age+=delta
	run_distance=lerpf(run_distance,run*float(behaviour.get("distance",4.0))*(1-progress),1-exp(-delta*2))
	var distance=lerpf(18.0,4.5*world_scale,progress)+run_distance
	var sweep=(sin(age*1.25*float(behaviour.get("dart",1.0))+individual_phase)*4.8+sin(age*2.1+individual_phase)*1.2)*float(behaviour.get("sweep",1.0))
	var target=origin+forward*distance+side*sweep*(1.0-progress)
	var jump_phase=fposmod(age,float(behaviour.get("jump_cycle",7.0)))
	jumping=jump_phase>2.3 and jump_phase<3.6 and float(behaviour.get("jump_height",1.65))>0
	var lift=sin((jump_phase-2.3)/1.3*PI)*float(behaviour.get("jump_height",1.65)) if jumping else 0.0
	target.y=lerpf(-.52+(-.53+lift)*world_scale,-.52+1.57*world_scale,landing_lift)
	if landing_lift>0.1:
		target+=side*sin(age*3)*0.15*world_scale*landing_lift
		running=false
		jumping=false
		tension=minf(tension,0.70)
	var next_above=target.y> -0.55
	splash_event=next_above!=above_water
	above_water=next_above
	velocity=(target-position)/maxf(delta,0.001)
	position=target
