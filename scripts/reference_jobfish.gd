extends "res://scripts/reference_fish.gd"
## Owner-authorized rusty jobfish; shares playback behavior without loading the tuna model.
const JOB_MODEL=preload("res://assets/models/reference/rusty_jobfish.glb")
# Envelope measured from the actual skinned swim, pull and display poses.
const JOB_BOUNDS=AABB(Vector3(-1.12,-.60,-1.045),Vector3(2.24,1.20,2.13))
func source_scene() -> PackedScene:return JOB_MODEL
func configure_model_space() -> void:
 model_space.rotation.y=PI
 model_space.scale=Vector3.ONE*2.2
 model_space.position=Vector3.ZERO
func canonical_bounds() -> AABB:return JOB_BOUNDS
