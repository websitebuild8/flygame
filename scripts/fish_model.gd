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
	# Deliberate snout, cranial mass, shoulder, belly and caudal peduncle.
	var stations=[Vector3(0,.043,.075),Vector3(.055,.105,.155),Vector3(.15,.17,.25),Vector3(.29,.205,.32),Vector3(.45,.19,.30),Vector3(.65,.125,.22),Vector3(.82,.055,.115),Vector3(.94,.025,.052),Vector3(1,.022,.043)]
	var shape=Vector2(.02,.04)
	for i in range(stations.size()-1):
		var left: Vector3=stations[i]
		var right: Vector3=stations[i+1]
		if t>=left.x and t<=right.x:
			var blend=(t-left.x)/(right.x-left.x)
			var before: Vector3=stations[maxi(0,i-1)]
			var after: Vector3=stations[mini(stations.size()-1,i+2)]
			shape=Vector2(left.y,left.z).cubic_interpolate(Vector2(right.y,right.z),Vector2(before.y,before.z),Vector2(after.y,after.z),blend)
			break
	# Family-specific silhouettes, beyond changing skin colours.
	if variant in [2,7]:
		shape*=Vector2(.76,1.35 if variant==2 else 1.18)
		shape.y+=exp(-pow((t-.18)*7,2))*(.11 if variant==2 else .05)
	if variant in [5,10]: shape*=Vector2(.95,1.16)
	if variant in [11,12]:
		shape*=Vector2(1.22,1.02)
		shape.x+=exp(-pow((t-.13)*8,2))*.06
	if variant in [4,13]:
		shape*=Vector2(.67,.60 if variant==4 else .42)
		shape.y+=sin(t*PI)*.025
	if variant==6: shape*=Vector2(.76,.80)
	if variant==9: shape*=Vector2(.84,.88)
	if variant==3:
		shape*=Vector2(.65,.85)
		shape.y+=exp(-pow((t-.13)*8,2))*.16
	if variant==8: shape*=Vector2(.90,.88)
	return shape

func build_body() -> void:
	var vertices = PackedVector3Array()
	var uv = PackedVector2Array()
	var indices = PackedInt32Array()
	const RINGS = 65
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
	var texcoords=PackedVector2Array()
	for i in range(points.size()):
		var p = points[i]
		vertices.append(origin+(Vector3(0,p.y,p.x) if plane=="yz" else Vector3(p.y,0,p.x)))
		colors.append(color.lightened(float(i%3)*0.04))
		texcoords.append(Vector2(p.x,p.y))
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_COLOR] = colors
	arrays[Mesh.ARRAY_TEX_UV] = texcoords
	arrays[Mesh.ARRAY_INDEX] = Geometry2D.triangulate_polygon(points)
	var mesh = ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
	var node = MeshInstance3D.new()
	node.mesh = mesh
	var material=ShaderMaterial.new()
	material.shader=preload("res://shaders/fish_fin.gdshader")
	material.set_shader_parameter("fin_color",color)
	node.material_override=material
	parent.add_child(node)
	# Fine visible fin rays, rather than rectangular blocks.
	for i in range(1,points.size()-1):
		var endpoint = origin+(Vector3(0,points[i].y,points[i].x) if plane=="yz" else Vector3(points[i].y,0,points[i].x))
		Art.pole(parent,origin,endpoint,0.0015,color.darkened(0.1))

func dorsal_ribbon(start: float, end: float, height: float, spiny: bool, color: Color) -> void:
	var points=PackedVector2Array()
	const STEPS=18
	for i in range(STEPS+1):
		var t=lerpf(start,end,float(i)/STEPS)
		var h=height*(.5+.5*sin(float(i)/STEPS*PI))
		if spiny and i%2==0: h*=.62
		points.append(Vector2(lerpf(-1.13,1.02,t),profile(t).y+h))
	for i in range(STEPS,-1,-1):
		var t=lerpf(start,end,float(i)/STEPS)
		points.append(Vector2(lerpf(-1.13,1.02,t),profile(t).y*.95))
	membrane(self,points,"yz",Vector3.ZERO,color)

func build_fins() -> void:
	var tuna=variant in [0,1,4,8,14]
	var grouper=variant in [11,12]
	var snapper=variant in [5,10]
	var trevally=variant in [2,7]
	var fin=Color("65766b")
	if variant==0: fin=Color("d5b634")
	if variant==3: fin=Color("287d7b")
	if variant==7: fin=Color("176fac")
	if snapper: fin=Color("a35144")
	if grouper: fin=Color("746d43")
	if variant==6: fin=Color("c6b343")
	if variant==3:
		dorsal_ribbon(.10,.91,.13,false,fin)
	elif grouper or snapper:
		dorsal_ribbon(.26,.85,.12,true,fin)
	elif variant==4:
		dorsal_ribbon(.23,.59,.10,true,fin)
	else:
		var t=.43 if variant==13 else .31
		membrane(self,PackedVector2Array([Vector2(-.13,0),Vector2(-.10,.18),Vector2(.03,.12),Vector2(.24,0)]),"yz",Vector3(0,profile(t).y,lerpf(-1.13,1.02,t)),fin)
	if not grouper and not snapper and variant!=3:
		var t=.74 if variant==13 else .61
		var sweep=.42 if variant==0 else (.27 if trevally else .17)
		var points=PackedVector2Array([Vector2(0,0),Vector2(.025,sweep),Vector2(.09,sweep*.68),Vector2(.15,.08),Vector2(.34,-.025)])
		membrane(self,points,"yz",Vector3(0,profile(t).y,lerpf(-1.13,1.02,t)),fin)
		var lower=PackedVector2Array()
		for point in points: lower.append(Vector2(point.x,-point.y))
		membrane(self,lower,"yz",Vector3(0,-profile(t).y,lerpf(-1.13,1.02,t)),fin)
	else:
		membrane(self,PackedVector2Array([Vector2(0,0),Vector2(.06,-.13),Vector2(.27,-.11),Vector2(.40,0)]),"yz",Vector3(0,-profile(.66).y,.29),fin)
	for side in [-1,1]:
		var reach=.57 if trevally or variant==0 else (.25 if grouper else .36)
		membrane(self,PackedVector2Array([Vector2(0,0),Vector2(reach,side*.20),Vector2(reach*.8,side*.07)]),"xz",Vector3(side*profile(.29).x,-.02,-.48),fin)
		if tuna:
			for i in range(7):
				var t=.74+float(i)*.032
				membrane(self,PackedVector2Array([Vector2(0,0),Vector2(.025,side*.055),Vector2(.06,0)]),"yz",Vector3(0,side*profile(t).y,lerpf(-1.13,1.02,t)),fin)
		if trevally:
			for i in range(10):
				var t=.72+i*.022
				Art.oval(self,Vector3(side*profile(t).x,0,lerpf(-1.13,1.02,t)),Vector3(.009,.019,.025),Color("a0acaa"))
	tail=Node3D.new()
	tail.name="CaudalFin"
	add_child(tail)
	tail.position.z=1.0
	var spread=.42 if tuna else .38
	var shape=PackedVector2Array([Vector2(0,-.035),Vector2(.38,-spread),Vector2(.30,-spread*.6),Vector2(.12,0),Vector2(.30,spread*.6),Vector2(.38,spread),Vector2(0,.035)])
	if grouper:
		shape=PackedVector2Array([Vector2(0,-.04),Vector2(.22,-.23),Vector2(.34,-.18),Vector2(.39,0),Vector2(.34,.18),Vector2(.22,.23),Vector2(0,.04)])
	elif snapper:
		shape=PackedVector2Array([Vector2(0,-.04),Vector2(.33,-.28),Vector2(.22,0),Vector2(.33,.28),Vector2(0,.04)])
	membrane(tail,shape,"yz",Vector3.ZERO,fin)

func build_face() -> void:
	var shape = profile(0.14)
	var warm=variant in [5,10,11,12]
	var cheek=Color("a39a70") if warm else Color("92a9aa")
	for side in [-1,1]:
		# Three-dimensional operculum with a curved trailing edge.
		var eye_at = Vector3(side*(shape.x*sqrt(maxf(.25,1-pow(.06/shape.y,2)))+0.009),0.06,-0.83)
		Art.oval(self,eye_at,Vector3(0.048,0.092,0.092),Color("817348") if warm else Color("bac9be"))
		var eye=Art.oval(self,eye_at+Vector3(side*0.015,0,0),Vector3(0.04,0.066,0.066),Color("0a151b"))
		var wet=eye.material_override as StandardMaterial3D
		wet.roughness=.06
		wet.metallic=.1
		Art.oval(self,eye_at+Vector3(side*0.033,0.013,-0.012),Vector3(0.009,0.017,0.017),Color("f5ffff"))
		var previous = Vector3(side*profile(.24).x*.48,.23,-.55)
		for i in range(1,16):
			var fraction=float(i)/15
			var point=Vector3(side*profile(.24).x*sqrt(maxf(.15,1-pow((.23-fraction*.44)/profile(.24).y,2)))*1.01,.23-fraction*.44,-.55+sin(fraction*PI)*.10)
			Art.pole(self,previous,point,.0025,cheek.darkened(.43))
			previous=point
		# Nostril and a recessed mouth corner rather than a pointed closed nose.
		Art.oval(self,Vector3(side*.083,.05,-1.035),Vector3(.004,.006,.009),Color("283b3b"))
		Art.pole(self,Vector3(side*.035,-.035,-1.13),Vector3(side*.11,-.06,-.98),.003,Color("243b3b"))
	var mouth=Art.oval(self,Vector3(0,-.032,-1.128),Vector3(.075,.025,.013),Color("273d3d"))
	mouth.name="Mouth"
	Art.oval(self,Vector3(0,-.064,-1.09),Vector3(.14 if variant in [11,12,13] else .10,.035,.14 if variant in [11,12,13] else .10),cheek.lightened(.12))

func _process(delta: float) -> void:
	phase += delta*swim_intensity
	if is_visible_in_tree() and tail:
		tail.rotation.y = sin(phase*4.5)*(0.13+0.04*swim_intensity)
