extends RefCounted
## Offline catch journal, market delivery contracts and optional weekly goals.
const World=preload("res://scripts/world_data.gd")
var records: Dictionary={}
var active: Dictionary={}
var completed=0
var weekly: Dictionary={}
func week_key(now: float) -> int:return floori((now+259200)/604800)
func refresh_week(now: float=-1):
 if now<0:now=Time.get_unix_time_from_system()
 var key=week_key(now)
 if int(weekly.get("id",-1))!=key:weekly={"id":key,"count":0,"species":[],"claimed":false}
func record_catch(item: Dictionary,spot: String="",count_week: bool=true) -> Dictionary:
 var species=str(item.get("species",""))
 if not World.has_fish_model(species):return {"new_species":false,"record":false}
 var weight=clampf(float(item.get("weight",0)),0,10000)
 if not is_finite(weight) or weight<=0:return {"new_species":false,"record":false}
 var fresh=not records.has(species)
 var row=records.get(species,{"count":0,"weight":0.0,"best":0.0,"value":0,"spot":""})
 var best=weight>float(row.best)+.049
 row.count=int(row.count)+1;row.weight=snappedf(float(row.weight)+weight,.1)
 if best:row.best=weight;row.spot=spot
 row.value=maxi(int(row.value),int(item.get("value",0)));records[species]=row
 if count_week:
  refresh_week();weekly.count=int(weekly.count)+1
  if species not in weekly.species:weekly.species.append(species)
 return {"new_species":fresh,"record":best and not fresh}
func offers() -> Array[Dictionary]:
 var result: Array[Dictionary]=[]
 # Early contracts use species available in the starting waters.
 var pool=["Skipjack tuna","Yellowfin tuna","Giant trevally"]
 if completed>=3:pool.append("Mahi-mahi")
 if completed>=6:pool.append("Sailfish")
 for i in range(3):
  var species=pool[(completed+i)%pool.size()];var count=2+(completed+i)%2
  var kg=(8.0 if count==3 else 4.0)+minf(completed*.5,4)
  if species=="Sailfish":kg=16.0
  result.append({"id":"%d_%d"%[completed,i],"species":species,"goal":count,"kg":kg,"reward":110+i*30+mini(completed,8)*15})
 return result
func accept(id: String,island: String) -> bool:
 if not active.is_empty():return false
 var valid=false
 for port in World.Harbours.all_ports():
  if port.name==island:valid=true
 if not valid:return false
 for offer in offers():
  if offer.id==id:
   active=offer.duplicate();active["island"]=island;active["count"]=0;active["weight"]=0.0;return true
 return false
func deliver(item: Dictionary,island: String):
 if active.is_empty() or ready() or island!=active.island or item.get("species","")!=active.species:return
 var weight=float(item.get("weight",0))
 if not is_finite(weight) or weight<=0:return
 active.count=int(active.count)+1;active.weight=snappedf(float(active.weight)+weight,.1)
func ready() -> bool:
 return not active.is_empty() and int(active.get("count",0))>=int(active.goal) and float(active.get("weight",0))+.001>=float(active.kg)
func claim(island: String) -> int:
 if not ready() or island!=active.island:return 0
 var reward=int(active.reward);active={};completed+=1;return reward
func weekly_ready() -> bool:
 refresh_week();return int(weekly.count)>=10 and weekly.species.size()>=3 and not weekly.claimed
func claim_weekly() -> int:
 if not weekly_ready():return 0
 weekly.claimed=true;return 300
func mastery(species: String) -> String:
 var count=int(records.get(species,{}).get("count",0))
 return "Master angler" if count>=15 else ("Skilled angler" if count>=5 else ("Discovered" if count>0 else "Undiscovered"))
func snapshot() -> Dictionary:
 refresh_week();return {"version":1,"records":records.duplicate(true),"active":active.duplicate(true),"completed":completed,"weekly":weekly.duplicate(true)}
func restore(data: Variant):
 records={};active={};completed=0;weekly={}
 if not data is Dictionary:return
 completed=clampi(int(data.get("completed",0)),0,100000)
 var saved=data.get("records",{})
 if saved is Dictionary:
  for species in saved:
   var row=saved[species]
   if not World.has_fish_model(str(species)) or not row is Dictionary:continue
   var best=float(row.get("best",0));var total=float(row.get("weight",0))
   if not is_finite(best) or not is_finite(total):continue
   records[species]={"count":clampi(int(row.get("count",0)),1,10000000),"best":clampf(best,0,10000),"weight":clampf(total,0,100000000),"value":clampi(int(row.get("value",0)),0,10000000),"spot":str(row.get("spot","")).left(80)}
 var job=data.get("active",{})
 if job is Dictionary and World.has_fish_model(str(job.get("species",""))):
  var kg=float(job.get("kg",0));var weight=float(job.get("weight",0))
  if is_finite(kg) and is_finite(weight) and kg>0:
   for port in World.Harbours.all_ports():
    if port.name==job.get("island",""):
     active={"id":str(job.get("id","")),"species":str(job.species),"goal":clampi(int(job.get("goal",2)),1,20),"kg":clampf(kg,1,200),"reward":clampi(int(job.get("reward",0)),0,500),"island":port.name,"count":clampi(int(job.get("count",0)),0,1000),"weight":clampf(weight,0,10000)}
 var week=data.get("weekly",{})
 if week is Dictionary:
  var species: Array=[]
  if week.get("species",[]) is Array:
   for entry in week.get("species",[]):
    if World.has_fish_model(str(entry)) and entry not in species:species.append(str(entry))
  weekly={"id":int(week.get("id",-1)),"count":clampi(int(week.get("count",0)),0,1000000),"species":species,"claimed":bool(week.get("claimed",false))}
 refresh_week()
