extends RefCounted
const World=preload("res://scripts/world_data.gd")
const BADGES=[{"id":"none","name":"No badge","need":0},{"id":"captain","name":"First captain","need":1},{"id":"reef","name":"Reef regular","need":15},{"id":"ocean","name":"Ocean veteran","need":50}]
var names: Dictionary={}
var badges: Dictionary={}
func clean_name(value: String) -> String:
 var result=""
 for character in value.strip_edges():
  if character.unicode_at(0)>=32 and character not in ["[","]","<",">"]:result+=character
 return result.left(22).strip_edges()
func rename(id: String,value: String) -> bool:
 if World.vessel(id).id!=id:return false
 var cleaned=clean_name(value)
 if cleaned.is_empty():names.erase(id)
 else:names[id]=cleaned
 return true
func title(id: String) -> String:return str(names.get(id,World.vessel(id).name))
func choose(id: String,badge: String,catches: int) -> bool:
 if World.vessel(id).id!=id:return false
 for entry in BADGES:
  if entry.id==badge and catches>=entry.need:badges[id]=badge;return true
 return false
func badge(id: String,catches: int) -> Dictionary:
 for entry in BADGES:
  if entry.id==badges.get(id,"none") and catches>=entry.need:return entry
 return BADGES[0]
func snapshot() -> Dictionary:return {"names":names.duplicate(),"badges":badges.duplicate()}
func restore(data: Variant,catches: int):
 names.clear();badges.clear()
 if not data is Dictionary:return
 if data.get("names") is Dictionary:
  for id in data.names:rename(str(id),str(data.names[id]))
 if data.get("badges") is Dictionary:
  for id in data.badges:choose(str(id),str(data.badges[id]),catches)
