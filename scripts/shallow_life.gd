extends RefCounted
## Cheap underwater fish silhouettes are composed into the water, not depth-disabled 3D meshes.
const World=preload("res://scripts/world_data.gd")
var anchors: Array[Vector2]=[]
var selected=Vector2.ZERO
var selected_valid=false
var choose_tick=1.0
var values=PackedVector4Array()
var depth_image: Image
func _init():
 depth_image=load("res://assets/maps/ocean/coastal_depth.png").get_image()
 if depth_image.is_compressed():depth_image.decompress()
 values.resize(8)
 for port in World.Harbours.all_ports():anchors.append(port.dock-port.inward*2+port.along*2.5)
 for island in World.ISLANDS:
  var coast=World.outline(island)
  for index in range(0,coast.size(),16):
   var next=coast[(index+1)%coast.size()];var direction=(next-coast[index]).normalized();var side=Vector2(-direction.y,direction.x)
   for sign_value in [-1,1]:
    var at=coast[index]+side*4*sign_value
    if World.water(at,true,.5):anchors.append(at);break
func sample(at: Vector2) -> Color:
 var uv=(at+Vector2.ONE*700)/1400
 return depth_image.get_pixel(clampi(int(uv.x*512),0,511),clampi(int(uv.y*512),0,511))
func update(delta: float,eye: Vector3,clock: float,water: ShaderMaterial,quality: int) -> void:
 choose_tick+=delta
 var at=Vector2(eye.x,eye.z)
 if choose_tick>=.2:
  choose_tick=0;var best=35.0*35;selected_valid=false
  for anchor in anchors:
   if at.distance_squared_to(anchor)<best:best=at.distance_squared_to(anchor);selected=anchor;selected_valid=true
 for i in range(8):
  var angle=clock*(.19+float(i%3)*.025)+float(i)*1.4
  var radius=.8+float(i%4)*.34
  var point=selected+Vector2(cos(angle)*radius,sin(angle)*radius*.65)
  var color=sample(point)
  var visible_fish=selected_valid and i<[3,5,8][quality] and color.b>.5 and color.r<.6
  values[i]=Vector4(point.x,point.y,atan2(cos(angle)*.65,-sin(angle)),1 if visible_fish else 0)
 water.set_shader_parameter("shoal_fish",values)
