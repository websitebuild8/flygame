extends Node3D
const MODELS=[preload("res://assets/models/market/customer_casual.glb"),preload("res://assets/models/market/customer_beach.glb"),preload("res://assets/models/market/customer_worker.glb")]
var variation=0
var model: Node3D
var player: AnimationPlayer
var walking=false
func _ready():
	set_meta("imported_model",true)
	model=MODELS[variation%MODELS.size()].instantiate();add_child(model)
	var bounds=AABB();var first=true
	for mesh in model.find_children("*","MeshInstance3D",true,false):
		var box=(global_transform.affine_inverse()*mesh.global_transform)*mesh.get_aabb()
		bounds=box if first else bounds.merge(box);first=false
		for surface in range(mesh.mesh.get_surface_count()):
			var cloth=ShaderMaterial.new()
			cloth.shader=preload("res://shaders/market_customer.gdshader")
			cloth.set_shader_parameter("shirt_color",[Color("237d85"),Color("bb7051"),Color("547a65"),Color("8b6899"),Color("c79548")][variation%5])
			mesh.set_surface_override_material(surface,cloth)
	var factor=(1.70+float(variation%3)*.045)/maxf(bounds.size.y,.01)
	model.scale*=factor;model.position=-Vector3(bounds.get_center().x,bounds.position.y,bounds.get_center().z)*factor
	player=model.find_child("AnimationPlayer",true,false) as AnimationPlayer
	set_walking(false)
func set_walking(value: bool):
	walking=value
	if not player:return
	var wanted="Walk" if value else "Idle_Neutral"
	for clip in player.get_animation_list():
		if wanted in clip:
			player.get_animation(clip).loop_mode=Animation.LOOP_LINEAR
			player.play(clip,.18,1.0 if value else .85+variation*.035)
			return
