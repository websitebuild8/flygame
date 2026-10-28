extends SceneTree
## One-off portraits from already licensed game models; no 3D viewport is needed in the UI.
const World=preload("res://scripts/world_data.gd")
const Art=preload("res://scripts/world_art.gd")
func _initialize():call_deferred("render_portraits")
func render_portraits():
 var viewport=SubViewport.new();viewport.size=Vector2i(384,216);viewport.transparent_bg=true;viewport.own_world_3d=true;viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS;root.add_child(viewport)
 var room=Node3D.new();viewport.add_child(room)
 var environment=WorldEnvironment.new();environment.environment=Environment.new();environment.environment.background_mode=Environment.BG_COLOR;environment.environment.background_color=Color(0,0,0,0);environment.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;environment.environment.ambient_light_color=Color.WHITE;environment.environment.ambient_light_energy=.85;room.add_child(environment)
 var sun=DirectionalLight3D.new();room.add_child(sun);sun.rotation_degrees=Vector3(-35,-30,0);sun.light_energy=1.7
 var fill=DirectionalLight3D.new();room.add_child(fill);fill.rotation_degrees=Vector3(30,160,0);fill.light_energy=.6
 var camera=Camera3D.new();room.add_child(camera);camera.projection=Camera3D.PROJECTION_ORTHOGONAL
 for fish in World.FISH:
  var actor=Art.fish(room,1,fish.name);actor.rotation.y=PI/2
  var bounds=actor.transform*actor.get_meta("fish_bounds")
  var center=bounds.get_center();camera.size=maxf(bounds.size.y*1.25,bounds.size.x/1.777*1.18);camera.position=center+Vector3(0,0,12);camera.look_at(center)
  for i in range(6):await process_frame
  await RenderingServer.frame_post_draw
  var path="res://assets/ui/fish/"+fish.name.to_lower().replace(" ","_")+".png"
  viewport.get_texture().get_image().save_png(path);print("Rendered ",path)
  room.remove_child(actor);actor.queue_free()
 viewport.queue_free();quit()
