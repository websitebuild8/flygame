extends RefCounted
## Matches the length-preserving arc in authored_rod.gdshader.
static func tip(bend: float) -> Vector3:
	return point(Vector3(0,1.229,-2.003),bend)

static func point(vertex: Vector3,bend: float) -> Vector3:
	var base=Vector3(0,-.04,.38)
	var axis=Vector3(0,.47,-.882666).normalized()
	var radial=Vector3(0,-axis.z,axis.y)
	var along=clampf((vertex-base).dot(axis),0,2.7)
	var flex=maxf(along-.675,0)
	var curvature=bend*.95/2.025
	if curvature<=.00001:return vertex
	var angle=curvature*flex
	var center=base+axis*(minf(along,.675)+sin(angle)/curvature)-radial*((1-cos(angle))/curvature)
	return center+Basis(Vector3.RIGHT,-angle)*(vertex-base-axis*along)

static func guides(overhead: bool=false) -> PackedVector3Array:
	# Hole centres measured from the authored ceramic rings, in straight-rod space.
	var base=Vector3(0,-.04,.38)
	var axis=Vector3(0,.47,-.882666).normalized()
	var radial=Vector3(0,-axis.z,axis.y)
	var result=PackedVector3Array()
	for ring in [Vector2(1.06175,-.0312),Vector2(1.602,-.02925),Vector2(2.1487,-.02005),Vector2(2.6969,-.0047)]:
		result.append(base+axis*ring.x+radial*ring.y*(-1 if overhead else 1))
	return result
