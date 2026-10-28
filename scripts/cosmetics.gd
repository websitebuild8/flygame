extends RefCounted
## Permanent cosmetic finishes. Paid ownership is never accepted from the ordinary trip save.
const STYLES=[
 {"id":"original","name":"Original","color":Color("ffffff"),"accent":Color("ffffff"),"premium":false},
 {"id":"lagoon","name":"Lagoon blue","color":Color("1785a5"),"accent":Color("b8e4df"),"premium":false},
 {"id":"seafoam","name":"Seafoam","color":Color("439c87"),"accent":Color("e1e8cd"),"premium":false},
 {"id":"coral","name":"Sunset coral","color":Color("cf6552"),"accent":Color("ffe0a3"),"premium":true},
 {"id":"pearl","name":"Pearl edition","color":Color("e5e2d0"),"accent":Color("55b7b8"),"premium":true},
 {"id":"reef_bronze","name":"Reef bronze","color":Color("a57149"),"accent":Color("efc994"),"premium":false,"unlock_level":5,"pattern":true},
 {"id":"atoll_silver","name":"Atoll silver","color":Color("9fbfc3"),"accent":Color("325b76"),"premium":false,"unlock_level":10,"pattern":true},
 {"id":"ocean_gold","name":"Ocean gold","color":Color("c7a251"),"accent":Color("174f5b"),"premium":false,"unlock_level":15,"pattern":true},
 {"id":"captain_teal","name":"Captain’s teal","color":Color("176f79"),"accent":Color("f3d5a1"),"premium":false,"catch_unlock":10,"boat_only":true,"pattern":true},
 {"id":"ocean_racer","name":"Ocean racer","color":Color("344995"),"accent":Color("e99d4b"),"premium":false,"catch_unlock":30,"boat_only":true,"pattern":true},
 {"id":"midnight","name":"Midnight gold","color":Color("172d43"),"accent":Color("d6ae55"),"premium":true}
]
var angler_level=1
var lifetime_catches=0
var equipped: Dictionary={}
func style(id: String) -> Dictionary:
 for entry in STYLES:
  if entry.id==id:return entry
 return STYLES[0]
func can_use(id: String) -> bool:
 # The store integration is not configured yet. Premium designs remain preview-only.
 return not style(id).premium and angler_level>=int(style(id).get("unlock_level",1)) and lifetime_catches>=int(style(id).get("catch_unlock",0))
func choose(item: String,id: String) -> bool:
 if not can_use(id) or style(id).id!=id:return false
 if style(id).get("boat_only",false) and preload("res://scripts/gear_catalog.gd").item(item).get("category","")!="Boats":return false
 equipped[item]=id;return true
func selected(item: String) -> String:return str(equipped.get(item,"original"))
func snapshot() -> Dictionary:return equipped.duplicate()
func restore(data: Variant):
 equipped.clear()
 if not data is Dictionary:return
 var catalog=preload("res://scripts/gear_catalog.gd")
 for item in data:
  if catalog.item(str(item)).get("category","") in ["Rods","Reels","Boats"]:choose(str(item),str(data[item]))
