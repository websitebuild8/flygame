extends RefCounted
const TIPS={
 "helm":"Your first trip · drag the wheel to steer. Slide the throttle up for forward, down for reverse; centre is neutral.",
 "buoy":"At the buoy · select neutral or switch off the engine, then tap Start fishing.",
 "cast":"Ready to fish · choose lure and depth in Fishing setup. Tap CAST; an overhead reel uses DROP JIG.",
 "hook":"Bite! Tap HOOK in the green zone. Then hold to reel; release briefly if tension climbs into red.",
 "land":"Fish clear of the water · tap Put fish on boat. You do not need to fill the bar.",
 "market":"At the harbour · tap Market, serve a customer, then collect payment. Contracts and requests are in Goals."
}
var seen: Dictionary={}
var enabled=true
func next(game: Node3D) -> String:
 if not enabled:return ""
 var key="helm"
 if game.market_mode or (game.at_home_dock() and not game.inventory.is_empty()):key="market"
 elif game.can_put_fish_on_boat():key="land"
 elif game.fishing and game.bite_announced:key="hook"
 elif game.fishing_view:key="cast"
 elif not game.current_challenge_spot().is_empty():key="buoy"
 return "" if seen.has(key) else key
func dismiss(key: String):
 if TIPS.has(key):seen[key]=true
func restore(data: Variant):
 seen.clear();enabled=true
 if not data is Dictionary:return
 enabled=bool(data.get("enabled",true));var saved=data.get("seen",{})
 if saved is Dictionary:
  for key in TIPS:
   if saved.get(key,false):seen[key]=true
func snapshot() -> Dictionary:return {"enabled":enabled,"seen":seen.duplicate()}
