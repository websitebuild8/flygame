extends SceneTree
const Bounds=preload("res://scripts/rigged_asset_bounds.gd")
func _initialize():call_deferred("checks")
func checks():
 var stage=Node3D.new();root.add_child(stage)
 var fish=preload("res://scripts/world_art.gd").fish(stage,1.0,"Yellowfin tuna");assert(fish.has_method("set_motion") and fish.player.get_animation_list().size()==5,"Converted yellowfin retains five source clips")
 var skeleton=fish.find_children("*","Skeleton3D",true,false)[0];assert(skeleton.get_bone_count()>=42,"Weighted skeleton survives import")
 var point=skeleton.get_bone_global_pose(4)
 fish.player.play("Swim01");fish.player.seek(.1,true);fish.player.advance(0);skeleton.force_update_all_bone_transforms();point=skeleton.get_bone_global_pose(4)
 fish.player.seek(.4,true);fish.player.advance(0);skeleton.force_update_all_bone_transforms();var changed=not point.is_equal_approx(skeleton.get_bone_global_pose(4))
 # Inspect all bones, because a particular controller can legitimately stay still.
 if not changed:
  var poses=[]
  fish.player.seek(.1,true);fish.player.advance(0);skeleton.force_update_all_bone_transforms()
  for i in range(skeleton.get_bone_count()):poses.append(skeleton.get_bone_global_pose(i))
  fish.player.seek(.4,true);fish.player.advance(0);skeleton.force_update_all_bone_transforms()
  for i in range(skeleton.get_bone_count()):changed=changed or not poses[i].is_equal_approx(skeleton.get_bone_global_pose(i))
 assert(changed,"Recovered animation actually moves skeleton bones")
 for clip in ["Swim01","Pulling01","Show01"]:
  fish.player.play(clip)
  for fraction in [0.0,.2,.4,.6,.8,.99]:
   fish.player.seek(fish.player.get_animation(clip).length*fraction,true);fish.player.advance(0)
   var bounds=Bounds.measure(fish)
   assert(bounds.position.is_finite() and bounds.size.is_finite() and bounds.size.length()<4.0,"Sampled skin stays finite without exploding")
   assert(fish.canonical_bounds().grow(.025).encloses(bounds),"Canonical landing/catch bounds contain animated fish: "+clip+str(bounds))
 fish.set_motion("pull");assert(fish.motion=="Pulling01");fish.set_motion("show");assert(fish.motion=="Show01")
 var other=preload("res://scripts/world_art.gd").fish(stage,1,"Yellowfin tuna");assert(other.player!=fish.player and other.motion=="Swim01","Individual fish retain independent playback")
 var gear=load("res://assets/models/reference/deep_blue.glb").instantiate();root.add_child(gear);var player=gear.find_children("*","AnimationPlayer",true,false)[0]
 assert(gear.find_children("*","MeshInstance3D",true,false).size()==2 and player.has_animation("Reeling01") and player.has_animation("Throwing01"),"Rod and reel preserve both skins and source motion")
 var sum=0
 for mesh in gear.find_children("*","MeshInstance3D",true,false):
  for surface in range(mesh.mesh.get_surface_count()):sum+=mesh.mesh.surface_get_array_index_len(surface)/3
 assert(sum<18000,"Selected tackle geometry remains bounded for mobile")
 for clip in player.get_animation_list():
  player.play(clip);player.seek(player.get_animation(clip).length*.35,true);player.advance(0);var box=Bounds.measure(gear);assert(box.size.is_finite() and box.size.length()<8,"Equipment clip remains within a plausible pose envelope")
 gear.queue_free();fish.queue_free();other.queue_free();stage.queue_free();await process_frame
 var game=load("res://scenes/main.tscn").instantiate();game.save_path="user://reference-assets.json";root.add_child(game);game.set_physics_process(false);game.set_process(false);game.interface.start_trip()
 var previous=game.equipped_boat;var lab=game.interface.reference_preview;lab.open();assert(lab.asset_picker.item_count==4,"Recovered models use a compact selector");assert(game.interface.menu_visible and lab.visible,"Showcase opens as a paused, separate screen")
 lab.show_asset(1);lab.play_clip("Reeling01");lab.close();assert(lab.model==null and lab.viewport.render_target_update_mode==SubViewport.UPDATE_DISABLED,"Closing releases preview model and disables its rendering")
 assert(not game.interface.menu_visible and not lab.visible and game.equipped_boat==previous,"Closing showcase restores gameplay and preserves boat selection")
 game.boat.position=Vector3(0,0,-45);game.drive.engine_running=false;game.active_spot=game.World.SPOTS[0];game.active_species=game.World.FISH[0];game.active_catch={"species":"Yellowfin tuna","weight":8.0,"value":123,"size":1.0,"grade":"LARGE"};game.fish_actor=game.Art.fish(game,.1,"Yellowfin tuna");game.fishing=true;game.land_fish()
 assert(game.catch_model.motion=="Show01" and game.inventory[-1].weight==8.0 and game.inventory[-1].value==123,"Recovered catch animation preserves weight, price and inventory logic")
 game.queue_free();await create_timer(.2).timeout
 print("PASS: recovered fish skins and moving source clips, conservative animated landing bounds, independent playback, rod/reel animations and geometry budget, paused showcase and unchanged catch economics/boat selection")
 quit()
