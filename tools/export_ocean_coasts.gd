extends SceneTree
## Run before prepare_ocean.py; uses the same carved coasts as navigation/harbours.
func _initialize():
 var World=load("res://scripts/world_data.gd");var islands=[]
 for island in World.ISLANDS:
  var coast=[]
  for p in World.outline(island):coast.append([p.x,p.y])
  var port=World.Harbours.get_port(island.name);var polygon=[]
  for p in port.polygon:polygon.append([p.x,p.y])
  islands.append({"name":island.name,"coast":coast,"harbour":polygon})
 var file=FileAccess.open("res://assets/maps/ocean/coasts.json",FileAccess.WRITE);file.store_string(JSON.stringify(islands));file.close();quit()
