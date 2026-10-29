extends RefCounted
## Authored game balance, not a forecast or a scientific fish distribution model.
const World=preload("res://scripts/world_data.gd")
const LURES=["Silver baitfish","Reef flash","Bluewater skirt"]
const DEPTHS=["Surface · 2 m","Midwater · 12 m","Deep · 25 m"]
const HABITS={
 "Yellowfin tuna":{"lure":0,"depth":1,"hours":"Dawn / dusk","habitat":"Channels and offshore water","weather":"Cloudy","dawn":true,"cloud":true},
 "Giant trevally":{"lure":1,"depth":2,"hours":"Dusk / night","habitat":"Reef edges and drop-offs","weather":"Cloudy / showers","night":true,"cloud":true},
 "Skipjack tuna":{"lure":0,"depth":0,"hours":"Daylight","habitat":"Lagoon approaches and channels","weather":"Sunny","day":true},
 "Sailfish":{"lure":2,"depth":0,"hours":"Daylight","habitat":"Offshore bluewater","weather":"Sunny","day":true},
 "Mahi-mahi":{"lure":2,"depth":1,"hours":"Dawn / dusk","habitat":"Outer reefs and offshore drifts","weather":"Cloudy","dawn":true,"cloud":true},
 "Rusty jobfish":{"lure":1,"depth":2,"hours":"Dawn / dusk","habitat":"Deep reef slopes and drop-offs","weather":"Cloudy","dawn":true,"cloud":true},
 "Giant grouper":{"lure":1,"depth":2,"hours":"Dusk / night","habitat":"Deep reef ledges and drop-offs","weather":"Cloudy / showers","night":true,"cloud":true}
}
var lure=0
var depth=1
func weight(species: String,hours: float,weather: int,overhead: bool=false) -> float:
 var habit=HABITS[species];var result=1.0
 if lure==habit.lure:result*=2.1
 if depth==habit.depth:result*=1.8
 var night=hours<6 or hours>=18
 if habit.get("night",false) and night:result*=1.45
 if habit.get("day",false) and not night:result*=1.3
 if habit.get("dawn",false) and ((hours>=5 and hours<8) or (hours>=17 and hours<20)):result*=1.5
 if habit.get("cloud",false) and weather in [1,2]:result*=1.25
 elif not habit.get("cloud",false) and weather==0:result*=1.15
 if overhead and habit.depth==2:result*=1.15
 return result
func choose(point: Dictionary,hours: float,weather: int,rng: RandomNumberGenerator,overhead: bool=false) -> Dictionary:
 var total=0.0
 for index in point.fish:total+=weight(World.FISH[index].name,hours,weather,overhead)
 var pick=rng.randf()*total
 for index in point.fish:
  pick-=weight(World.FISH[index].name,hours,weather,overhead)
  if pick<=0:return World.FISH[index]
 return World.FISH[point.fish[-1]]
func snapshot() -> Dictionary:return {"lure":lure,"depth":depth}
func restore(data: Variant):
 if data is Dictionary:lure=clampi(int(data.get("lure",0)),0,2);depth=clampi(int(data.get("depth",1)),0,2)
