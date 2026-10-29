extends SceneTree
const Data=preload("res://scripts/deep_blue_data.gd")
const RodCurve=preload("res://scripts/rod_curve.gd")
func _initialize():call_deferred("checks")
func checks():
 var game=load("res://scenes/main.tscn").instantiate();game.save_path="user://deep-blue-live.json";root.add_child(game);game.interface.start_trip();game.set_physics_process(false);game.set_process(false);game.drive.engine_running=false;game.boat.position=game.SPOT;game.cast();game.fish_timer=3;game.reeling=true;game._physics_process(.016)
 var feedback=game.feedback;var outfit=feedback.equipment;var reel=outfit.get_meta("reel");var crank=reel.get_meta("crank");var rotor=reel.get_meta("rotor");var spool=reel.get_meta("spool");var body=reel.get_meta("body");var knob=reel.get_meta("free_knob")
 assert(outfit.get_meta("deep_blue",false) and reel.get_meta("deep_blue",false),"Existing starter loadout uses the adapted rod and reel")
 assert(outfit.find_children("*","Skeleton3D",true,false).is_empty() and outfit.find_children("*","AnimationPlayer",true,false).is_empty(),"Live equipment has no imported animation rig running beside the hand IK")
 assert(reel.to_global(reel.get_meta("mount_foot")).distance_to(outfit.to_global(outfit.get_meta("reel_seat")))<.0001,"Imported foot seats on the physical rod")
 assert(crank.global_position.distance_to(knob.global_position)<.15 and feedback.rig.to_local(knob.global_position).x>0,"Crank and knob form a compact right-hand retrieve")
 var body_rest=body.transform;var spool_basis=spool.basis
 crank.basis=Basis.IDENTITY;rotor.basis=Basis.IDENTITY;feedback.reel_phase=0;feedback.winding_speed=10
 var before=reel.to_local(knob.global_position)
 feedback.update_feedback(.01,true,true,.5,game.line_target())
 var after=reel.to_local(knob.global_position)
 assert(after.z<before.z,"Knob travels forward through the upper part of the winding stroke")
 var crank_angle=crank.basis.get_rotation_quaternion().get_angle();var bail_angle=rotor.basis.get_rotation_quaternion().get_angle()
 assert(absf(bail_angle/crank_angle-5)<.01,"Bail retrieves at the measured five-to-one ratio")
 var moved=false
 for i in range(90):
  feedback.update_feedback(1.0/60,true,true,.5,game.line_target())
  assert(body.transform.is_equal_approx(body_rest) and spool.basis.is_equal_approx(spool_basis),"Housing stays fixed; spool reciprocates without spinning")
  moved=moved or spool.position.length()>.001
  var fixed=(reel.global_basis.inverse()*knob.global_basis).orthonormalized()
  assert(fixed.is_equal_approx(Basis.IDENTITY),"Knob turns freely rather than twisting the player's wrist around the axle")
  assert(knob.global_position.distance_to(crank.to_global(crank.get_meta("grip_point")))<.0001,"Hand target stays on the actual knob")
  assert(feedback.hands.winding.position.distance_to(feedback.rig.to_local(knob.global_position))<.05,"Gloved hand follows the moving knob")
 assert(moved and spool.position.length()<=Data.SPOOL_TRAVEL+.0001,"Spool oscillation remains inside the authored stroke")
 var guides=outfit.get_meta("guide_points");assert(guides.size()==8,"Live line uses all eight source ceramic eyes")
 var blank=outfit.get_meta("authored_blank") as MeshInstance3D
 for guide in guides:
  var nearest=INF
  for vertex in blank.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]:nearest=minf(nearest,guide.distance_to(vertex))
  assert(nearest>.001 and nearest<.03,"Measured guide centre lies within an open ring, away from solid rod vertices")
 for bend in [0.0,.5,.95]:
  feedback.bend_amount=bend;feedback.update_feedback(0,true,true,.5,game.line_target())
  assert(feedback.routed_line_points.size()==22,"Spool, bail, eight guides and fish line form one continuous route")
  for i in range(guides.size()):assert(feedback.routed_line_points[i+2].distance_to(outfit.to_global(RodCurve.point(guides[i],bend)))<.0001,"Guide routing follows the same deformation as its mesh")
 game.equip_style("island_reel","lagoon");assert(body.get_active_material(0) is ShaderMaterial,"Existing reel cosmetic finishes apply to the new fixed housing")
 game.equip_style("island_rod","seafoam");assert(blank.get_active_material(0).get_shader_parameter("custom_paint"),"Existing rod cosmetic finishes apply to the new blank")
 game.feedback.equip("ocea","grappler","mono");assert(game.feedback.overhead and not game.feedback.equipment.get_meta("deep_blue",false),"Overhead jigging retains its compatible equipment")
 game.feedback.equip("island_reel","offshore_rod","mono");assert(game.feedback.equipment.get_meta("reel").get_meta("deep_blue",false) and not game.feedback.equipment.get_meta("deep_blue",false),"The new reel remains compatible with the other spinning rod")
 game.feedback.equip("island_reel","island_rod","mono");assert(game.feedback.equipment.get_meta("deep_blue",false),"Switching loadouts restores the complete adapted outfit")
 game.queue_free();await create_timer(.2).timeout
 print("PASS: live Deep Blue starter adaptation, no extra skeleton, seated mount, right-hand forward winding, five-to-one bail, fixed housing, reciprocating spool, free knob, gloved grip, eight real bent guides, cosmetics and alternate equipment compatibility")
 quit()
