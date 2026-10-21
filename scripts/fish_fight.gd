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

func start(at: Vector3, direction: Vector3, strength: float) -> void:
	origin=at
	forward=Vector3(direction.x,0,direction.z).normalized()
	side=Vector3(-forward.z,0,forward.x)
	difficulty=strength
	position=origin+forward*18
	position.y=-1.0

func step(delta: float, reeling: bool, retrieve: float, drag: float, rod: float, line_strength: float) -> void:
	age+=delta
	running = sin(age*1.0)>0.65
	var run = 1.0 if running else 0.0
	tension=clampf(tension+delta*((0.26+run*0.22)*difficulty/(drag*line_strength) if reeling else -0.48),0,1)
	var previous_progress=progress
	progress=clampf(progress+delta*(0.13*retrieve*rod*(1-run*0.35) if reeling else -(0.012+run*0.015)),0,1)
	if landing_lift>=0.65: progress=maxf(progress,previous_progress)
	landing_lift=smoothstep(0.78,0.98,progress)
	if progress>=1.0: landing_age+=delta
	var distance=lerpf(18.0,4.5,progress)
	var target=origin+forward*distance+side*sin(age*1.25)*(1.0-progress)*3.8
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
