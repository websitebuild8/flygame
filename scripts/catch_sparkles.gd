extends Control
var age=2.0
var enabled=false
func _ready():mouse_filter=Control.MOUSE_FILTER_IGNORE
func _draw():
 if not enabled or age>1.4:return
 var t=clampf(age/1.4,0,1);var center=size*Vector2(.32,.46)
 for i in range(22):
  var angle=i*2.4;var at=center+Vector2.from_angle(angle)*(45+t*(90+i%5*14));at.y+=t*t*60
  var radius=(1-t)*(2+i%3)
  draw_circle(at,radius,Color(Color("f3c779") if i%2 else Color("8bdecb"),1-t))
