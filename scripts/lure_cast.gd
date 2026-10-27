extends RefCounted
## A short tether before release, then a gravity-driven flight to the water.
const LEADER_LENGTH=.92*preload("res://scripts/world_data.gd").BOAT_SCALE
const RELEASE_TIME=.52
const FLIGHT_TIME=1.30
const GRAVITY=Vector3(0,-9.81,0)
var state="ready"
var age=0.0
var position=Vector3.ZERO
var velocity=Vector3.ZERO
var destination=Vector3.ZERO
var release_position=Vector3.ZERO
var release_velocity=Vector3.ZERO
var overhead=false
var splash_event=false
var initialized=false
var drop_duration=.6

func reset() -> void:
	state="ready";age=0;overhead=false;initialized=false;splash_event=false;velocity=Vector3.ZERO

func begin(at: Vector3, jigging: bool=false) -> void:
	state="drop" if jigging else "windup";age=0;destination=at;overhead=jigging;splash_event=false
	if jigging and initialized:
		release_position=position
		destination=Vector3(position.x,at.y,position.z)
		drop_duration=maxf(.12,sqrt(maxf(0,2*(release_position.y-at.y)/9.81)))

func is_casting() -> bool:
	return state in ["windup","flight","drop"]

func rod_pitch() -> float:
	if state=="windup":
		if age<.34:return smoothstep(0,.34,age)*.88*(.35 if overhead else 1.0)
		return lerpf(.88,-.22,smoothstep(.34,RELEASE_TIME,age))*(.35 if overhead else 1.0)
	if state=="flight":return -.22*exp(-(age-RELEASE_TIME)*5)
	return 0

func bend_load() -> float:
	if state=="windup":return sin(clampf(age/RELEASE_TIME,0,1)*PI)*.18
	if state=="flight":return .16*exp(-(age-RELEASE_TIME)*7)
	return 0

func camera_pitch() -> float:
	return rod_pitch()*.24

func step(delta: float,tip: Vector3,clock: float) -> void:
	splash_event=false
	if state=="drop" and not initialized:
		position=tip+Vector3.DOWN*LEADER_LENGTH;initialized=true
		release_position=position;destination=Vector3(position.x,destination.y,position.z)
		drop_duration=maxf(.12,sqrt(maxf(0,2*(release_position.y-destination.y)/9.81)))
	age+=delta
	if state in ["ready","windup"]:
		var desired=tip+Vector3(sin(clock*1.7)*.06,-LEADER_LENGTH,sin(clock*1.35)*.055)
		if not initialized:position=desired;initialized=true
		# A damped tether responds to rod acceleration without one rigid body per line link.
		var dt=minf(delta,.04)
		velocity+=((desired-position)*90-velocity*15)*dt
		position+=velocity*dt
		position=tip+(position-tip).normalized()*LEADER_LENGTH
		if state=="windup" and age>=RELEASE_TIME:
			release_position=position
			release_velocity=(destination-release_position-GRAVITY*FLIGHT_TIME*FLIGHT_TIME*.5)/FLIGHT_TIME
			state="flight"
	if state=="drop":
		var t=minf(age,drop_duration)
		position=release_position+Vector3.DOWN*4.905*t*t
		velocity=Vector3.DOWN*9.81*t
		if age>=drop_duration:
			state="soak";position=destination;splash_event=true
	elif state=="flight":
		var t=clampf(age-RELEASE_TIME,0,FLIGHT_TIME)
		position=release_position+release_velocity*t+GRAVITY*t*t*.5
		velocity=release_velocity+GRAVITY*t
		if t>=FLIGHT_TIME:
			state="soak";position=destination;splash_event=true
	elif state=="soak":
		position=destination+Vector3(0,-minf((age-(drop_duration if overhead else RELEASE_TIME+FLIGHT_TIME))*.18,.35),0)
