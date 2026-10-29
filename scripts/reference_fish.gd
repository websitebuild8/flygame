extends Node3D
## Shared recovered fish playback; each species supplies its own scene and frame.
var species_name=""
var swim_intensity=1.0
var player: AnimationPlayer
var model_space: Node3D
var motion=""
func setup(name_text: String):
 species_name=name_text;model_space=Node3D.new();add_child(model_space);model_space.rotation.y=PI
 configure_model_space()
 var model=source_scene().instantiate();model_space.add_child(model)
 for mesh in model.find_children("*","MeshInstance3D",true,false):
  mesh.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;mesh.custom_aabb=mesh.get_aabb().grow(.6)
 player=model.find_children("*","AnimationPlayer",true,false)[0]
 # Imported animation resources are shared and already linear-sampled. Set loop
 # on instance-local copies so previews and other fish cannot change each other.
 for name in player.get_animation_library_list():
  var library=player.get_animation_library(name).duplicate(true);player.remove_animation_library(name);player.add_animation_library(name,library)
 for clip in player.get_animation_list():player.get_animation(clip).loop_mode=Animation.LOOP_LINEAR
 set_motion("swim");player.advance(0)
func source_scene() -> PackedScene:return null
func configure_model_space() -> void:pass
func set_motion(value: String):
 var next="Show01" if value=="show" else ("Pulling01" if value=="pull" else "Swim01")
 if motion==next:return
 motion=next;player.play(next,.12)
func _process(_delta: float):
 if not player:return
 player.active=is_visible_in_tree()
 player.speed_scale=.8 if motion=="Show01" else clampf(.65+swim_intensity*.3,.7,1.7)
