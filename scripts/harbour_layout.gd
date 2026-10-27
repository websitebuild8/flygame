extends RefCounted
## A widened game-scale basin cut into Kelaa, with one navigable western entrance.
const BASIN=Rect2(-10,2,33,28)
const HOME=Vector2(17,16)
const ENTRANCE=Vector2(-10,17)
const WALLS=[
 [Vector2(-10,2),Vector2(23,2)],
 [Vector2(-10,30),Vector2(23,30)],
 [Vector2(-10,2),Vector2(-10,11)],
 [Vector2(-10,23),Vector2(-10,30)],
 [Vector2(23,2),Vector2(23,30)]
]
static func contains(at: Vector2) -> bool:return BASIN.has_point(at)
static func at_berth(at: Vector2) -> bool:return contains(at) and at.distance_to(HOME)<9
static func polygon() -> PackedVector2Array:
 return PackedVector2Array([BASIN.position,Vector2(BASIN.end.x,BASIN.position.y),BASIN.end,Vector2(BASIN.position.x,BASIN.end.y)])
