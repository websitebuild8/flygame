extends Node3D
## Free CC BY 4.0 saltwater hard bait, with the leader knotted to its nose eye.
const MODEL=preload("res://assets/models/tackle/saltwater_lure.glb")
const MODEL_SCALE=.075
# The authored body faces +Z; its nose ends at Z=1.3356.
const FRONT_EYE=Vector3(0,.03,1.36)
func _ready() -> void:
	set_meta("imported_model",true)
	var model=MODEL.instantiate();model.name="LureBody";add_child(model)
	var frame=Basis(Vector3.RIGHT,-PI/2)
	model.basis=frame.scaled(Vector3.ONE*MODEL_SCALE)
	model.position=-(model.basis*FRONT_EYE)
	for mesh in model.find_children("*","MeshInstance3D",true,false):
		mesh.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var tie=Marker3D.new();tie.name="FrontLineTie";add_child(tie)
	var eye=MeshInstance3D.new();eye.name="NoseEye";add_child(eye)
	var ring=TorusMesh.new();ring.inner_radius=.0018;ring.outer_radius=.0032;ring.rings=12;ring.ring_segments=6
	eye.mesh=ring;eye.rotation.x=PI/2;eye.position.y=-.0032
	var metal=StandardMaterial3D.new();metal.albedo_color=Color("b8c6c9");metal.metallic=.8;metal.roughness=.3
	eye.material_override=metal;eye.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# A short wrapped leader knot and tag end meet the actual outgoing line at zero.
	var knot=MeshInstance3D.new();knot.name="LeaderKnot";add_child(knot)
	var tool=SurfaceTool.new();tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var points=PackedVector3Array()
	for i in range(33):
		var t=float(i)/32
		points.append(Vector3(cos(t*TAU*4)*.00085,t*.0045,sin(t*TAU*4)*.00085))
	points.append(Vector3(.003,.001,0))
	for i in range(points.size()-1):
		var direction=(points[i+1]-points[i]).normalized()
		var side=direction.cross(Vector3.FORWARD).normalized()
		var across=direction.cross(side).normalized()
		for j in range(6):
			var a=(side*cos(j*TAU/6)+across*sin(j*TAU/6))*.00035
			var b=(side*cos((j+1)*TAU/6)+across*sin((j+1)*TAU/6))*.00035
			for vertex in [points[i]+a,points[i+1]+a,points[i]+b,points[i]+b,points[i+1]+a,points[i+1]+b]:tool.add_vertex(vertex)
	tool.generate_normals();knot.mesh=tool.commit()
	var leader=StandardMaterial3D.new();leader.albedo_color=Color("d5e4d5");leader.roughness=.55
	knot.material_override=leader;knot.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

func apply_finish(index: int):
	var tint=[Color("d9eef2"),Color("f3b86b"),Color("70c7e3")][clampi(index,0,2)]
	for mesh in get_node("LureBody").find_children("*","MeshInstance3D",true,false):
		for i in range(mesh.mesh.get_surface_count()):
			var source=mesh.get_active_material(i)
			if source is StandardMaterial3D:
				var mat=source.duplicate();mat.albedo_color=tint;mesh.set_surface_override_material(i,mat)
