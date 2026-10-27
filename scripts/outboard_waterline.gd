extends RefCounted
## Keep the complete propeller disk below the sampled sea, preserving authored engine trim.
static func motors(visual: Node3D) -> Array:
 if visual.has_meta("waterline_motors"):return visual.get_meta("waterline_motors")
 var result=[]
 for motor in visual.find_children("OutboardPivot*","Node3D",true,false):
  var prop=motor.find_child("Propeller*",true,false) as MeshInstance3D
  if not prop:continue
  var bounds=prop.get_aabb();var radius=0.0
  for i in range(8):radius=maxf(radius,bounds.get_endpoint(i).length())
  result.append({"motor":motor,"prop":prop,"rest_y":motor.position.y,"radius":radius*prop.global_basis.get_scale().x})
 visual.set_meta("waterline_motors",result);return result
static func update(visual: Node3D,sea: RefCounted):
 for item in motors(visual):
  var motor=item.motor;var prop=item.prop
  motor.position.y=item.rest_y
  var at=prop.global_position
  var desired=sea.height(Vector2(at.x,at.z))-item.radius-.045
  var excess=maxf(0,at.y-desired)
  motor.position.y-=excess/maxf(.001,motor.get_parent().global_basis.y.y)
static func positions(visual: Node3D) -> Array[Vector3]:
 var result: Array[Vector3]=[]
 for item in motors(visual):result.append(item.prop.global_position)
 return result
