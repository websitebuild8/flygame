extends Node3D
## JUST's authored, textured glove/sleeve model; two IK chains follow fishing grips.
const SOURCE=preload("res://assets/models/hands/gloved_arms.glb")
var grip: Marker3D
var winding: Marker3D
var skeleton: Skeleton3D
var chains: Array[Dictionary]=[]
var wrists: Array[Marker3D]=[]
var model: Node3D
var helm_mode=false
func _ready() -> void:
	set_meta("imported_model",true)
	model=SOURCE.instantiate();add_child(model)
	for player in model.find_children("*","AnimationPlayer",true,false):player.stop();player.active=false
	for camera in model.find_children("*","Camera3D",true,false):camera.current=false;camera.queue_free()
	for mesh in model.find_children("*","MeshInstance3D",true,false):
		mesh.visible=mesh.name in ["Object_7","Object_9"]
		mesh.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	model.scale=Vector3.ONE*(.28/11.424)
	model.rotation.y=PI
	model.position=Vector3(.10,-1.10,.20)
	skeleton=model.find_child("Skeleton3D",true,false) as Skeleton3D
	assert(skeleton)
	grip=Marker3D.new();grip.name="LeftRodGrip";add_child(grip)
	winding=Marker3D.new();winding.name="RightReelGrip";add_child(winding)
	for side in ["L","R"]:
		var wrist=Marker3D.new();add_child(wrist);wrists.append(wrist)
		chains.append({"upper":skeleton.find_bone("upperarm_L.L_30" if side=="L" else "upperarm_L.R_56"),"lower":skeleton.find_bone("lowerarm_L.L_29" if side=="L" else "lowerarm_L.R_55"),"hand":skeleton.find_bone("hand_L.L_25" if side=="L" else "hand_L.R_51")})
	set_grip_style(false)

func set_grip_style(driving: bool,counter: bool=false) -> void:
	# Pose the authored finger bones around the grip in the hand's actual palm frame.
	for side in ["L","R"]:
		var hand=skeleton.find_bone("hand_L.L_25" if side=="L" else "hand_L.R_51")
		var hand_frame=skeleton.get_bone_global_rest(hand).basis
		for finger in ["index","middle","ring","pink"]:
			var chain: Array[int]=[]
			for bone in range(skeleton.get_bone_count()):
				var name=skeleton.get_bone_name(bone)
				if name.begins_with(finger+"_") and ("."+side+"_") in name:chain.append(bone)
			for joint in range(mini(3,chain.size())):
				var bone=chain[joint]
				# Left fingers travel out under the handle, rise around its far side,
				# then return across the top toward the palm.
				var wrap={"index":[.30,1.55,2.85],"middle":[.38,1.62,2.92],"ring":[.43,1.72,3.0],"pink":[.50,1.80,3.06]}
				var retrieve={"index":[.80,1.80,2.70],"middle":[.50,1.20,1.90],"ring":[.35,.95,1.50],"pink":[.25,.80,1.40]}
				var angle=(wrap[finger][joint] if side=="L" else -(wrap[finger][joint] if driving else retrieve[finger][joint]))
				if counter:angle=[.12,.35,.65][joint]*(1 if side=="L" else -1)
				var direction=(hand_frame*Vector3(sin(angle),cos(angle),0)).normalized()
				var rest=skeleton.get_bone_global_rest(bone).basis
				var desired=Basis(Quaternion(rest.y.normalized(),direction))*rest
				var parent=skeleton.get_bone_parent(bone)
				var local=skeleton.get_bone_global_pose(parent).basis.inverse()*desired
				skeleton.set_bone_pose_rotation(bone,local.orthonormalized().get_rotation_quaternion())
				skeleton.force_update_all_bone_transforms()
	# Oppose the left thumb across the foregrip instead of leaving it extended.
	var left_hand=skeleton.find_bone("hand_L.L_25")
	var palm=skeleton.get_bone_global_rest(left_hand).basis
	var thumb_names=["thumb_L.L_8","thumb_L.002.L_7","thumb_L.001.L_6"]
	var thumb_directions=[Vector3(.8,.5,-.2),Vector3(.1,.98,-.1),Vector3(-.3,.95,0)]
	for joint in range(thumb_names.size()):
		var name=thumb_names[joint]
		var bone=skeleton.find_bone(name)
		var rest=skeleton.get_bone_global_rest(bone).basis
		var direction=(palm*thumb_directions[joint]).normalized()
		var desired=Basis(Quaternion(rest.y.normalized(),direction))*rest
		var parent=skeleton.get_bone_parent(bone)
		var local=skeleton.get_bone_global_pose(parent).basis.inverse()*desired
		skeleton.set_bone_pose_rotation(bone,local.orthonormalized().get_rotation_quaternion())
		skeleton.force_update_all_bone_transforms()
func pose(handle: Vector3,turning: bool,overhead: bool) -> void:
	helm_mode=false
	# Balance the hold immediately above the reel seat, with the lower fingers
	# beside its stem, rather than stretching the hand up the blank.
	grip.position=Vector3(-.015,.135,.05)
	winding.position=handle+Vector3(0,0,.035)
	# Palm under the foregrip: fingers rise around it, rather than draping over it.
	var rod_axis=Vector3(0,.47,-.882666).normalized()
	var palm_up=Vector3(0,-rod_axis.z,rod_axis.y)
	# Palm normal faces up; fingers start to the right and curl back left.
	# Thumb opposes that path across the top. Use an anatomical frame, not Euler roll.
	var left_basis=Basis(palm_up,Vector3.RIGHT,rod_axis)
	# The knob spins freely in the hand; the wrist follows its orbit with a small
	# flex rather than rotating the entire hand with the crank.
	var right_basis=Basis.from_euler(Vector3(-.35+clampf(handle.z*.4,-.10,.10),.1,.30+clampf(handle.y*.3,-.08,.08)))
	var view=get_parent().get_parent() as Node3D
	for i in range(2):
		var grasp=grip.position if i==0 else winding.position
		var orientation=left_basis if i==0 else right_basis
		wrists[i].transform=Transform3D(orientation,grasp-orientation*Vector3(.065 if i==0 else -.065,.27,.025)*.28)
		solve_arm(i,skeleton.to_local(view.to_global(Vector3(-.80 if i==0 else .65,-.50,-.28))))

func pose_helm(left_contact: Vector3,right_contact: Vector3,left_frame: Basis,right_frame: Basis) -> void:
	helm_mode=true
	grip.global_position=left_contact;winding.global_position=right_contact
	var view=get_parent().get_parent() as Node3D
	for i in range(2):
		var frame=left_frame if i==0 else right_frame
		var contact=left_contact if i==0 else right_contact
		wrists[i].global_transform=Transform3D(frame,contact-frame*Vector3(.065 if i==0 else -.065,.27,.025)*.28)
		solve_arm(i,skeleton.to_local(view.to_global(Vector3(-.60 if i==0 else .60,-.55,-.22))))

func solve_arm(index: int,pole: Vector3) -> void:
	var chain=chains[index]
	var upper=skeleton.get_bone_global_rest(chain.upper)
	var lower=skeleton.get_bone_global_rest(chain.lower)
	var hand=skeleton.get_bone_global_rest(chain.hand)
	# Shoulders belong to the player's body, not the moving rod. This lets elbows
	# articulate while the hands remain on the rod and freely rotating reel knob.
	var view=get_parent().get_parent() as Node3D
	var origin=skeleton.to_local(view.to_global(Vector3((-.24 if helm_mode else -.40) if index==0 else .26,-.32,-.08)))
	var target=skeleton.to_local(wrists[index].global_position)
	var delta=target-origin
	var scale=skeleton.global_basis.get_scale().x
	# Human-sized segments with a small reach allowance for the view-model rig.
	var reach=maxf(1.0,(delta.length()*scale+.025)/.64)
	var l1=.33*reach/scale
	var l2=.31*reach/scale
	var d=clampf(delta.length(),absf(l1-l2)+.001,l1+l2-.001)
	var direction=delta.normalized()
	var bend=pole-origin-direction*(pole-origin).dot(direction)
	if bend.length()<.001:bend=direction.cross(Vector3.RIGHT)
	bend=bend.normalized()
	var cosine=clampf((l1*l1+d*d-l2*l2)/(2*l1*d),-1,1)
	var elbow=origin+direction*l1*cosine+bend*l1*sqrt(1-cosine*cosine)
	var endpoint=origin+direction*d
	var wrist_basis=skeleton.global_basis.orthonormalized().inverse()*wrists[index].global_basis.orthonormalized()
	var upper_basis=Basis(Quaternion(upper.basis.y.normalized(),(elbow-origin).normalized()))*upper.basis
	skeleton.set_bone_global_pose(chain.upper,Transform3D(upper_basis,origin))
	skeleton.force_update_all_bone_transforms()
	var forearm_rest=wrist_basis*hand.basis.inverse()*lower.basis
	var lower_basis=Basis(Quaternion(forearm_rest.y.normalized(),(endpoint-elbow).normalized()))*forearm_rest
	skeleton.set_bone_global_pose(chain.lower,Transform3D(lower_basis,elbow))
	skeleton.force_update_all_bone_transforms()
	skeleton.set_bone_global_pose(chain.hand,Transform3D(wrist_basis,endpoint))
	skeleton.force_update_all_bone_transforms()
	# The authored sleeve also weights three forearm twist bones. Reposition them
	# along the solved arm instead of leaving them in the original shortened pose.
	for bone in range(skeleton.get_bone_count()):
		if skeleton.get_bone_parent(bone)!=chain.lower or not skeleton.get_bone_name(bone).begins_with("twist_arm"):continue
		var rest=skeleton.get_bone_global_rest(bone)
		var fraction=clampf(lower.origin.distance_to(rest.origin)/lower.origin.distance_to(hand.origin),0,1)
		var elbow_turn=(lower_basis*lower.basis.inverse()).orthonormalized().get_rotation_quaternion()
		var wrist_turn=(wrist_basis*hand.basis.inverse()).orthonormalized().get_rotation_quaternion()
		var basis=Basis(elbow_turn.slerp(wrist_turn,fraction*.85))*rest.basis
		skeleton.set_bone_global_pose(bone,Transform3D(basis,elbow.lerp(endpoint,fraction)))
		skeleton.force_update_all_bone_transforms()
