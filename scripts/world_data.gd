extends RefCounted
const Kelaa=preload("res://scripts/kelaa_map_data.gd")
const Neighbours=preload("res://scripts/neighbour_map_data.gd")
const Harbours=preload("res://scripts/island_harbours.gd")
const Harbour=preload("res://scripts/harbour_layout.gd")
const BOAT_SCALE=.22
const BOAT_CLEARANCE=1.3
const NAV_CLEARANCE=2.2
const SEA_RADIUS=650.0
const EAST_UNLOCK=160.0
const CHART_HALF=700.0
const ISLANDS = [
 {"name":"HA. Kelaa","at":Vector2(36.3,59.2),"radius":62.0},
 {"name":"HA. Filladhoo","at":Vector2(260,-230),"radius":50.0},
 {"name":"HA. Vashafaru","at":Vector2(-90,-350),"radius":47.0},
 {"name":"HA. Dhidhdhoo","at":Vector2(-350,210),"radius":45.0},
 {"name":"HA. Baarah","at":Vector2(300,210),"radius":60.0}
]
# Only species with imported textured models are currently catchable.
const FISH = [
 {"name":"Yellowfin tuna","min":2.0,"max":16.0,"value":65,"fight":1.1},
 {"name":"Giant trevally","min":2.0,"max":14.0,"value":60,"fight":1.12},
 {"name":"Skipjack tuna","min":1.5,"max":8.0,"value":35,"fight":0.95},
 {"name":"Sailfish","min":8.0,"max":35.0,"value":90,"fight":1.45},
 {"name":"Mahi-mahi","min":2.0,"max":14.0,"value":55,"fight":1.2}
]
const SPOTS = [
 {"id":"lagoon","name":"Kelaa Lagoon","at":Vector2(0,-45),"unlock":0,"fish":[0,1,2]},
 {"id":"reef","name":"Kelaa Outer Reef","at":Vector2(-80,-60),"unlock":0,"fish":[0,1,2,4]},
 {"id":"channel","name":"Vashafaru Channel","at":Vector2(-90,-260),"unlock":0,"fish":[0,1,2,4]},
 {"id":"east","name":"Filladhoo Dropoff","at":Vector2(330,-190),"unlock":3,"fish":[0,1,2,3,4]},
 {"id":"bluewater","name":"Haa Alif Bluewater","at":Vector2(430,-420),"unlock":6,"fish":[0,2,3,4]},
 {"id":"night","name":"Baarah Drift","at":Vector2(225,245),"unlock":3,"fish":[0,1,2,4]},
 {"id":"sunset","name":"Dhidhdhoo Reef","at":Vector2(-420,160),"unlock":4,"fish":[0,1,2,4]}
]
const BOATS = [
 {"id":"skiff","name":"Scout 17 Centre Console","price":0,"unlock":0,"speed":18.0,"handling":1.15,"accel":1.15,"storage":14,"detail":"Real Scout hull · centre console · single outboard"},
 {"id":"launch","name":"Boston Whaler 285 Conquest","price":2800,"unlock":15,"speed":30.0,"handling":0.8,"accel":1.45,"storage":24,"detail":"Real Boston Whaler hull · cabin helm · twin outboards"},
 {"id":"glacier","name":"Glacier Bay","price":4200,"unlock":22,"speed":31.0,"handling":0.9,"accel":1.5,"storage":30,"detail":"Twin-hull fishing boat · navy canopy · twin outboards"},
 {"id":"grady","name":"Grady-White Freedom 325","price":6000,"unlock":30,"speed":35.0,"handling":0.85,"accel":1.6,"storage":36,"detail":"Blue sport hull · covered helm · twin outboards"}
]
static func vessel(id: String) -> Dictionary:
	for entry in BOATS:
		if entry.id==id:
			return entry
	return BOATS[0]
static func nearest(point: Vector3) -> Dictionary:
	var best = SPOTS[0]
	var distance = INF
	for entry in SPOTS:
		var d = Vector2(point.x,point.z).distance_to(entry.at)
		if d<distance:
			distance=d
			best=entry
	return best
static func water(point: Vector2, unlocked: bool, margin: float = BOAT_CLEARANCE) -> bool:
	if point.length()>SEA_RADIUS or (not unlocked and point.x>EAST_UNLOCK):
		return false
	if Harbours.blocks_walls(point,margin):return false
	for island in ISLANDS:
		if island.name=="HA. Kelaa":
			if Kelaa.blocks_water(point,margin):return false
			continue
		if Neighbours.blocks_water(point,island.name,margin):return false
	return true

static func has_fish_model(species: String) -> bool:
	for entry in FISH:
		if entry.name==species:
			return true
	return false

static func outline(island: Dictionary) -> PackedVector2Array:
	return Kelaa.coast if island.name=="HA. Kelaa" else Neighbours.outline(island.name)
