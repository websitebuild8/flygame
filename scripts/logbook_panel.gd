extends PanelContainer
const Clay=preload("res://scripts/clay_theme.gd")
const Art=preload("res://scripts/ui_art.gd")
var game: Node3D
var content: VBoxContainer
var tab="Collection"
var tabs: HBoxContainer
var scroll: ScrollContainer
var abandon_confirm=false
var celebration=0
var challenge_celebration: Dictionary={}
var rank_label: Label
var scroll_positions: Dictionary={}
var detail_open=false
func _ready():
 set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);anchor_left=.055;anchor_right=.945;anchor_top=.045;anchor_bottom=.955
 var column=VBoxContainer.new();column.add_theme_constant_override("separation",12);add_child(column)
 var top=HBoxContainer.new();top.add_theme_constant_override("separation",12);column.add_child(top)
 Art.picture(top,Art.medal(2),Vector2(42,50))
 var title=label(top,"ANGLER’S CLUB",26);title.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 rank_label=label(top,"Lv 1",19,Clay.SEA)
 var close=action(top,"Back to fishing",close_screen);close.size_flags_horizontal=Control.SIZE_SHRINK_END;Art.button_icon(close,"arrowLeft",22)
 tabs=HBoxContainer.new();tabs.add_theme_constant_override("separation",10);column.add_child(tabs)
 for entry in [["Collection","book"],["Spots","pin"],["Daily","sun"],["Contracts","contract"],["Weekly","calendar"],["My boat","home"]]:
  var button=action(tabs,entry[0],func():show_tab(entry[0]));Art.button_icon(button,entry[1],20);button.add_theme_font_size_override("font_size",16);button.set_meta("tab",entry[0])
 scroll=preload("res://scripts/club_scroll.gd").new();scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL;column.add_child(scroll)
 content=VBoxContainer.new();content.size_flags_horizontal=Control.SIZE_EXPAND_FILL;content.add_theme_constant_override("separation",14);scroll.add_child(content)
 add_theme_stylebox_override("panel",Clay.surface());visible=false
func label(parent: Control,value: String,size: int=17,color: Color=Clay.INK) -> Label:
 var result=game.interface.label(value,size,color);result.autowrap_mode=TextServer.AUTOWRAP_OFF if parent is HBoxContainer else TextServer.AUTOWRAP_WORD_SMART;parent.add_child(result);return result
func action(parent: Control,title: String,callback: Callable,primary: bool=false) -> Button:
 var button=game.interface.action(parent,title,callback,primary);Clay.button(button,primary);Art.colours(button,Clay.FOAM if primary else Clay.INK);return button
func card(parent: Control,color: Color=Clay.CARD) -> VBoxContainer:
 var shell=PanelContainer.new();shell.size_flags_horizontal=Control.SIZE_EXPAND_FILL;parent.add_child(shell)
 var style=Clay.surface(color,20);style.content_margin_left=16;style.content_margin_right=16;style.content_margin_top=14;style.content_margin_bottom=14;shell.add_theme_stylebox_override("panel",style)
 var body=VBoxContainer.new();body.add_theme_constant_override("separation",8);shell.add_child(body);return body
func row(parent: Control) -> HBoxContainer:
 var box=HBoxContainer.new();box.add_theme_constant_override("separation",12);parent.add_child(box);return box
func stat(parent: Control,icon: String,value: String,size: int=17,color: Color=Clay.INK):
 var box=row(parent);Art.picture(box,Art.icon(icon),Vector2(24,24),color);label(box,value,size,color)
func meter(parent: Control,value: float,total: float,color: Color=Clay.SEA):
 var bar=ProgressBar.new();bar.min_value=0;bar.max_value=maxf(total,1);bar.value=clampf(value,0,bar.max_value);bar.show_percentage=false;bar.custom_minimum_size.y=11;parent.add_child(bar)
 for key in ["background","fill"]:
  var style=StyleBoxFlat.new();style.set_corner_radius_all(6);style.bg_color=Color("cedbd1") if key=="background" else color;bar.add_theme_stylebox_override(key,style)
func summary(icon: Texture2D,title: String,subtitle: String,value: float=-1,total: float=1):
 var box=card(content,Color("dcebdc"));var line=row(box);Art.picture(line,icon,Vector2(50,56),Clay.SEA if "/icons/" in icon.resource_path else Color.WHITE);var text=VBoxContainer.new();text.size_flags_horizontal=Control.SIZE_EXPAND_FILL;line.add_child(text);label(text,title,24);label(text,subtitle,14,Clay.MUTED)
 if value>=0:meter(box,value,total)
func grid(columns: int) -> GridContainer:
 var result=GridContainer.new();result.columns=columns;result.add_theme_constant_override("h_separation",14);result.add_theme_constant_override("v_separation",14);content.add_child(result);return result
func open(selected: String=""):
 celebration=0;challenge_celebration={}
 game.interface.menu_visible=true;game.interface.menu.visible=false;visible=true;move_to_front()
 game.driving_controls.neutral();game.driving_controls.release_pointers();game.reeling=false;show_tab(selected if not selected.is_empty() else tab);game.interface.refresh()
func close_screen():
 scroll.stop()
 visible=false;game.interface.menu_visible=false;game.interface.menu.visible=false;game.interface.refresh()
func close():close_screen()
func show_tab(value: String):
 if not detail_open:scroll_positions[tab]=scroll.scroll_vertical
 detail_open=false
 if value!=tab:celebration=0;challenge_celebration={}
 tab=value;abandon_confirm=false
 rank_label.text="Lv %d"%game.experience.status().level
 rank_label.tooltip_text="%d XP · %s"%[game.experience.total,game.experience.status().title]
 for child in content.get_children():content.remove_child(child);child.queue_free()
 for item in tabs.get_children():Clay.button(item,false,item.get_meta("tab")==tab);Art.colours(item,Clay.FOAM if item.get_meta("tab")==tab else Clay.INK)
 if celebration>0:summary(Art.medal(2),"MVR %d earned!"%celebration,"Reward collected · ready for your next trip")
 if tab=="Collection":collection()
 elif tab=="Spots":spots()
 elif tab=="Contracts":contracts()
 elif tab=="Daily":daily()
 elif tab=="My boat":vessel()
 else:weekly()
 scroll.reset_to(0 if celebration>0 or not challenge_celebration.is_empty() else float(scroll_positions.get(tab,0)))
func collection():
 var progress=game.trip_progress
 summary(Art.medal(2),"%d / %d species discovered"%[progress.records.size(),game.World.FISH.size()],"Catch · collect · earn your mastery medals",progress.records.size(),game.World.FISH.size())
 var cards=grid(3 if get_viewport_rect().size.x>=1100 else 2)
 for fish in game.World.FISH:
  var record=progress.records.get(fish.name,{});var count=int(record.get("count",0));var body=card(cards)
  body.get_parent().custom_minimum_size.x=230
  var head=row(body);var name=label(head,fish.name,18);name.size_flags_horizontal=Control.SIZE_EXPAND_FILL
  Art.picture(head,Art.medal(2 if count>=15 else (1 if count>=5 else 0)) if count>0 else Art.icon("locked"),Vector2(32,38),Color.WHITE if count>0 else Clay.MUTED)
  var portrait=Art.picture(body,Art.fish(fish.name),Vector2(0,96),Color.WHITE if count>0 else Color(.0,.07,.09,1));portrait.mouse_filter=Control.MOUSE_FILTER_STOP;portrait.mouse_default_cursor_shape=Control.CURSOR_POINTING_HAND
  portrait.gui_input.connect(func(event):
   if scroll.accepts_tap() and ((event is InputEventMouseButton and not event.pressed and event.button_index==MOUSE_BUTTON_LEFT) or (event is InputEventScreenTouch and not event.pressed)):details(fish.name)
  )
  var stats=row(body);label(stats,"%.1f kg"%record.best if count>0 else "— kg",25);var space=Control.new();space.size_flags_horizontal=Control.SIZE_EXPAND_FILL;stats.add_child(space);Art.picture(stats,Art.icon("fish"),Vector2(21,24),Clay.SEA);label(stats,str(count),20)
  var target=1 if count==0 else (5 if count<5 else 15)
  meter(body,count,target,Color("cf9d46") if count>=15 else Clay.SEA)
  label(body,"MASTER ANGLER" if count>=15 else ("%d / %d · %s"%[count,target,"Discovery" if count==0 else ("Silver medal" if count<5 else "Gold medal")]),13,Clay.MUTED)
  var info=action(body,"Details",func():details(fish.name));Art.button_icon(info,"information",20)
func details(species: String):
 scroll_positions["Collection"]=scroll.scroll_vertical;detail_open=true;scroll.reset_to()
 for child in content.get_children():content.remove_child(child);child.queue_free()
 var fish_index=-1
 for i in range(game.World.FISH.size()):
  if game.World.FISH[i].name==species:fish_index=i
 var record=game.trip_progress.records.get(species,{});var count=int(record.get("count",0));var body=card(content)
 var line=row(body);Art.picture(line,Art.fish(species),Vector2(300,170));var stats=VBoxContainer.new();stats.size_flags_horizontal=Control.SIZE_EXPAND_FILL;line.add_child(stats)
 label(stats,species,26);label(stats,game.trip_progress.mastery(species),17,Clay.SEA)
 if fish_index>=0 and game.World.FISH[fish_index].has("local_name"):label(stats,game.World.FISH[fish_index].local_name+" · "+game.World.FISH[fish_index].scientific_name,14,Clay.MUTED)
 stat(stats,"weight","%.1f kg personal best"%record.get("best",0));stat(stats,"fish","%d landed"%count);stat(stats,"coin","MVR %d most valuable catch"%record.get("value",0))
 if count>0:stat(body,"pin",str(record.spot),16)
 var spots: Array[String]=[]
 for spot in game.World.SPOTS:
  if fish_index in spot.fish:spots.append(spot.name+(" · %d catches"%spot.unlock if game.catches<int(spot.unlock) else ""))
 label(body,"WHERE TO FISH",13,Clay.SEA);label(body,"  /  ".join(spots),16)
 var habits=preload("res://scripts/fishing_conditions.gd").HABITS[species]
 stat(body,"pin",habits.habitat,16)
 label(body,"TRY THIS SETUP",13,Clay.SEA)
 label(body,"%s · %s\n%s · %s"%[game.fishing_conditions.LURES[habits.lure],game.fishing_conditions.DEPTHS[habits.depth],habits.hours,habits.weather],17)
 label(body,"In-game preferences improve your chances; they never guarantee a species.",14,Clay.MUTED)
 label(body,preload("res://scripts/fish_fight.gd").BEHAVIOURS[species].tip,16,Clay.MUTED)
 action(body,"Back to collection",func():show_tab("Collection"))
func reward(parent: Control,amount: int):
 var line=row(parent);Art.picture(line,Art.icon("coin"),Vector2(30,30),Color("a56e21"));label(line,"MVR %d"%amount,24,Color("8b591b"));label(line,"BONUS",12,Color("8b591b"))
func contracts():
 var progress=game.trip_progress;var island=game.harbour_for_rewards()
 summary(Art.icon("contract"),"Harbour deliveries",island if not island.is_empty() else "Visit a harbour to accept or claim a delivery")
 if progress.active.is_empty():
  var cards=grid(3 if get_viewport_rect().size.x>=1100 else 2)
  for offer in progress.offers():
   var body=card(cards);body.get_parent().custom_minimum_size.x=230
   label(body,"DELIVERY CONTRACT",12,Clay.SEA);Art.picture(body,Art.fish(offer.species),Vector2(0,100));label(body,offer.species,20)
   var goals=row(body);stat(goals,"fish","%d+"%offer.goal,20);stat(goals,"weight","%.1f kg"%offer.kg,20)
   reward(body,offer.reward)
   var accept=action(body,"Accept",func():game.accept_contract(offer.id);show_tab(tab),true);Art.button_icon(accept,"checkmark",20);accept.disabled=island.is_empty()
 else:
  var job=progress.active;var body=card(content);var line=row(body);Art.picture(line,Art.fish(job.species),Vector2(250,140));var goals=VBoxContainer.new();goals.size_flags_horizontal=Control.SIZE_EXPAND_FILL;line.add_child(goals)
  label(goals,job.species,24);stat(goals,"pin",job.island)
  stat(goals,"fish","%d / %d delivered"%[job.count,job.goal]);meter(goals,job.count,job.goal)
  stat(goals,"weight","%.1f / %.1f kg"%[job.weight,job.kg]);meter(goals,job.weight,job.kg)
  reward(body,job.reward)
  if progress.ready():
   var claim=action(body,"Claim reward" if island==job.island else "Return to "+job.island,claim_contract,true);Art.button_icon(claim,"coin",25);claim.disabled=island!=job.island
  else:
   action(body,"Go fishing",close_screen,true)
   var cancel=action(body,"Change contract",func():
    if abandon_confirm:game.trip_progress.active={};game.save_trip();show_tab(tab)
    else:
     abandon_confirm=true
     for child in body.get_children():
      if child is Button and child.text=="Change contract":child.text="Confirm · lose delivery progress"
   )
   cancel.add_theme_font_size_override("font_size",15)
 stat(content,"trophy","%d deliveries completed · normal fish sales pay separately"%progress.completed,14,Clay.MUTED)
func weekly():
 var progress=game.trip_progress;progress.refresh_week()
 summary(Art.medal(2),"Weekly ocean challenge","Two goals · one reward · no daily streak")
 var cards=grid(2);var catches=card(cards);var variety=card(cards)
 Art.picture(catches,Art.icon("fish"),Vector2(70,65),Clay.SEA);label(catches,"%d / 10"%mini(progress.weekly.count,10),32);label(catches,"Fish landed",17);meter(catches,progress.weekly.count,10)
 var fish_row=row(variety)
 fish_row.add_theme_constant_override("separation",6)
 for fish in game.World.FISH:Art.picture(fish_row,Art.fish(fish.name),Vector2(56,65),Color.WHITE if fish.name in progress.weekly.species else Color(.3,.4,.4,.5))
 label(variety,"%d / 3"%mini(progress.weekly.species.size(),3),32);label(variety,"Different species",17);meter(variety,progress.weekly.species.size(),3)
 var prize=card(content,Color("eee1bd"));var line=row(prize);Art.picture(line,Art.medal(2),Vector2(52,62));reward(line,300)
 if progress.weekly.claimed:
  stat(prize,"checkmark","REWARD COLLECTED",20,Clay.SEA)
 elif progress.weekly_ready():
  var claim=action(prize,"Claim MVR 300",claim_weekly,true);claim.disabled=game.harbour_for_rewards().is_empty()
 else:action(prize,"Go fishing",close_screen,true)
 label(content,"Claim at any harbour · resets Monday UTC",13,Clay.MUTED)

func claim_contract():
 var amount=game.claim_contract()
 if amount>0:celebration=amount
 show_tab(tab)
func claim_weekly():
 var amount=game.claim_weekly_reward()
 if amount>0:celebration=amount
 show_tab(tab)

func stars(parent: Control,count: int):
 var widget=preload("res://scripts/star_row.gd").new();widget.stars=count;parent.add_child(widget)
func spots():
 var system=game.spot_challenges;var rank=game.experience.status()
 summary(Art.icon("star"),"Level %d · %s"%[rank.level,rank.title],"%d / 10 badges collected · free finish gifts at levels 5, 10 and 15"%system.best.size(),rank.current,rank.next)
 if not system.result.is_empty():
  var outcome=system.result;var entry=system.definition(outcome.id);var result_card=card(content,Color("eee1bd") if outcome.success else Clay.CARD)
  label(result_card,"CHALLENGE COMPLETE!" if outcome.success else outcome.reason,24)
  label(result_card,entry.name,18);stars(result_card,outcome.stars if outcome.success else 0)
  if outcome.success:
   var prize=system.preview_reward();var line=row(result_card);stat(line,"star","+%d XP"%prize.xp,22);reward(line,prize.mvr)
   action(result_card,"Claim rewards",func():
    var reward=game.claim_spot_reward()
    if not reward.is_empty():celebration=reward.mvr;challenge_celebration=reward
    show_tab("Spots")
   ,true)
  else:
   label(result_card,"Your fish and catch XP are safe. Retry free at the buoy.",15,Clay.MUTED)
   var retry=action(result_card,"Retry",func():start_event(entry.id),true);retry.disabled=not game.can_start_spot_challenge(entry.id)
   action(result_card,"Dismiss",func():system.result={};game.save_trip();show_tab("Spots"))
 if not challenge_celebration.is_empty():
  var prize=card(content,Color("eee1bd"));var line=row(prize);Art.picture(line,Art.medal(challenge_celebration.stars-1),Vector2(48,64));stars(line,challenge_celebration.stars)
  label(prize,"+%d XP · Level %d"%[challenge_celebration.xp,challenge_celebration.level],25)
  if challenge_celebration.level_up:label(prize,"LEVEL UP!",24,Clay.SEA)
  if not challenge_celebration.get("gifts",[]).is_empty():label(prize,"Gift unlocked · "+", ".join(challenge_celebration.gifts),18,Clay.SEA)
 if not system.active.is_empty():
  var entry=system.definition(system.active.id);var session=system.active;var body=card(content)
  label(body,entry.name,24);label(body,system.goal(entry),16)
  stat(body,"fish","%d / %d landed"%[session.count,int(entry.get("count",1))]);meter(body,session.count,entry.get("count",1))
  if entry.has("kg"):stat(body,"weight","%.1f / %.1f kg"%[session.weight,entry.kg]);meter(body,session.weight,entry.kg)
  if entry.has("variety"):stat(body,"fish","%d / %d species"%[session.species.size(),entry.variety])
  if entry.has("seconds"):stat(body,"calendar","%02d:%02d remaining"%[int(session.remaining)/60,int(session.remaining)%60],22)
  label(body,"Timer pauses while this screen is open. Stay within the fishing point.",14,Clay.MUTED)
  action(body,"Continue fishing",close_screen,true)
  var cancel=action(body,"End attempt",func():
   if abandon_confirm:system.finish(false,"Attempt ended");game.save_trip();show_tab("Spots")
   else:
    abandon_confirm=true
    for button in body.get_children():
     if button is Button and button.text=="End attempt":button.text="Confirm · keep fish, end challenge"
  )
 var cards=grid(2)
 for point in game.World.SPOTS:
  var entry=system.definition(point.id);var body=card(cards);label(body,point.name,20);stars(body,int(system.best.get(entry.id,0)))
  label(body,entry.name,17,Clay.SEA);label(body,system.goal(entry),15)
  var payout=row(body);stat(payout,"star","%d XP"%entry.xp);stat(payout,"coin","MVR %d"%entry.mvr)
  var start=action(body,"Start challenge" if game.can_start_spot_challenge(entry.id) else "View challenge",func():event_details(entry.id),true);Art.button_icon(start,"target",22)
  var timed=system.definition(point.id+"_timed")
  if not timed.is_empty():
   var event_button=action(body,"Timed event · Lv %d"%timed.level,func():event_details(timed.id));Art.button_icon(event_button,"calendar",21)
  for extra in system.DEFINITIONS:
   if extra.spot==point.id and extra.id!=entry.id and not extra.has("seconds"):
    var bonus=action(body,extra.name,func():event_details(extra.id));Art.button_icon(bonus,"star",21)
func event_details(id: String):
 if not detail_open:scroll_positions["Spots"]=scroll.scroll_vertical
 detail_open=true;scroll.reset_to()
 var system=game.spot_challenges;var entry=system.definition(id);var point=system.spot(entry.spot)
 for child in content.get_children():content.remove_child(child);child.queue_free()
 var body=card(content);var head=row(body);Art.picture(head,Art.medal(2),Vector2(44,64));label(head,entry.name,26);stars(head,int(system.best.get(id,0)))
 stat(body,"pin",point.name,20);label(body,system.goal(entry),21)
 if entry.has("seconds"):
  stat(body,"calendar","%d minutes · Level %d"%[int(entry.seconds)/60,entry.level],21)
  label(body,"3 stars: at least 60% time left. 2 stars: at least 33% time left. 1 star: finish before zero.",16)
 else:label(body,"1 star: complete the goal. 2 stars: %.1f kg. 3 stars: %.1f kg (%s)."%[entry.silver,entry.gold,"combined catch" if entry.has("kg") else "average qualifying fish"],16)
 label(body,"First clear",14,Clay.SEA);var prize=row(body);stat(prize,"star","%d+ XP"%entry.xp,23);reward(prize,entry.mvr)
 label(body,"Replays: 10 XP, plus XP for improved stars. No repeated first-clear MVR. Failure keeps your catches and catch XP.",14,Clay.MUTED)
 var can_start=game.can_start_spot_challenge(id)
 var start=action(body,"Start %02d:%02d"%[int(entry.seconds)/60,int(entry.seconds)%60] if entry.has("seconds") else "Start challenge",func():start_event(id),true);start.disabled=not can_start
 if not can_start:
  var note="Stop at this buoy in neutral or with the engine off."
  if game.experience.status().level<int(entry.get("level",1)):note="Reach level %d to unlock this event."%entry.level
  elif not system.active.is_empty():note="Finish or end your current attempt first."
  elif not system.result.is_empty() and system.result.success:note="Claim your completed challenge reward first."
  elif entry.get("night",false) and game.day_cycle.hours>=6 and game.day_cycle.hours<18:note="Return after dusk: 18:00–06:00 game time."
  label(body,note,16,Clay.SEA)
 var navigate=action(body,"Plot route to buoy",func():game.set_waypoint(point.at,point.name);close_screen());navigate.disabled=game.catches<int(point.unlock)
 action(body,"Back to spot challenges",func():show_tab("Spots"))
func start_event(id: String):
 if game.start_spot_challenge(id):close_screen()
 else:event_details(id)

func daily():
 var system=game.daily_requests;var jobs=system.offers()
 summary(Art.icon("sun"),"Today’s fishing requests","Optional catches · claim anywhere · resets at 00:00 UTC · no streaks")
 var cards=grid(3 if get_viewport_rect().size.x>=1100 else 2)
 for i in range(jobs.size()):
  var job=jobs[i];var body=card(cards);body.get_parent().custom_minimum_size.x=220
  Art.picture(body,Art.fish(job.species) if not job.species.is_empty() else Art.icon("fish"),Vector2(0,85),Color.WHITE if not job.species.is_empty() else Clay.SEA)
  label(body,job.name,21)
  label(body,"Land one fish weighing 6 kg or more" if job.kind=="large" else ("Land %d %s"%[job.goal,job.species] if not job.species.is_empty() else "Land any three fish"),16)
  meter(body,system.counts[i],job.goal);stat(body,"fish","%d / %d"%[system.counts[i],job.goal],21)
  reward(body,job.mvr);stat(body,"star","+%d XP"%job.xp)
  var claim=action(body,"Collected" if system.claimed[i] else ("Claim reward" if system.ready(i) else "Go fishing"),func():
   if system.ready(i):
    var prize=game.claim_daily_request(i);celebration=int(prize.get("mvr",0));show_tab("Daily")
   else:close_screen()
  ,true);claim.disabled=system.claimed[i]
 label(content,"Fish count when landed, stay in your icebox and can still be sold. Your local device clock sets the daily calendar.",14,Clay.MUTED)

func vessel():
 var id=game.equipped_boat;var identity=game.boat_identity
 var chosen=identity.badge(id,game.catches)
 summary(Art.icon("home") if chosen.id=="none" else Art.medal(0 if chosen.id=="captain" else (1 if chosen.id=="reef" else 2)),identity.title(id),game.World.vessel(id).name+" · "+chosen.name)
 var body=card(content);label(body,"NAME YOUR VESSEL",13,Clay.SEA)
 var naming=row(body);var input=LineEdit.new();input.max_length=22;input.text=str(identity.names.get(id,""));input.placeholder_text="Boat name · up to 22 characters";input.custom_minimum_size.y=52;input.size_flags_horizontal=Control.SIZE_EXPAND_FILL;input.add_theme_stylebox_override("normal",Clay.surface(Clay.CARD,14,true));input.add_theme_stylebox_override("focus",Clay.surface(Clay.FOAM,14,true));input.add_theme_color_override("font_color",Clay.INK);input.add_theme_color_override("font_placeholder_color",Clay.MUTED);naming.add_child(input)
 action(naming,"Save name",func():game.name_boat(input.text);show_tab("My boat"),true)
 label(body,"Choose your captain’s badge",19)
 var badges=row(body)
 for index in range(1,identity.BADGES.size()):
  var entry=identity.BADGES[index];var shell=VBoxContainer.new();shell.size_flags_horizontal=Control.SIZE_EXPAND_FILL;badges.add_child(shell)
  Art.picture(shell,Art.medal(index-1),Vector2(50,64),Color.WHITE if game.catches>=entry.need else Color(.4,.45,.45,.5))
  var select=action(shell,entry.name if game.catches>=entry.need else "%d catches"%entry.need,func():game.choose_boat_badge(entry.id);show_tab("My boat"));select.add_theme_font_size_override("font_size",15);select.disabled=game.catches<entry.need or chosen.id==entry.id
 action(body,"Remove badge",func():game.choose_boat_badge("none");show_tab("My boat"))
 label(body,"Earned liveries",19)
 for entry in [[10,"Captain’s teal"],[30,"Ocean racer"]]:
  stat(body,"star",entry[1]+(" · unlocked" if game.catches>=entry[0] else " · %d / %d catches"%[game.catches,entry[0]]));meter(body,game.catches,entry[0])
 label(body,"Apply earned liveries in the harbour showroom: Boats → Customise. Boat names and badges appear in the driving HUD.",15,Clay.MUTED)
 label(body,"Fleet ownership · %d / %d vessels"%[game.owned_boats.size(),game.World.BOATS.size()],18,Clay.SEA)
 for boat in game.World.BOATS:stat(body,"checkmark" if boat.id in game.owned_boats else "locked",boat.name,16,Clay.SEA if boat.id in game.owned_boats else Clay.MUTED)
