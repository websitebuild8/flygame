extends RefCounted
var total=0
func cost(level: int) -> int:return 100+50*(level-1)
func status() -> Dictionary:
 var remaining=total;var level=1
 while level<20 and remaining>=cost(level):remaining-=cost(level);level+=1
 return {"level":level,"current":remaining if level<20 else 1,"next":cost(level) if level<20 else 1,"title":"Ocean legend" if level==20 else ("Ocean master" if level>=15 else ("Atoll expert" if level>=10 else ("Reef angler" if level>=5 else "New angler")))}
func add(amount: int) -> Dictionary:
 var before=status().level;total=clampi(total+maxi(0,amount),0,100000000)
 return {"xp":maxi(0,amount),"before":before,"level":status().level,"level_up":status().level>before}
func restore(value: Variant):total=clampi(int(value),0,100000000) if value is int or value is float else 0
