extends SceneTree
const Board=preload("res://scripts/reward_board.gd")
func _initialize():call_deferred("checks")
func find_button(node: Node,title: String) -> Button:
 for button in node.find_children("*","Button",true,false):
  if button.text==title:return button
 return null
func checks():
 var game=load("res://scenes/main.tscn").instantiate();game.save_path="user://voyage-rewards.json";root.add_child(game);game.set_physics_process(false)
 var ui=game.interface
 for title in ["Set sail","Rewards & medals","Collection","Chart","Diving spots","Harbour shop"]:assert(find_button(game.intro,title),"Home provides a clear illustrated shortcut: "+title)
 assert(game.intro.find_children("*","TextureRect",true,false).size()>=2,"Home uses existing fish artwork and medals")
 for dimensions in [Vector2i(1280,720),Vector2i(960,540)]:
  root.size=dimensions;await process_frame;await process_frame
  assert(Rect2(Vector2.ZERO,root.get_visible_rect().size).encloses(game.intro.get_global_rect()),"Home remains in a small landscape viewport")
  for button in game.intro.find_children("*","Button",true,false):assert(game.intro.get_global_rect().encloses(button.get_global_rect()),"Home buttons do not extend outside the panel: "+button.text)
 find_button(game.intro,"Rewards & medals").pressed.emit();await process_frame
 assert(not game.intro_visible and ui.logbook.visible and ui.logbook.tab=="Rewards","Home reward shortcut opens the paused reward hub")
 assert(ui.logbook.tabs.get_child_count()==5,"Rewards consolidate daily/weekly pages without an overflowing tab bar")
 for i in range(3):game.daily_requests.record({"species":"Yellowfin tuna","weight":8})
 var expected=Board.overview(game);assert(expected.count>=2 and expected.mvr>=165,"Ready reward summary reflects actual daily service state")
 var money=game.coins;var xp=game.experience.total
 ui.logbook.collect_daily(0)
 assert(game.coins==money+75 and game.experience.total==xp+40 and ui.logbook.receipt.visible,"Receipt follows an actual saved MVR and XP claim")
 assert(ui.logbook.receipt.amount.text=="MVR 75" and ui.logbook.receipt.experience.text=="+40 XP","Receipt makes cash and XP amounts explicit")
 ui.logbook.collect_daily(0);assert(game.coins==money+75 and game.experience.total==xp+40,"Repeated UI claim does not duplicate currency or XP")
 ui.logbook.receipt.close();assert(not ui.logbook.receipt.visible)
 var restored=preload("res://scripts/daily_requests.gd").new();restored.restore(game.daily_requests.snapshot());assert(restored.claimed[0] and restored.claim(0).is_empty(),"Claimed reward remains consumed after service restore")
 ui.logbook.show_tab("Daily");await process_frame;assert(ui.logbook.selected_tab("Rewards"),"Daily details keep Rewards highlighted")
 ui.logbook.show_tab("Weekly");await process_frame;assert(ui.logbook.selected_tab("Rewards"),"Weekly details keep Rewards highlighted")
 ui.logbook.show_tab("Rewards")
 for dimensions in [Vector2i(1280,720),Vector2i(960,540)]:
  root.size=dimensions;await process_frame;await process_frame
  ui.logbook.receipt.open({"mvr":180,"xp":180,"stars":3,"level_up":true,"level":5,"gifts":["Reef bronze"]});await process_frame;await process_frame
  assert(Rect2(Vector2.ZERO,root.get_visible_rect().size).encloses(ui.logbook.receipt.panel.get_global_rect()),"Level-up receipt fits small screens")
  assert(ui.logbook.receipt.heading.text=="LEVEL UP!" and "Reef bronze" in ui.logbook.receipt.extra.text,"Level-up receipt shows the real unlocked finish")
  for button in ui.logbook.receipt.panel.find_children("*","Button",true,false):assert(ui.logbook.receipt.panel.get_global_rect().encloses(button.get_global_rect()),"Receipt Continue remains reachable")
  ui.logbook.receipt.close()
 ui.logbook.close_screen();game.queue_free();await create_timer(.2).timeout
 print("PASS: illustrated voyage home, real reward readiness, exact-once cash/XP, saved claims, compact navigation, free milestones and small-screen receipts")
 quit()
