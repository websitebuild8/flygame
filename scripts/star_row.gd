extends Control
var stars=0:
 set(value):stars=clampi(value,0,3);queue_redraw()
func _ready():custom_minimum_size=Vector2(112,38);mouse_filter=Control.MOUSE_FILTER_IGNORE
func _draw():
 for index in range(3):
  var points=PackedVector2Array();var center=Vector2(18+index*36,19)
  for vertex in range(10):
   var angle=-PI/2+vertex*PI/5;points.append(center+Vector2(cos(angle),sin(angle))*(15 if vertex%2==0 else 6.6))
  draw_colored_polygon(points,Color("edba51") if index<stars else Color("ced8d0"));points.append(points[0]);draw_polyline(points,Color("a47128") if index<stars else Color("94aaa1"),1.5,true)
