extends RefCounted
## Optional UTC calendar jobs. No streaks, entry costs or sold-fish requirements.
const World=preload("res://scripts/world_data.gd")
var day=-1
var high_day=-1
var counts=[0,0,0]
var claimed=[false,false,false]
func refresh(now: float=-1):
 if now<0:now=Time.get_unix_time_from_system()
 var today=floori(now/86400)
 # Rolling the clock backwards cannot reopen claimed jobs.
 if today>high_day:
  day=today;high_day=today;counts=[0,0,0];claimed=[false,false,false]
func offers() -> Array:
 refresh()
 var species=["Skipjack tuna","Yellowfin tuna","Giant trevally"][posmod(day,3)]
 return [{"name":"Today’s catch","species":"","goal":3,"mvr":75,"xp":40,"kind":"fish"},{"name":"Species spotlight","species":species,"goal":2,"mvr":100,"xp":60,"kind":"fish"},{"name":"A fine specimen","species":"","goal":1,"mvr":90,"xp":50,"kind":"large"}]
func record(item: Dictionary):
 var jobs=offers();var weight=float(item.get("weight",0))
 if not World.has_fish_model(str(item.get("species",""))) or not is_finite(weight) or weight<=0:return
 for i in range(3):
  if claimed[i]:continue
  var job=jobs[i]
  if (job.species.is_empty() or job.species==item.species) and (job.kind!="large" or weight>=6):counts[i]=mini(int(counts[i])+1,int(job.goal))
func ready(index: int) -> bool:
 var jobs=offers()
 return index>=0 and index<3 and not claimed[index] and counts[index]>=jobs[index].goal
func claim(index: int) -> Dictionary:
 var jobs=offers()
 if index<0 or index>=3 or claimed[index] or counts[index]<jobs[index].goal:return {}
 claimed[index]=true
 var job=jobs[index];return {"mvr":job.mvr,"xp":job.xp}
func snapshot() -> Dictionary:
 refresh();return {"day":day,"high_day":high_day,"counts":counts.duplicate(),"claimed":claimed.duplicate()}
func restore(data: Variant):
 day=-1;high_day=-1;counts=[0,0,0];claimed=[false,false,false]
 if data is Dictionary:
  day=int(data.get("day",-1));high_day=maxi(day,int(data.get("high_day",day)))
  var saved_counts=data.get("counts",[]);var saved_claimed=data.get("claimed",[])
  if saved_counts is Array and saved_claimed is Array and saved_counts.size()==3 and saved_claimed.size()==3:
   for i in range(3):counts[i]=clampi(int(saved_counts[i]),0,3);claimed[i]=bool(saved_claimed[i])
 refresh()
