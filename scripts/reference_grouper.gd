extends "res://scripts/reference_fish.gd"
## Owner-authorized grouper artwork, adapted to the canonical fish/landing frame.
const MODEL=preload("res://assets/models/reference/giant_grouper.glb")
const BOUNDS=AABB(Vector3(-1.12,-.60,-1.05),Vector3(2.24,1.20,2.30))
func source_scene() -> PackedScene:return MODEL
func configure_model_space() -> void:
 model_space.scale=Vector3.ONE*1.65
 model_space.position=Vector3(0,.09,-.14)
func canonical_bounds() -> AABB:return BOUNDS
