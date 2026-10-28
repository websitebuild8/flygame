extends SceneTree
const Clay=preload("res://scripts/clay_theme.gd")
func _initialize():call_deferred("checks")
func luminance(c: Color) -> float:
 var linear=c.srgb_to_linear();return linear.r*.2126+linear.g*.7152+linear.b*.0722
func contrast(a: Color,b: Color) -> float:return (maxf(luminance(a),luminance(b))+.05)/(minf(luminance(a),luminance(b))+.05)
func find_button(node: Node,title: String) -> Button:
 for button in node.find_children("*","Button",true,false):
  if button.text==title:return button
 return null
func checks():
 var game=load("res://scenes/main.tscn").instantiate();game.save_path="user://menu-design.json";root.add_child(game);game.set_physics_process(false)
 var ui=game.interface
 assert(contrast(Clay.INK,Clay.PAPER)>4.5 and contrast(Clay.MUTED,Clay.PAPER)>4.5 and contrast(Clay.FOAM,Clay.SEA)>4.5,"Menu text and primary actions retain strong contrast")
 assert(game.intro.material==null and game.intro.get_meta("clay_surface",false),"Clay menus use native styles without full-screen blur")
 assert(ui.modal_scrim.visible,"Welcome screen blocks touches reaching the helm")
 find_button(game.intro,"Set sail").pressed.emit();ui.refresh()
 assert(not game.intro_visible and not ui.modal_scrim.visible,"Set sail dismisses welcome and restores gameplay")
 ui.toggle_menu();await process_frame;await process_frame
 assert(ui.menu.visible and ui.modal_scrim.visible and not ui.credits_text.visible,"Settings opens with a backdrop and compact collapsed credits")
 var close=find_button(ui.menu,"Close")
 assert(close and close.custom_minimum_size.y>=54,"Settings close target remains large and outside scrolling content")
 find_button(ui.menu,"Credits and licences").pressed.emit();assert(ui.credits_text.visible,"Credits remain accessible")
 find_button(ui.menu,"Credits and licences").pressed.emit();assert(not ui.credits_text.visible,"Credits collapse again")
 close.pressed.emit();assert(not ui.menu_visible and not ui.modal_scrim.visible,"Close restores the gameplay view")
 game.coins=2500;game.drive.engine_running=false;game.open_shop("Reels");await process_frame;await process_frame
 assert(ui.shop_panel.get_meta("clay_surface",false) and ui.shop_list.get_child_count()>0,"The shop uses styled item cards")
 assert(ui.preview_controls.visible and ui.preview_controls is Control,"Shop uses an unobstructed gesture surface")
 for tab in ui.shop_tabs.get_children():assert(tab.custom_minimum_size.y>=54,"Shop category touch targets are large")
 var normal=find_button(game.intro,"Set sail").get_theme_stylebox("normal");var pressed=find_button(game.intro,"Set sail").get_theme_stylebox("pressed")
 assert(normal.bg_color!=pressed.bg_color and normal.shadow_size>pressed.shadow_size,"Pressed clay buttons have visible depth and colour feedback")
 game.leave_fishing();game.boat.position=Vector3(0,0,-130);ui.refresh();assert(not game.fish_button.visible,"Irrelevant fishing action stays out of the driving view")
 for dimensions in [Vector2i(1280,720),Vector2i(960,540)]:
  root.size=dimensions;ui.apply_safe_area();ui.toggle_menu();await process_frame;await process_frame
  assert(Rect2(Vector2.ZERO,root.get_visible_rect().size).encloses(ui.menu.get_global_rect()),"Settings stays inside the landscape viewport")
  ui.toggle_menu()
 game.queue_free();await process_frame
 print("PASS: clay contrast, welcome/settings interaction, compact credits, shop touch targets, press feedback, context-aware HUD and two landscape sizes")
 quit()
