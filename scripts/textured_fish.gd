extends Node3D
## Licensed tuna asset adapter. Canonical game fish faces -Z, with +Y upward.
const MODEL=preload("res://assets/models/fish/tuna.glb")
var species_name="Yellowfin tuna"
var swim_intensity=1.0
var player: AnimationPlayer
var model_space: Node3D
func setup(name_text: String) -> void:
	species_name=name_text
	model_space=Node3D.new()
	model_space.name="ModelSpace"
	add_child(model_space)
	model_space.scale=Vector3.ONE*.5
	model_space.rotation.y=PI
	model_space.position.y=.09
	var source=MODEL.instantiate()
	model_space.add_child(source)
	var players=source.find_children("*","AnimationPlayer",true,false)
	if not players.is_empty():
		player=players[0]
		# Each fish owns its playback state; the mesh/textures remain shared.
		for library_name in player.get_animation_library_list():
			var library=player.get_animation_library(library_name).duplicate(true)
			player.remove_animation_library(library_name)
			player.add_animation_library(library_name,library)
		for clip in player.get_animation_list():
			player.get_animation(clip).loop_mode=Animation.LOOP_LINEAR
		player.play("Swim")
		player.advance(0)
func _process(_delta: float) -> void:
	if player:
		player.speed_scale=clampf(.65+swim_intensity*.35,.7,1.8)
		player.active=is_visible_in_tree()
