extends RefCounted
## Game-scale outboard approximation: persistent lever, neutral detent,
## in-gear idle, limited reverse, inertia and a low-speed direction interlock.
var engine_running = true
var lever = 0.0
var gear = 0
var throttle = 0.0
var speed = 0.0
var steering = 0.0
var rpm = 0.0
var shift_delay = 0.0
var shift_waiting = false
var performance_propeller = false
var base_speed = 12.5
var handling = 1.0
var acceleration_multiplier = 1.0
const NEUTRAL_DETENT = 0.13
const SHIFT_TIME = 0.32

func set_lever(value: float) -> void:
	lever = clampf(value,-1.0,1.0)
	if absf(lever) <= NEUTRAL_DETENT:
		lever = 0.0

func reset() -> void:
	lever = 0
	gear = 0
	throttle = 0
	speed = 0
	steering = 0
	rpm = 0
	shift_delay = 0
	shift_waiting = false

func step(delta: float, wheel: float, level: int) -> void:
	if not engine_running:
		speed*=exp(-delta*0.95)
		if absf(speed)<0.025: speed=0
		rpm=0
		throttle=0
		steering=lerpf(steering,clampf(wheel,-1,1),1-exp(-delta*7))
		return
	var requested = 0 if lever == 0 else (1 if lever > 0 else -1)
	shift_delay = maxf(0,shift_delay-delta)
	shift_waiting = requested != 0 and speed * requested < -0.8
	if requested != gear:
		if gear != 0:
			gear = 0
			shift_delay = SHIFT_TIME
		elif not shift_waiting and shift_delay <= 0:
			gear = requested
	throttle = clampf((absf(lever)-NEUTRAL_DETENT)/(1-NEUTRAL_DETENT),0,1) if gear != 0 else 0.0
	var max_forward = (base_speed + float(level)*3.0)*(1.08 if performance_propeller else 1.0)
	var target_speed = 0.0
	if gear != 0:
		var maximum = max_forward if gear > 0 else 3.8
		target_speed = float(gear) * (0.85 + pow(throttle,1.45)*(maximum-0.85))
	if gear == 0:
		# Neutral coasts: propeller thrust stops, momentum does not.
		speed *= exp(-delta*0.75)
		if absf(speed)<0.025:
			speed = 0
	else:
		var acceleration = (1.3 + throttle*1.8)*acceleration_multiplier*(1.12 if performance_propeller else 1.0)
		speed = move_toward(speed,target_speed,acceleration*delta)
	steering = lerpf(steering,clampf(wheel,-1,1),1-exp(-delta*7.0))
	var desired_rpm = 0.13 + throttle*0.87 if gear != 0 else 0.10
	rpm = lerpf(rpm,desired_rpm,1-exp(-delta*3.5))

func yaw_rate() -> float:
	# Reverse thrust turns the stern the other way; no pirouettes at rest.
	var authority = minf(absf(speed)/2.2,1.0)
	var high_speed_limit = lerpf(1.0,0.62,clampf(absf(speed)/14.0,0,1))
	return -steering * authority * high_speed_limit * signf(speed) * 0.85 * handling

func gear_name() -> String:
	return "F" if gear > 0 else ("R" if gear < 0 else "N")
