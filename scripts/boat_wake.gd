extends Node3D
var pieces: Array[MeshInstance3D] = []
var ages: Array[float] = []
var timer = 0.0
var cursor = 0

func _ready() -> void:
	for i in range(22):
		var node = MeshInstance3D.new()
		var mesh = QuadMesh.new()
		mesh.size = Vector2(0.4,0.8)
		node.mesh = mesh
		node.rotation.x = -PI/2
		var material = StandardMaterial3D.new()
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		material.albedo_color = Color(0.85,0.98,0.92,0.5)
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		node.material_override = material
		node.visible = false
		add_child(node)
		pieces.append(node)
		ages.append(5.0)

func update_wake(delta: float, at: Vector3, stern: Vector3, speed: float) -> void:
	timer -= delta
	if absf(speed)>1.2 and timer<=0:
		timer = 0.09
		var node = pieces[cursor]
		node.position = at+stern*2.7*signf(speed)
		node.position.y = get_parent().surface.height(Vector2(node.position.x,node.position.z))+.008
		node.rotation.y = atan2(stern.x,stern.z)
		ages[cursor] = 0
		cursor = (cursor+1)%pieces.size()
	for i in range(pieces.size()):
		ages[i] += delta
		var age = ages[i]
		pieces[i].visible = age<1.9
		if age<1.9:
			pieces[i].position.y=get_parent().surface.height(Vector2(pieces[i].position.x,pieces[i].position.z))+.008
			pieces[i].scale = Vector3(1+age*4.0,1+age*1.5,1)
			(pieces[i].material_override as StandardMaterial3D).albedo_color.a = (1-age/1.9)*0.35
