extends Node
var players: Array[AudioStreamPlayer] = []
var mix_rpm = 0.0
var mix_speed = 0.0

func _ready() -> void:
	for sound in ["engine_idle","engine_cruise","engine_full","water_run"]:
		var player = AudioStreamPlayer.new()
		var wav = load("res://assets/audio/%s.wav" % sound) as AudioStreamWAV
		wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
		wav.loop_begin = 0
		wav.loop_end = wav.data.size()/2
		player.stream = wav
		player.volume_db = -60
		add_child(player)
		players.append(player)

func update_audio(delta: float, rpm: float, speed: float, active: bool, sound: bool) -> void:
	mix_rpm = lerpf(mix_rpm,rpm,1-exp(-delta*3))
	mix_speed = lerpf(mix_speed,absf(speed),1-exp(-delta*2))
	if not active or not sound:
		for player in players:
			player.stop()
		return
	var weights = [0.6*(1-mix_rpm*0.8),sin(mix_rpm*PI)*0.55,smoothstep(0.5,1,mix_rpm)*0.6,clampf(mix_speed/18,0,1)*0.65]
	for i in range(players.size()):
		var player = players[i]
		if not player.playing:
			player.play()
		player.pitch_scale = lerpf(0.9,1.2,mix_rpm) if i<3 else lerpf(0.85,1.08,clampf(mix_speed/25,0,1))
		player.volume_db = linear_to_db(maxf(float(weights[i]),0.001))-12

func _exit_tree() -> void:
	for player in players:
		player.stop()
