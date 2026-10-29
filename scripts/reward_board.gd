extends RefCounted
## Read-only projection of existing reward services. Claims still use main.gd.
static func entries(game: Node3D) -> Array[Dictionary]:
 var rows: Array[Dictionary]=[]
 var jobs=game.daily_requests.offers()
 for i in range(jobs.size()):
  var job=jobs[i]
  rows.append({"id":"daily_"+str(i),"kind":"daily","index":i,"title":job.name,"icon":"sun","mvr":job.mvr,"xp":job.xp,"ready":game.daily_requests.ready(i),"claimed":game.daily_requests.claimed[i],"current":game.daily_requests.counts[i],"goal":job.goal,"where":"Claim anywhere","destination":"Daily"})
 var challenge=game.spot_challenges
 if not challenge.result.is_empty() and challenge.result.success:
  var prize=challenge.preview_reward()
  rows.append({"id":"spot","kind":"spot","title":challenge.definition(challenge.result.id).name,"icon":"trophy","mvr":prize.mvr,"xp":prize.xp,"ready":true,"claimed":false,"current":1,"goal":1,"where":"Claim anywhere","destination":"Spots"})
 var port=game.harbour_for_rewards()
 var progress=game.trip_progress
 if not progress.active.is_empty():
  var job=progress.active
  rows.append({"id":"contract","kind":"contract","title":"Harbour delivery","icon":"contract","mvr":job.reward,"xp":60,"ready":progress.ready() and port==job.island,"claimed":false,"current":job.count,"goal":job.goal,"where":"Claim at "+job.island,"destination":"Contracts"})
 progress.refresh_week()
 rows.append({"id":"weekly","kind":"weekly","title":"Weekly ocean challenge","icon":"calendar","mvr":300,"xp":120,"ready":progress.weekly_ready() and not port.is_empty(),"claimed":progress.weekly.claimed,"current":mini(progress.weekly.count,10),"goal":10,"where":"10 fish · 3 species · claim at a harbour","destination":"Weekly"})
 return rows
static func overview(game: Node3D) -> Dictionary:
 var count=0;var mvr=0;var xp=0
 for row in entries(game):
  if row.ready:count+=1;mvr+=int(row.mvr);xp+=int(row.xp)
 return {"count":count,"mvr":mvr,"xp":xp}
