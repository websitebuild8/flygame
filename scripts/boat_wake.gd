extends Node3D
## Small pooled prop wash patches: stern sources stay fixed for forward AND reverse.
var pieces: Array[MeshInstance3D]=[]
var ages: Array[float]=[]
var velocities: Array[Vector3]=[]
var timer=0.0
var cursor=0
var emitted_origins: Array[Vector3]=[]
static var foam: Texture2D
func _ready():
 if not foam:
  var image=Image.create(64,64,false,Image.FORMAT_RGBA8)
  for y in range(64):
   for x in range(64):
    var p=(Vector2(x,y)-Vector2(31.5,31.5))/31.5
    var edge=pow(maxf(0,1-p.length_squared()),1.8)
    var flecks=.35+.65*pow(.5+.5*sin(x*1.8+sin(y*.6)*2.0)*sin(y*1.5+x*.3),2)
    image.set_pixel(x,y,Color(.81,.94,.93,edge*flecks))
  foam=ImageTexture.create_from_image(image)
 for i in range(22):
  var node=MeshInstance3D.new();var mesh=QuadMesh.new();mesh.size=Vector2(.14,.24);node.mesh=mesh;node.rotation.x=-PI/2
  var material=StandardMaterial3D.new();material.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;material.albedo_texture=foam;material.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
  node.material_override=material;node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;node.visible=false;add_child(node)
  pieces.append(node);ages.append(5.0);velocities.append(Vector3.ZERO)
func update_wake(delta: float,at: Vector3,stern: Vector3,speed: float,origins: Array[Vector3]=[],thrust: float=0,gear: int=0) -> void:
 timer-=delta
 emitted_origins.clear()
 if thrust>.12 and gear!=0 and timer<=0:
  timer=lerpf(.18,.08,clampf(thrust,0,1))
  if origins.is_empty():origins.append(at+stern*.8)
  for origin in origins:
   var node=pieces[cursor]
   # Gear reverses the water jet, never its point of origin.
   node.position=origin+stern*.025
   node.position.y=get_parent().surface.height(Vector2(origin.x,origin.z))+.008
   node.rotation.y=atan2(stern.x,stern.z)
   ages[cursor]=0;velocities[cursor]=stern*float(gear)*(.24+thrust*.65)
   emitted_origins.append(node.position)
   cursor=(cursor+1)%pieces.size()
 for i in range(pieces.size()):
  ages[i]+=delta;var age=ages[i];pieces[i].visible=age<1.25
  if age<1.25:
   pieces[i].position+=velocities[i]*delta
   pieces[i].position.y=get_parent().surface.height(Vector2(pieces[i].position.x,pieces[i].position.z))+.008
   pieces[i].scale=Vector3(1+age*2.5,1+age*3.0,1)
   (pieces[i].material_override as StandardMaterial3D).albedo_color=Color(1,1,1,(1-age/1.25)*.55)
