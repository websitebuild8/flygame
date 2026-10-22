extends RefCounted
const ISLANDS = [
 {"name":"HA. Kelaa","at":Vector2(-25,30),"radius":19.0},
 {"name":"HA. Filladhoo","at":Vector2(85,-80),"radius":24.0},
 {"name":"HA. Vashafaru","at":Vector2(-22,-125),"radius":22.0},
 {"name":"HA. Dhidhdhoo","at":Vector2(-130,110),"radius":18.0},
 {"name":"HA. Baarah","at":Vector2(115,65),"radius":18.0}
]
# Only species with imported textured models are currently catchable.
const FISH = [
 {"name":"Yellowfin tuna","min":2.0,"max":16.0,"value":65,"fight":1.1},
 {"name":"Giant trevally","min":2.0,"max":14.0,"value":60,"fight":1.12}
]
const SPOTS = [
 {"id":"lagoon","name":"Kelaa Lagoon","at":Vector2(0,-45),"unlock":0,"fish":[0,1]},
 {"id":"reef","name":"Kelaa Outer Reef","at":Vector2(-80,-60),"unlock":0,"fish":[0,1]},
 {"id":"channel","name":"Vashafaru Channel","at":Vector2(25,-100),"unlock":0,"fish":[0,1]},
 {"id":"east","name":"Filladhoo Dropoff","at":Vector2(125,-45),"unlock":3,"fish":[0,1]},
 {"id":"bluewater","name":"Haa Alif Bluewater","at":Vector2(150,-150),"unlock":6,"fish":[0,1]},
 {"id":"night","name":"Baarah Drift","at":Vector2(15,120),"unlock":0,"fish":[0,1]},
 {"id":"sunset","name":"Dhidhdhoo Reef","at":Vector2(-165,65),"unlock":4,"fish":[0,1]}
]
const BOATS = [
 {"id":"dinghy","name":"Island Dinghy","price":0,"unlock":0,"speed":12.5,"handling":1.0,"accel":1.0,"storage":10,"detail":"Classic mint helm · light and easy to handle"},
 {"id":"skiff","name":"Reef Skiff","price":600,"unlock":3,"speed":18.0,"handling":1.15,"accel":1.15,"storage":14,"detail":"White sport wheel · blue throttle · nimble handling"},
 {"id":"runner","name":"Atoll Runner","price":1400,"unlock":8,"speed":24.0,"handling":0.95,"accel":1.3,"storage":18,"detail":"Carbon sport helm · amber controls · T-top canopy"},
 {"id":"launch","name":"Ocean Launch","price":2800,"unlock":15,"speed":30.0,"handling":0.8,"accel":1.45,"storage":24,"detail":"Wood and brass wheel · twin throttle · cabin canopy"}
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
static func water(point: Vector2, unlocked: bool, margin: float = 4.0) -> bool:
	if point.length()>245 or (not unlocked and point.x>45):
		return false
	for island in ISLANDS:
		if point.distance_to(island.at)<island.radius+margin:
			return false
	return true

static func has_fish_model(species: String) -> bool:
	for entry in FISH:
		if entry.name==species:
			return true
	return false
