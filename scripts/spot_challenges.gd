extends RefCounted
const World=preload("res://scripts/world_data.gd")
const DEFINITIONS=[
 {"id":"lagoon","spot":"lagoon","name":"Lagoon starter","count":3,"xp":60,"mvr":80,"silver":4.0,"gold":6.0},
 {"id":"reef","spot":"reef","name":"Trevally tackle","species":"Giant trevally","count":1,"min_weight":5.0,"xp":90,"mvr":110,"silver":8.0,"gold":11.0},
 {"id":"channel","spot":"channel","name":"Channel collector","count":2,"variety":2,"xp":80,"mvr":100,"silver":5.0,"gold":8.0},
 {"id":"east","spot":"east","name":"Mahi moment","species":"Mahi-mahi","count":1,"xp":100,"mvr":130,"silver":7.0,"gold":10.0},
 {"id":"bluewater","spot":"bluewater","name":"Sailfish showdown","species":"Sailfish","count":1,"xp":160,"mvr":250,"silver":18.0,"gold":28.0},
 {"id":"night","spot":"night","name":"After-dark angler","count":2,"night":true,"xp":100,"mvr":130,"silver":4.0,"gold":7.0},
 {"id":"sunset","spot":"sunset","name":"Reef mixed bag","count":2,"kg":12.0,"variety":2,"xp":120,"mvr":160,"silver":16.0,"gold":22.0},
 {"id":"lagoon_timed","spot":"lagoon","name":"Lagoon dash","count":2,"seconds":180,"level":2,"xp":90,"mvr":100},
 {"id":"reef_timed","spot":"reef","name":"Reef rush","count":3,"seconds":300,"level":3,"xp":110,"mvr":130},
 {"id":"channel_timed","spot":"channel","name":"Channel sprint","count":1,"kg":10.0,"seconds":300,"level":4,"xp":130,"mvr":160}
]
var active: Dictionary={}
var result: Dictionary={}
var best: Dictionary={}
func definition(id: String) -> Dictionary:
 for entry in DEFINITIONS:
  if entry.id==id:return entry
 return {}
func spot(id: String) -> Dictionary:
 for entry in World.SPOTS:
  if entry.id==id:return entry
 return {}
func start(id: String,at: String,level: int,hours: float,catches: int) -> bool:
 var entry=definition(id)
 if entry.is_empty() or not active.is_empty() or (not result.is_empty() and result.success):return false
 if entry.spot!=at or level<int(entry.get("level",1)) or catches<int(spot(at).unlock):return false
 if entry.get("night",false) and hours>=6 and hours<18:return false
 active={"id":id,"count":0,"weight":0.0,"species":[],"largest":0.0,"remaining":float(entry.get("seconds",0))};result={};return true
func goal(entry: Dictionary) -> String:
 var parts: Array[String]=[]
 if entry.has("species"):parts.append(entry.species+(" ≥ %.0f kg"%entry.min_weight if entry.has("min_weight") else ""))
 parts.append("%d fish"%int(entry.get("count",1)))
 if entry.has("kg"):parts.append("%.0f kg total"%entry.kg)
 if entry.has("variety"):parts.append("%d species"%entry.variety)
 if entry.get("night",false):parts.append("18:00–06:00")
 return " · ".join(parts)
func ready() -> bool:
 if active.is_empty():return false
 var entry=definition(active.id)
 return active.count>=int(entry.get("count",1)) and active.weight+.001>=float(entry.get("kg",0)) and active.species.size()>=int(entry.get("variety",0))
func record(item: Dictionary,at: String,hours: float):
 if active.is_empty():return
 var entry=definition(active.id)
 if at!=entry.spot:return
 if entry.get("night",false) and hours>=6 and hours<18:return
 var species=str(item.get("species",""));var weight=float(item.get("weight",0))
 if not World.has_fish_model(species) or not is_finite(weight) or weight<=0:return
 if entry.has("species") and entry.species!=species:return
 if weight<float(entry.get("min_weight",0)):return
 active.count+=1;active.weight=snappedf(active.weight+weight,.1);active.largest=maxf(active.largest,weight)
 if species not in active.species:active.species.append(species)
 if ready():finish(true)
func advance(delta: float,at: String):
 if active.is_empty():return
 var entry=definition(active.id)
 if at!=entry.spot:finish(false,"Left the fishing point");return
 if entry.has("seconds"):
  active.remaining=maxf(0,active.remaining-maxf(delta,0))
  if active.remaining<=0:finish(false,"Time’s up")
func finish(success: bool,reason: String=""):
 if active.is_empty():return
 var entry=definition(active.id);var stars=0
 if success:
  stars=1
  var score=active.weight if entry.has("kg") else active.weight/maxf(active.count,1)
  if entry.has("seconds"):
   var fraction=active.remaining/float(entry.seconds);stars=3 if fraction>=.60 else (2 if fraction>=.33 else 1)
  else:stars=3 if score>=float(entry.gold) else (2 if score>=float(entry.silver) else 1)
 result={"id":active.id,"success":success,"stars":stars,"reason":reason,"count":active.count,"weight":active.weight};active={}
func preview_reward() -> Dictionary:
 if result.is_empty() or not result.success:return {"xp":0,"mvr":0}
 var entry=definition(result.id);var old=int(best.get(result.id,0));var stars=int(result.stars)
 return {"xp":int(entry.xp)+(stars-1)*20 if old==0 else 10+maxi(0,stars-old)*20,"mvr":int(entry.mvr) if old==0 else 0}
func claim() -> Dictionary:
 if result.is_empty() or not result.success:return {}
 var prize=preview_reward();prize["id"]=result.id;prize["stars"]=result.stars
 best[result.id]=maxi(int(best.get(result.id,0)),int(result.stars));result={};return prize
func snapshot() -> Dictionary:return {"version":1,"active":active.duplicate(true),"result":result.duplicate(true),"best":best.duplicate()}
func restore(data: Variant):
 active={};result={};best={}
 if not data is Dictionary:return
 var saved=data.get("best",{})
 if saved is Dictionary:
  for id in saved:
   if not definition(str(id)).is_empty():best[id]=clampi(int(saved[id]),1,3)
 var ending=data.get("result",{})
 if ending is Dictionary and not definition(str(ending.get("id",""))).is_empty():
  result={"id":str(ending.id),"success":bool(ending.get("success",false)),"stars":clampi(int(ending.get("stars",1)),1,3) if ending.get("success",false) else 0,"reason":str(ending.get("reason","")).left(80),"count":clampi(int(ending.get("count",0)),0,100),"weight":0.0}
  return
 var session=data.get("active",{})
 if not session is Dictionary:return
 var entry=definition(str(session.get("id","")))
 if entry.is_empty():return
 var weight=float(session.get("weight",0));var largest=float(session.get("largest",0));var remaining=float(session.get("remaining",0))
 if not is_finite(weight) or not is_finite(largest) or not is_finite(remaining):return
 var species: Array=[]
 if session.get("species",[]) is Array:
  for name in session.species:
   if World.has_fish_model(str(name)) and name not in species:species.append(str(name))
 active={"id":entry.id,"count":clampi(int(session.get("count",0)),0,100),"weight":clampf(weight,0,10000),"largest":clampf(largest,0,10000),"remaining":clampf(remaining,0,float(entry.get("seconds",0))),"species":species}
