extends RefCounted
## Physical levers hinge around the boat's lateral bearing, not a model-dependent axis.
const TRAVEL=.65
static func apply(lever: Node3D,value: float) -> void:
 var rest=lever.get_meta("rest_basis",Basis.IDENTITY) as Basis
 lever.basis=Basis(Vector3.RIGHT,-clampf(value,-1,1)*TRAVEL)*rest
 lever.set_meta("command",value)
