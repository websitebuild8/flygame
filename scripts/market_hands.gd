extends Node3D
var hands: Node3D
func _ready():
	hands=preload("res://scripts/fishing_hands.gd").new();add_child(hands)
	hands.set_grip_style(false,true)
func update_pose(market: Node3D):
	var left=market.to_global(Vector3(-.46,1.265,.64-market.serve_motion*.42))
	var right=market.to_global(Vector3(lerpf(.48,.12,market.cash_motion),1.265,.65-market.cash_motion*.47))
	var left_frame=market.global_basis*Basis(Vector3.DOWN,Vector3.FORWARD,Vector3.RIGHT)
	var right_frame=market.global_basis*Basis(Vector3.UP,Vector3.FORWARD,Vector3.LEFT)
	hands.pose_helm(left,right,left_frame,right_frame)
