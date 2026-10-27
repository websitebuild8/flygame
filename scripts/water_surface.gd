extends RefCounted
## Mirrors the ocean vertex shader, including the PlaneMesh triangle interpolation.
const BASE=-.6
const WAVE_SCALE=.22
var phase=0.0
var roughness=0.0
var subdivisions=100
var size=1800.0
var port: Dictionary={}
func vertex_height(at: Vector2) -> float:
 var shelter=1.0
 if not port.is_empty():
  var d=at-port.origin;var u=d.dot(port.inward);var v=d.dot(port.along)
  if u>-port.depth and u<port.land and absf(v)<port.half:shelter=.2
 return BASE+(sin(at.x*.12+phase*1.1)*.08+sin(at.y*.16+phase*.8)*.06)*(1+roughness*3.5)*WAVE_SCALE*shelter
func height(at: Vector2) -> float:
 var cell=size/float(subdivisions+1)
 var grid=(Vector2.ONE*size*.5-at)/cell
 var x=clampf(floorf(grid.x),0,subdivisions);var z=clampf(floorf(grid.y),0,subdivisions)
 var u=clampf(grid.x-x,0,1);var v=clampf(grid.y-z,0,1)
 var a=Vector2(size*.5-x*cell,size*.5-z*cell)
 var h_a=vertex_height(a);var h_b=vertex_height(a-Vector2(cell,0));var h_c=vertex_height(a-Vector2(0,cell))
 if u+v<=1:return h_a+(h_b-h_a)*u+(h_c-h_a)*v
 var h_d=vertex_height(a-Vector2.ONE*cell)
 return h_d+(h_c-h_d)*(1-u)+(h_b-h_d)*(1-v)
func ceiling() -> float:return BASE+.14*(1+roughness*3.5)*WAVE_SCALE
