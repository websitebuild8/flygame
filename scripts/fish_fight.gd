extends RefCounted
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

func start(at: Vector3, direction: Vector3, strength: float) -> void:
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
	running = sin(age*1.0)>0.65
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
	run_distance=lerpf(run_distance,run*4.0*(1-progress),1-exp(-delta*2))
	var distance=lerpf(18.0,4.5,progress)+run_distance
	var sweep=sin(age*1.25+individual_phase)*4.8+sin(age*2.1+individual_phase)*1.2
	var target=origin+forward*distance+side*sweep*(1.0-progress)
	var jump_phase=fposmod(age,7.0)
	jumping=jump_phase>2.3 and jump_phase<3.6
	var lift=sin((jump_phase-2.3)/1.3*PI)*1.65 if jumping else 0.0
	target.y=lerpf(-1.05+lift,1.05,landing_lift)
	if landing_lift>0.1:
		target+=side*sin(age*3)*0.15*landing_lift
		running=false
		jumping=false
		tension=minf(tension,0.70)
	var next_above=target.y> -0.55
	splash_event=next_above!=above_water
	above_water=next_above
	velocity=(target-position)/maxf(delta,0.001)
	position=target
