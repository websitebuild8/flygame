extends "res://scripts/reference_fish.gd"
## Owner-authorized reference tuna, adapted to the game's -Z forward fish frame.
const MODEL=preload("res://assets/models/reference/yellowfin.glb")
const BOUNDS=AABB(Vector3(-.61,-.61,-1.0),Vector3(1.22,1.22,2.27))
func source_scene() -> PackedScene:return MODEL
func configure_model_space() -> void:
 model_space.scale=Vector3.ONE*1.1
 model_space.position=Vector3(0,-.0677,-.25385)
func canonical_bounds() -> AABB:return BOUNDS
