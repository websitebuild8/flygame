extends SceneTree
## Offline conversion QA, never evaluated per gameplay frame.
const Bounds=preload("res://scripts/rigged_asset_bounds.gd")
func _initialize():call_deferred("inspect")
func inspect():
 var actor=load("res://assets/models/reference/speargun.glb").instantiate();root.add_child(actor)
 var player=actor.find_children("*","AnimationPlayer",true,false)[0]
 var result={"source":"res://assets/models/reference/speargun.glb","clips":{},"bone_names":[]}
 for skeleton in actor.find_children("*","Skeleton3D",true,false):
  for i in range(skeleton.get_bone_count()):result.bone_names.append(skeleton.get_bone_name(i))
 for clip in player.get_animation_list():
  player.play(clip);var samples=[];var merged=AABB();var first=true
  for fraction in [0.0,.25,.5,.75,.99]:
   player.seek(player.get_animation(clip).length*fraction,true);player.advance(0)
   var box=Bounds.measure(actor);merged=box if first else merged.merge(box);first=false
   samples.append({"fraction":fraction,"position":[box.position.x,box.position.y,box.position.z],"size":[box.size.x,box.size.y,box.size.z]})
  result.clips[clip]={"duration":player.get_animation(clip).length,"samples":samples,"envelope_position":[merged.position.x,merged.position.y,merged.position.z],"envelope_size":[merged.size.x,merged.size.y,merged.size.z]}
  print(clip," ",merged)
 var file=FileAccess.open("res://docs/speargun-pose-inspection.json",FileAccess.WRITE);file.store_string(JSON.stringify(result,"  "));file.close()
 actor.queue_free();await process_frame;quit()
