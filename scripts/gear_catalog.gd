extends RefCounted
## Product names identify references; prices/performance are fictional game balance.
const ITEMS = [
 {"id":"island_reel","name":"Island spinning reel","category":"Reels","kind":"spinning","price":0,"retrieve":1.0,"drag":1.0,"detail":"Your reliable starter spinning reel"},
 {"id":"saragosa","name":"Shimano Saragosa SW A","category":"Reels","kind":"spinning","price":180,"retrieve":1.18,"drag":1.15,"detail":"Saltwater spinning · smooth retrieval"},
 {"id":"ocea","name":"Shimano Ocea Jigger","category":"Reels","kind":"overhead","price":320,"retrieve":1.32,"drag":1.3,"detail":"Overhead jigging · pair with a jigging rod"},
 {"id":"fathom","name":"PENN Fathom II Lever Drag","category":"Reels","kind":"overhead","price":260,"retrieve":1.2,"drag":1.24,"detail":"Conventional jigging · lever drag"},
 {"id":"island_rod","name":"Island spinning rod","category":"Rods","kind":"spinning","price":0,"power":1.0,"detail":"Your starter casting rod"},
 {"id":"offshore_rod","name":"Offshore spinning rod","category":"Rods","kind":"spinning","price":140,"power":1.15,"detail":"Reinforced blank · steadier fish control"},
 {"id":"grappler","name":"Shimano Grappler Type J","category":"Rods","kind":"overhead","price":220,"power":1.25,"detail":"Jigging rod · pairs with overhead reels"},
 {"id":"mono","name":"Island nylon mono","category":"Line","kind":"line","price":0,"strength":1.0,"detail":"Your starter line"},
 {"id":"powerpro","name":"PowerPro braid","category":"Line","kind":"line","price":100,"strength":1.2,"detail":"Braided line · more tension headroom"},
 {"id":"engine","name":"Outboard engine upgrade","category":"Boat","kind":"engine","price":100,"detail":"Two stages · higher maximum speed"},
 {"id":"propeller","name":"Performance propeller","category":"Boat","kind":"part","price":180,"detail":"Quicker acceleration · 8% more top speed"},
 {"id":"icebox","name":"Insulated large icebox","category":"Boat","kind":"part","price":160,"detail":"Adds 14 fish to your boat storage"},
 {"id":"dinghy","name":"Island Dinghy","category":"Boats","kind":"boat","price":0,"unlock":0,"detail":"Classic mint helm · starter boat"},
 {"id":"skiff","name":"Reef Skiff","category":"Boats","kind":"boat","price":600,"unlock":3,"detail":"Blue sport helm · 18 m/s base speed · 14 fish"},
 {"id":"runner","name":"Atoll Runner","category":"Boats","kind":"boat","price":1400,"unlock":8,"detail":"Carbon racing helm · 24 m/s base speed · 18 fish"},
 {"id":"launch","name":"Ocean Launch","category":"Boats","kind":"boat","price":2800,"unlock":15,"detail":"Wood helm · twin throttle · 30 m/s base speed"}
]
const STARTERS = ["island_reel","island_rod","mono"]

static func item(id: String) -> Dictionary:
	for entry in ITEMS:
		if entry.id==id:
			return entry
	return {}
