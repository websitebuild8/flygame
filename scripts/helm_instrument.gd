extends SubViewportContainer
## Only the active boat's control mesh is rendered, never another hull.
var part: Node3D
var is_wheel=false
var travel=1.0
var last_value=INF
var last_active=false
var viewport_3d: SubViewport
func configure(source: Node3D, wheel: bool):
	is_wheel=wheel
	travel=float(source.get_meta("travel_direction",1.0))
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	stretch=true
	viewport_3d=SubViewport.new()
	viewport_3d.size=Vector2i(192,192)
	viewport_3d.transparent_bg=true
	viewport_3d.own_world_3d=true
	viewport_3d.render_target_update_mode=SubViewport.UPDATE_DISABLED
	add_child(viewport_3d)
	var frame=Node3D.new();viewport_3d.add_child(frame)
	part=source.duplicate() as Node3D
	part.transform=Transform3D.IDENTITY
	frame.add_child(part)
	var bounds=AABB();var first=true
	var meshes=part.find_children("*","MeshInstance3D",true,false)
	if part is MeshInstance3D:meshes.append(part)
	for mesh in meshes:
		mesh.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var box=(frame.global_transform.affine_inverse()*mesh.global_transform)*mesh.get_aabb()
		bounds=box if first else bounds.merge(box);first=false
	if not wheel:
		var rest_bounds=bounds
		for angle in [-.8,-.4,.4,.8]:
			bounds=bounds.merge(Transform3D(Basis(Vector3.RIGHT,angle),Vector3.ZERO)*rest_bounds)
	var factor=1.65/maxf(maxf(bounds.size.x,bounds.size.y),maxf(bounds.size.z,.01))
	frame.scale=Vector3.ONE*factor
	frame.position=-bounds.get_center()*factor
	var camera=Camera3D.new();viewport_3d.add_child(camera)
	camera.projection=Camera3D.PROJECTION_ORTHOGONAL
	camera.size=1.9
	camera.keep_aspect=Camera3D.KEEP_WIDTH
	camera.position=Vector3(0,0,3) if wheel else Vector3(1.4,.6,2.7)
	camera.look_at(Vector3.ZERO)
	camera.current=true
	var env=Environment.new()
	env.background_mode=Environment.BG_CLEAR_COLOR
	env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color=Color.WHITE;env.ambient_light_energy=.8
	camera.environment=env
	var light=DirectionalLight3D.new();viewport_3d.add_child(light)
	light.rotation_degrees=Vector3(-35,-25,0);light.light_energy=1.2
func pose(value: float, active: bool):
	visible=active
	if active and (not last_active or not is_equal_approx(value,last_value)):
		viewport_3d.render_target_update_mode=SubViewport.UPDATE_ONCE
	elif not active:
		viewport_3d.render_target_update_mode=SubViewport.UPDATE_DISABLED
	last_active=active;last_value=value
	part.basis=Basis(Vector3.BACK,-value*2.3) if is_wheel else Basis(Vector3.RIGHT,value*.8*travel)
