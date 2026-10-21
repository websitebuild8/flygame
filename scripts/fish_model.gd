extends Node3D
## Species-inspired anatomy with smooth body topology and swept membrane fins.
const Art = preload("res://scripts/world_art.gd")
var species_name = "Yellowfin tuna"
var variant = 0
var tail: Node3D
var phase = 0.0
var swim_intensity=1.0

func setup(name_text: String) -> void:
	species_name = name_text
	variant = 1 if "Skipjack" in name_text else (2 if "trevally" in name_text.to_lower() else 0)
	if "Mahi" in name_text: variant=3
	if "Wahoo" in name_text: variant=4
	if "Red bass" in name_text: variant=5
	if "Rainbow" in name_text: variant=6
	if "Bluefin" in name_text: variant=7
	if "Dogtooth" in name_text: variant=8
	if "jobfish" in name_text: variant=9
	if "snapper" in name_text: variant=10
	if "hind" in name_text: variant=11
	if "grouper" in name_text: variant=12
	if "barracuda" in name_text: variant=13
	if "Kawakawa" in name_text: variant=14
	build_body()
	build_fins()
	build_face()

func profile(t: float) -> Vector2:
	# Nose, shoulders, belly and narrow caudal peduncle.
	var width = pow(sin(PI*clampf(t,0.002,0.998)),0.85)
	var taper = lerpf(1.1,0.3,smoothstep(0.35,0.95,t))
	var height = 0.39*width*taper+0.025
	if variant in [2,5,7,10,11,12]: height*=1.3
	if variant in [3,4,6,13]: height*=0.72
	if variant==3 and t<0.23: height*=1.7
	if variant==13: height*=0.68
	if variant in [11,12]: height*=1.2
	return Vector2(height*(0.61 if variant!=2 else 0.40),height)

func build_body() -> void:
	var vertices = PackedVector3Array()
	var uv = PackedVector2Array()
	var indices = PackedInt32Array()
	const RINGS = 49
	const SIDES = 40
	for i in range(RINGS):
		var t = float(i)/(RINGS-1)
		var shape = profile(t)
		var z = lerpf(-1.13,1.02,t)
		for j in range(SIDES+1):
			var a = float(j)/SIDES*TAU
			vertices.append(Vector3(cos(a)*shape.x,sin(a)*shape.y,z))
			uv.append(Vector2(float(j)/SIDES,t))
	for i in range(RINGS-1):
		for j in range(SIDES):
			var a = i*(SIDES+1)+j
			var b = a+SIDES+1
			indices.append_array(PackedInt32Array([a,b+1,b,a,a+1,b+1]))
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_TEX_UV] = uv
	arrays[Mesh.ARRAY_INDEX] = indices
	var raw = ArrayMesh.new()
	raw.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
	var surface = SurfaceTool.new()
	surface.create_from(raw,0)
	surface.generate_normals()
	var body = MeshInstance3D.new()
	body.mesh = surface.commit()
	var skin = ShaderMaterial.new()
	skin.shader = preload("res://shaders/fish_skin.gdshader")
	skin.set_shader_parameter("species",variant)
	body.material_override = skin
	add_child(body)

func membrane(parent: Node3D, points: PackedVector2Array, plane: String, origin: Vector3, color: Color) -> void:
	var vertices = PackedVector3Array()
	var colors = PackedColorArray()
	for i in range(points.size()):
		var p = points[i]
		vertices.append(origin+(Vector3(0,p.y,p.x) if plane=="yz" else Vector3(p.y,0,p.x)))
		colors.append(color.lightened(float(i%3)*0.08))
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_COLOR] = colors
	arrays[Mesh.ARRAY_INDEX] = Geometry2D.triangulate_polygon(points)
	var mesh = ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
	var node = MeshInstance3D.new()
	node.mesh = mesh
	var material = Art.mat(color,0.35)
	material.vertex_color_use_as_albedo = true
	material.albedo_color = Color.WHITE
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	node.material_override = material
	parent.add_child(node)
	# Fine visible fin rays, rather than rectangular blocks.
	for i in range(1,points.size()-1):
		var endpoint = origin+(Vector3(0,points[i].y,points[i].x) if plane=="yz" else Vector3(points[i].y,0,points[i].x))
		Art.pole(parent,origin,endpoint,0.0035,color.darkened(0.2))

func build_fins() -> void:
	var yellow = Color("c6a840") if variant in [0,3,6] else (Color("3987c5") if variant==7 else (Color("9b5049") if variant==5 else Color("445b65")))
	var depth = 0.48 if variant in [2,5,7] else 0.38
	membrane(self,PackedVector2Array([Vector2(-0.38,0),Vector2(-0.29,0.27),Vector2(-0.04,0.13),Vector2(0.16,0)]),"yz",Vector3(0,depth,0),yellow)
	var sail = 0.48 if variant==0 else 0.24
	membrane(self,PackedVector2Array([Vector2(0,0),Vector2(0.09,sail),Vector2(0.25,0.08),Vector2(0.4,-0.05)]),"yz",Vector3(0,0.23,0.22),yellow)
	membrane(self,PackedVector2Array([Vector2(0,0),Vector2(0.12,-sail*0.8),Vector2(0.34,0.05)]),"yz",Vector3(0,-0.23,0.3),yellow)
	for side in [-1,1]:
		membrane(self,PackedVector2Array([Vector2(0,0),Vector2(0.45,side*0.37),Vector2(0.34,side*0.08)]),"xz",Vector3(side*0.2,-0.03,-0.47),Color("5d7177"))
		if variant in [0,1,4,8]:
			for i in range(6):
				var z = 0.57+float(i)*0.07
				var h = 0.15-float(i)*0.013
				membrane(self,PackedVector2Array([Vector2(0,0),Vector2(0.045,side*0.09),Vector2(0.085,-side*0.02)]),"yz",Vector3(0,side*h,z),yellow)
	tail = Node3D.new()
	add_child(tail)
	tail.position.z = 0.98
	membrane(tail,PackedVector2Array([Vector2(0,-0.035),Vector2(0.48,-0.58),Vector2(0.38,-0.26),Vector2(0.16,0),Vector2(0.38,0.26),Vector2(0.48,0.58),Vector2(0,0.035)]),"yz",Vector3.ZERO,yellow.darkened(0.16))

func build_face() -> void:
	var shape = profile(0.14)
	for side in [-1,1]:
		var eye_at = Vector3(side*(shape.x+0.005),0.075,-0.83)
		Art.oval(self,eye_at,Vector3(0.032,0.10,0.10),Color("958655"))
		Art.oval(self,eye_at+Vector3(side*0.013,0,0),Vector3(0.032,0.065,0.065),Color("101c23"))
		Art.oval(self,eye_at+Vector3(side*0.026,0.015,-0.008),Vector3(0.01,0.018,0.018),Color("e6f6ee"))
		var previous = Vector3(side*0.09,0.24,-0.48)
		for i in range(1,10):
			var angle = float(i)/9*PI
			var point = Vector3(side*(0.11+sin(angle)*0.10),0.24-float(i)/9*0.45,-0.48+sin(angle)*0.07)
			Art.pole(self,previous,point,0.005,Color("34454c"))
			previous = point
		Art.pole(self,Vector3(side*0.04,-0.02,-1.11),Vector3(side*0.10,-0.05,-0.96),0.005,Color("3c4a50"))
		if variant==2:
			for i in range(9):
				Art.oval(self,Vector3(side*0.07,-0.01,0.5+i*0.045),Vector3(0.025,0.045,0.02),Color("a8b9b9"))

func _process(delta: float) -> void:
	phase += delta*swim_intensity
	if is_visible_in_tree() and tail:
		tail.rotation.y = sin(phase*4.5)*(0.13+0.04*swim_intensity)
