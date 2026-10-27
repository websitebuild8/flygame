extends Node3D
## One hand winds the physical rim, the other holds the throttle's actual knob.
var hands: Node3D
var visual: Node3D
var wheel: Node3D
var lever: Node3D
var rim_center=Vector3.ZERO
var rim_radius=.18
var lever_grip=Vector3(0,.25,0)
var wheel_contact=Vector3.ZERO
var lever_contact=Vector3.ZERO
var hand_angle=0.0
var ready_pose=false

func _ready() -> void:
	visible=false
	hands=preload("res://scripts/fishing_hands.gd").new();add_child(hands)
	hands.set_grip_style(true)

func configure(boat_visual: Node3D) -> void:
	scale=Vector3.ONE*preload("res://scripts/world_data.gd").BOAT_SCALE
	hands.body_scale=preload("res://scripts/world_data.gd").BOAT_SCALE
	visual=boat_visual;wheel=visual.get_node("HelmWheel");lever=visual.get_node("ThrottleLever")
	var wheel_points=geometry_points(wheel)
	if not wheel_points.is_empty():
		var bounds=AABB(wheel_points[0],Vector3.ZERO)
		for point in wheel_points:bounds=bounds.expand(point)
		rim_center=bounds.get_center()
		rim_radius=(bounds.size.x+bounds.size.y)*.25
	var points=geometry_points(lever)
	if not points.is_empty():
		var farthest=0.0
		for point in points:farthest=maxf(farthest,point.length())
		var total=Vector3.ZERO;var count=0
		for point in points:
			if point.length()>farthest*.90:total+=point;count+=1
		lever_grip=total/maxi(1,count)
		# Vertices are already in lever-local coordinates; world-scale compensation
		# used to pull the hand below the knob after resizing the boat.
		lever_grip-=lever_grip.normalized()*.010
	ready_pose=false;hand_angle=0

func geometry_points(part: Node3D) -> PackedVector3Array:
	var result=PackedVector3Array()
	var meshes=part.find_children("*","MeshInstance3D",true,false)
	if part is MeshInstance3D:meshes.append(part)
	for mesh in meshes:
		if not mesh.mesh:continue
		var frame=part.global_transform.affine_inverse()*mesh.global_transform
		for surface in range(mesh.mesh.get_surface_count()):
			for vertex in mesh.mesh.surface_get_arrays(surface)[Mesh.ARRAY_VERTEX]:result.append(frame*vertex)
	return result

func update_pose(delta: float,active: bool,steering: float) -> void:
	visible=active
	if not active or not is_instance_valid(wheel):return
	# Regrip at the end of a comfortable arc instead of winding the wrist 130°.
	var wheel_turn=-steering*2.3
	var comfortable=wrapf(wheel_turn,-.90,.90)
	hand_angle=comfortable if not ready_pose else lerp_angle(hand_angle,comfortable,1-exp(-delta*14))
	var local_angle=PI+hand_angle-wheel_turn
	var radial=Vector3(cos(local_angle),sin(local_angle),0)
	wheel_contact=wheel.to_global(rim_center+radial*rim_radius)
	lever_contact=lever.to_global(lever_grip)
	var inward=-(wheel.global_basis*radial).normalized()
	var normal=wheel.global_basis.z.normalized()
	var left_frame=Basis(inward,-normal,inward.cross(-normal)).orthonormalized()
	var rest=lever.get_meta("rest_basis",Basis.IDENTITY) as Basis
	var command=float(lever.get_meta("command",0.0))
	var right_frame=(visual.global_basis.orthonormalized()*Basis.from_euler(Vector3(-.10-command*.30,0,-.10))).orthonormalized()
	hands.pose_helm(wheel_contact,lever_contact,left_frame,right_frame)
	ready_pose=true
