extends Node3D
## Pooled, opaque, unshadowed sea life. No new textures, particles or physics bodies.
const World=preload("res://scripts/world_data.gd")
var birds: Array[MeshInstance3D]=[]
var rings: Array[MeshInstance3D]=[]
var jumper: MeshInstance3D
var clock=0.0
var cooldown=12.0
var jump_age=-1.0
var anchor=Vector3.ZERO
var rng=RandomNumberGenerator.new()
func geometry(vertices: PackedVector3Array,color: Color) -> MeshInstance3D:
 var node=MeshInstance3D.new();var mesh=ArrayMesh.new();var arrays=[];arrays.resize(Mesh.ARRAY_MAX);arrays[Mesh.ARRAY_VERTEX]=vertices;mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays);node.mesh=mesh
 var material=StandardMaterial3D.new();material.albedo_color=color;material.cull_mode=BaseMaterial3D.CULL_DISABLED;material.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;node.material_override=material;node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;add_child(node);return node
func _ready():
 rng.randomize()
 var wing=PackedVector3Array([Vector3(-.5,.08,0),Vector3(0,0,-.08),Vector3(-.12,0,.07),Vector3(.5,.08,0),Vector3(.12,0,.07),Vector3(0,0,-.08)])
 for i in range(6):birds.append(geometry(wing,Color("a4b9c0")))
 jumper=geometry(PackedVector3Array([Vector3(0,0,-.30),Vector3(-.07,0,.10),Vector3(.07,0,.10),Vector3(-.07,0,.10),Vector3(0,0,.20),Vector3(.07,0,.10),Vector3(0,0,.18),Vector3(-.1,0,.30),Vector3(.1,0,.30),Vector3(0,0,0),Vector3(0,.10,.04),Vector3(0,0,.12)]),Color("86b7c1"));jumper.visible=false
 var mesh=TorusMesh.new();mesh.inner_radius=.48;mesh.outer_radius=.50;mesh.rings=20;mesh.ring_segments=4
 var material=StandardMaterial3D.new();material.albedo_color=Color("b4d6d2");material.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
 for i in range(2):
  var ring=MeshInstance3D.new();ring.mesh=mesh;ring.material_override=material;ring.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;add_child(ring);rings.append(ring);ring.visible=false
func update(delta: float,game: Node3D,active: bool):
 visible=active and game.day_cycle.day_amount>.3 and game.day_cycle.roughness<.8
 if not visible:return
 clock+=delta;cooldown-=delta
 var spot=World.nearest(game.boat.position);var nearby=Vector2(game.boat.position.x,game.boat.position.z).distance_to(spot.at)<85
 for i in range(birds.size()):
  var bird=birds[i];bird.visible=nearby and i<[2,4,6][game.graphics_quality]
  if not bird.visible:continue
  var phase=clock*.22+i*1.7;bird.position=Vector3(spot.at.x+cos(phase)*10,5+i*.45+sin(clock*1.2+i)*.4,spot.at.y+sin(phase)*8);bird.rotation.y=-phase;bird.scale.y=.7+sin(clock*5+i)*.6
 if jump_age<0 and cooldown<=0 and nearby and not game.fishing:
  anchor=Vector3(spot.at.x+rng.randf_range(-6,6),0,spot.at.y+rng.randf_range(-6,6))
  if Vector2(anchor.x,anchor.z).distance_to(Vector2(game.boat.position.x,game.boat.position.z))>4 and World.water(Vector2(anchor.x,anchor.z),true,.3):jump_age=0
  cooldown=rng.randf_range(18,32)
 if jump_age<0:return
 jump_age+=delta
 var at=Vector2(anchor.x,anchor.z)
 jumper.visible=jump_age<.9
 jumper.position=anchor+Vector3(jump_age*.7,game.surface.height(at)+sin(clampf(jump_age/.9,0,1)*PI)*.8,jump_age*.5);jumper.rotation=Vector3(-.8+jump_age*1.8,clock,0)
 for i in range(2):
  var age=jump_age-.8-i*.15;rings[i].visible=age>0 and age<1.2
  if rings[i].visible:
   rings[i].position=anchor+Vector3(.63,game.surface.height(at)+.025,.45);rings[i].scale=Vector3.ONE*maxf(.1,age*2)
 if jump_age>2.2:
  jump_age=-1;jumper.visible=false
  for ring in rings:ring.visible=false
