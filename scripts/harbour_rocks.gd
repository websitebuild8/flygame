extends Node3D
## Instanced CC0 photogrammetry armour stone, grouped spatially for mobile culling.
const MODEL=preload("res://assets/models/harbour/armour_rock.glb")
static var shared_mesh: ArrayMesh
static var shared_material: ShaderMaterial
var groups: Array[MultiMeshInstance3D]=[]
var rock_count=0
func _ready():name="ArmourStone";add_to_group("harbour_rock_groups")
static func mesh() -> ArrayMesh:
 if not shared_mesh:
  var source=MODEL.instantiate();var part=source.find_children("*","MeshInstance3D",true,false)[0]
  shared_mesh=part.mesh
  var original=part.get_active_material(0) as StandardMaterial3D
  shared_material=ShaderMaterial.new();shared_material.shader=preload("res://shaders/harbour_rock.gdshader")
  shared_material.set_shader_parameter("stone_color",original.albedo_texture);shared_material.set_shader_parameter("stone_normal",original.normal_texture)
  source.free()
 return shared_mesh
func configure(port: Dictionary):
 var rock=mesh();var bounds=rock.get_aabb();var center=bounds.get_center();var length=bounds.size[bounds.get_longest_axis_index()]
 var rng=RandomNumberGenerator.new();rng.seed=hash(port.name)+9245
 var batches={}
 for wall_index in range(4):
  var wall=port.walls[wall_index];var a=wall[0];var b=wall[1];var direction=(b-a).normalized();var outward=Vector2(-direction.y,direction.x)
  if Geometry2D.is_point_in_polygon((a+b)*.5+outward,port.polygon):outward=-outward
  var count=maxi(1,int(a.distance_to(b)/.85))
  for i in range(count):
   for row in range(2):
    var p=a.lerp(b,(float(i)+.5)/count)+direction*rng.randf_range(-.12,.12)+outward*((.66 if row==0 else 1.08)+rng.randf_range(-.13,.13))
    var width=rng.randf_range(.90,1.12) if row==0 else rng.randf_range(1.1,1.35)
    var shape=Vector3(width,rng.randf_range(.85,1.1)*width,width*rng.randf_range(.8,1.1))/length
    var basis=Basis.from_euler(Vector3(rng.randf_range(-.3,.3),rng.randf_range(-PI,PI),rng.randf_range(-.25,.25))).scaled(shape)
    var at=Vector3(p.x,(-.14 if row==0 else -.45)+rng.randf_range(-.06,.06),p.y)
    var key=Vector2i(floori(p.x/24),floori(p.y/24))
    if not batches.has(key):batches[key]=[]
    var origin=Vector3(key.x*24,0,key.y*24)
    var tint=rng.randf_range(.80,1.0)
    batches[key].append({"transform":Transform3D(basis,at-origin-basis*center),"color":Color(tint,tint*.99,tint*.97)})
    rock_count+=1
 for key in batches:
  var entries=batches[key];var ordered=[]
  # Low quality keeps a spatially distributed subset, rather than removing a whole wall.
  for parity in range(2):
   for i in range(parity,entries.size(),2):ordered.append(entries[i])
  var node=MultiMeshInstance3D.new();node.name="RockArmourChunk";add_child(node)
  node.position=Vector3(key.x*24,0,key.y*24);node.material_override=shared_material
  node.multimesh=MultiMesh.new();node.multimesh.transform_format=MultiMesh.TRANSFORM_3D;node.multimesh.use_colors=true;node.multimesh.mesh=rock;node.multimesh.instance_count=ordered.size()
  for i in range(ordered.size()):node.multimesh.set_instance_transform(i,ordered[i].transform);node.multimesh.set_instance_color(i,ordered[i].color)
  node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;groups.append(node)
 apply_quality(0)
func apply_quality(quality: int):
 for node in groups:
  node.visibility_range_end=[95.0,135.0,180.0][quality]
  node.multimesh.visible_instance_count=ceili(node.multimesh.instance_count*[.55,.80,1.0][quality])
