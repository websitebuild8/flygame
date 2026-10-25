extends CanvasLayer
var game: Node3D
var body: Control
var margin: MarginContainer
var zone: Label
var objective: Label
var menu: PanelContainer
var menu_visible = false
var mode_before = ""
var settings_button: Button
var pause_tip: Label
var cast_normal: StyleBoxFlat
var cast_pressed: StyleBoxFlat
var cast_round: StyleBoxFlat
var cast_round_pressed: StyleBoxFlat
var tackle_button: Button
var workshop_button: Button
var shop_panel: PanelContainer
var shop_list: VBoxContainer
var shop_tabs: HBoxContainer
var shop_category = "Reels"
var shop_title: Label
var selected_item = "island_reel"
var map_visible=false
var map_panel: PanelContainer
var map_chart: Control
var mini_map: Button
var engine_button: Button
var put_fish_button: Button
var map_button: Button
var camera_button: Button
var route_label: Label
var clock_label: Label
var market_panel: PanelContainer
var customer_label: Label
var preview_label: Label
var action_stack: VBoxContainer
var preview_card: PanelContainer
var travel_box: PanelContainer
var gauge_panel: PanelContainer
var fight_gauge: Control
var reel_ring: Control
var reel_swipe=0.0
var swipe_pointer=-1
const INK = Color("102633")
const WHITE = Color("edf5f2")
const MUTED = Color("a6c0c7")
const MINT = Color("8bdecb")

func panel_style(color: Color, radius: int = 22) -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = Color(color,color.a*0.76)
	style.set_corner_radius_all(radius)
	style.set_border_width_all(1)
	style.border_color = Color(0.86,0.96,1.0,0.38)
	style.shadow_color=Color(0.01,0.03,0.04,0.22)
	style.shadow_size=8
	style.shadow_offset=Vector2(0,4)
	style.content_margin_left = 18
	style.content_margin_right = 18
	style.content_margin_top = 14
	style.content_margin_bottom = 14
	return style

func label(text: String, font_size: int = 18, color: Color = WHITE) -> Label:
	var item = Label.new()
	item.text = text
	item.add_theme_font_size_override("font_size",font_size)
	item.add_theme_color_override("font_color",color)
	return item

func action(parent: Control, title: String, callback: Callable, primary: bool = false) -> Button:
	var item = Button.new()
	item.text = title
	item.custom_minimum_size.y = 54
	item.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	item.focus_mode = Control.FOCUS_ALL
	item.add_theme_font_size_override("font_size",18)
	item.add_theme_color_override("font_color",WHITE)
	item.add_theme_color_override("font_hover_color",WHITE)
	item.add_theme_color_override("font_pressed_color",WHITE)
	item.add_theme_color_override("font_disabled_color",Color("8caaaf"))
	var normal = panel_style(Color(0.25,0.68,0.59,0.54) if primary else Color(0.14,0.24,0.29,0.58),18)
	normal.content_margin_top = 8
	normal.content_margin_bottom = 8
	item.add_theme_stylebox_override("normal",normal)
	var hover = normal.duplicate()
	hover.bg_color = Color(0.45,0.85,0.76,0.65) if primary else Color(0.35,0.53,0.60,0.65)
	item.add_theme_stylebox_override("hover",hover)
	var pressed = normal.duplicate()
	pressed.bg_color = Color(0.26,0.65,0.56,0.75) if primary else Color(0.35,0.55,0.62,0.75)
	item.add_theme_stylebox_override("pressed",pressed)
	var disabled = normal.duplicate()
	disabled.bg_color = Color(0.04,0.12,0.16,0.8)
	item.add_theme_stylebox_override("disabled",disabled)
	var focus = panel_style(Color.TRANSPARENT,18)
	focus.set_border_width_all(3)
	focus.border_color = Color("f2ce86")
	item.add_theme_stylebox_override("focus",focus)
	parent.add_child(item)
	item.pressed.connect(callback)
	return item

func build(owner_game: Node3D) -> void:
	game=owner_game
	body=Control.new()
	body.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	body.mouse_filter=Control.MOUSE_FILTER_IGNORE
	add_child(body)
	game.hud=body
	margin=MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.mouse_filter=Control.MOUSE_FILTER_IGNORE
	body.add_child(margin)
	apply_safe_area()
	get_viewport().size_changed.connect(apply_safe_area)
	var stage=Control.new()
	stage.mouse_filter=Control.MOUSE_FILTER_IGNORE
	margin.add_child(stage)
	var header=PanelContainer.new()
	header.size=Vector2(390,126)
	header.add_theme_stylebox_override("panel",panel_style(Color(0.14,0.24,0.29,0.58)))
	stage.add_child(header)
	var head_column=VBoxContainer.new()
	head_column.add_theme_constant_override("separation",6)
	header.add_child(head_column)
	var row=HBoxContainer.new()
	head_column.add_child(row)
	var title_column=VBoxContainer.new()
	title_column.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	row.add_child(title_column)
	title_column.add_child(label("ISHAQ'S FISHING TRIP",12,MUTED))
	zone=label("HA. KELAA",21)
	title_column.add_child(zone)
	settings_button=action(row,"☰",toggle_menu)
	settings_button.custom_minimum_size=Vector2(48,48)
	settings_button.size_flags_horizontal=0
	game.info=label("",16,MINT)
	head_column.add_child(game.info)
	objective=label("",12,MUTED)
	objective.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	head_column.add_child(objective)
	game.status=label("",15)
	game.status.position=Vector2(0,140)
	game.status.size=Vector2(390,60)
	game.status.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	game.status.add_theme_color_override("font_shadow_color",Color("173543"))
	game.status.add_theme_constant_override("shadow_offset_y",1)
	stage.add_child(game.status)
	gauge_panel=PanelContainer.new()
	gauge_panel.position=Vector2(0,204)
	gauge_panel.size=Vector2(345,110)
	gauge_panel.add_theme_stylebox_override("panel",panel_style(Color(0.025,0.085,0.12,0.93),18))
	stage.add_child(gauge_panel)
	game.fishing_meters=VBoxContainer.new()
	gauge_panel.add_child(game.fishing_meters)
	for text in ["LINE TENSION · RELEASE TO EASE","FISH LANDED"]:
		game.fishing_meters.add_child(label(text,12,WHITE))
		var meter=ProgressBar.new()
		meter.custom_minimum_size.y=12
		meter.show_percentage=false
		for style_name in ["background","fill"]:
			var bar_style=panel_style(Color("173543") if style_name=="background" else MINT,6)
			bar_style.content_margin_top=0
			bar_style.content_margin_bottom=0
			bar_style.content_margin_left=0
			bar_style.content_margin_right=0
			meter.add_theme_stylebox_override(style_name,bar_style)
		game.fishing_meters.add_child(meter)
		if game.tension_bar==null: game.tension_bar=meter
		else: game.landing_bar=meter
	fight_gauge=preload("res://scripts/fishing_gauge.gd").new()
	fight_gauge.game=game
	fight_gauge.mouse_filter=Control.MOUSE_FILTER_IGNORE
	stage.add_child(fight_gauge)
	fight_gauge.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	fight_gauge.offset_left=-180;fight_gauge.offset_right=180
	fight_gauge.offset_top=85;fight_gauge.offset_bottom=295
	game.driving_controls=preload("res://scripts/helm_controls.gd").new()
	stage.add_child(game.driving_controls)
	game.driving_controls.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	game.driving_controls.offset_top=-224
	game.driving_controls.set_skin(game.equipped_boat)
	var actions=VBoxContainer.new()
	action_stack=actions
	actions.alignment=BoxContainer.ALIGNMENT_END
	actions.add_theme_constant_override("separation",10)
	stage.add_child(actions)
	actions.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	actions.offset_left=-210
	actions.offset_right=210
	actions.offset_top=-250
	actions.offset_bottom=0
	game.fish_button=action(actions,"Start fishing",func(): pass,true)
	reel_ring=preload("res://scripts/reel_control_ring.gd").new()
	reel_ring.game=game
	reel_ring.mouse_filter=Control.MOUSE_FILTER_IGNORE
	game.fish_button.add_child(reel_ring)
	reel_ring.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	cast_normal=game.fish_button.get_theme_stylebox("normal").duplicate()
	cast_pressed=game.fish_button.get_theme_stylebox("pressed").duplicate()
	cast_round=panel_style(Color.TRANSPARENT,80)
	cast_round.set_border_width_all(0)
	cast_round.shadow_size=0
	cast_round.shadow_color=Color.TRANSPARENT
	cast_round.border_color=Color("f8dfb0")
	cast_round_pressed=cast_round.duplicate()
	cast_round_pressed.bg_color=Color.TRANSPARENT
	game.fish_button.button_down.connect(func():
		reel_swipe=0
		if not game.fishing: game.cast()
		game.reeling=true
	)
	game.fish_button.button_up.connect(func(): game.reeling=false)
	game.fish_button.gui_input.connect(reel_gesture)
	put_fish_button=action(actions,"Put fish on boat",game.put_fish_on_boat,true)
	var navigation=HBoxContainer.new()
	navigation.add_theme_constant_override("separation",8)
	actions.add_child(navigation)
	game.drive_button=action(navigation,"Back to helm",game.leave_fishing)
	game.market_button=action(navigation,"Market",game.sell)
	tackle_button=action(navigation,"Tackle",func(): game.open_shop("Reels"))
	workshop_button=action(navigation,"Workshop",func(): game.open_shop("Boat"))
	game.hint_label=label("",12,MUTED)
	game.hint_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	actions.add_child(game.hint_label)
	var travel_panel=PanelContainer.new()
	travel_box=travel_panel
	stage.add_child(travel_panel)
	travel_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	travel_panel.offset_left=-165
	travel_panel.offset_right=165
	travel_panel.add_theme_stylebox_override("panel",panel_style(Color(0.025,0.085,0.12,0.92),18))
	var travel=VBoxContainer.new()
	travel_panel.add_child(travel)
	clock_label=label("",18,MINT)
	clock_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	travel.add_child(clock_label)
	route_label=label("Open the chart to plan your trip",14)
	route_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	route_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	travel.add_child(route_label)
	var top_actions=HBoxContainer.new()
	top_actions.add_theme_constant_override("separation",10)
	stage.add_child(top_actions)
	top_actions.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	top_actions.offset_left=-285
	top_actions.offset_bottom=54
	map_button=action(top_actions,"Chart · M",toggle_map)
	camera_button=action(top_actions,"POV",game.toggle_driving_camera)
	mini_map=preload("res://scripts/mini_map.gd").new()
	mini_map.game=game
	stage.add_child(mini_map)
	mini_map.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	mini_map.offset_left=-180
	mini_map.offset_right=0
	mini_map.offset_top=66
	mini_map.offset_bottom=246
	mini_map.pressed.connect(toggle_map)
	engine_button=action(stage,"⏻ Engine off",game.toggle_engine)
	engine_button.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	engine_button.offset_left=-175
	engine_button.offset_right=-5
	engine_button.offset_top=-295
	engine_button.offset_bottom=-239
	build_market()
	build_menu()
	build_catch()
	build_shop()
	build_preview_card()
	build_map()
	build_intro()
	apply_glass(body)
	refresh()

func build_market() -> void:
	market_panel=PanelContainer.new()
	body.add_child(market_panel)
	market_panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	market_panel.offset_left=-440
	market_panel.offset_right=-20
	market_panel.offset_top=-310
	market_panel.offset_bottom=-24
	market_panel.add_theme_stylebox_override("panel",panel_style(Color(0.025,0.085,0.12,0.96),24))
	var column=VBoxContainer.new()
	column.add_theme_constant_override("separation",12)
	market_panel.add_child(column)
	column.add_child(label("ISLAND FISH MARKET",13,MINT))
	customer_label=label("",20)
	customer_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	column.add_child(customer_label)
	game.market_action=action(column,"Serve next customer",game.serve_customer,true)
	action(column,"Return to your boat",game.leave_fishing)
	market_panel.visible=false

func build_menu() -> void:
	menu = PanelContainer.new()
	menu.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var style = panel_style(Color(0.025,0.075,0.105,0.98),0)
	style.content_margin_left = 180
	style.content_margin_right = 180
	style.content_margin_top = 20
	menu.add_theme_stylebox_override("panel",style)
	add_child(menu)
	var column = VBoxContainer.new()
	column.add_theme_constant_override("separation",10)
	var scroll=ScrollContainer.new()
	scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL
	menu.add_child(scroll)
	scroll.add_child(column)
	column.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	column.add_child(label("TAKE A BREATHER",13,MINT))
	column.add_child(label("Your trip",34))
	column.add_child(label("Drag the wheel to steer.\nLever up: forward. Centre: neutral.\nLever down: reverse. The throttle stays set.",18,MUTED))
	column.add_child(label("Keyboard: A/D steer · W/S adjust throttle\nN selects neutral · Space casts/reels",15,MUTED))
	for text in ["Sound","Vibration"]:
		var toggle = CheckButton.new()
		toggle.text = text
		toggle.button_pressed = true
		toggle.custom_minimum_size.y = 54
		toggle.add_theme_font_size_override("font_size",20)
		toggle.toggled.connect(func(on: bool):
			if text == "Sound":
				game.feedback.sound_enabled = on
			else:
				game.feedback.vibration_enabled = on
		)
		column.add_child(toggle)
	game.upgrade_button = action(column,"Upgrade engine · MVR 100",game.buy_upgrade)
	game.home_button = action(column,"Return to home dock",func():
		game.return_home()
		toggle_menu()
	)
	action(column,"Next time of day",func():
		game.day_cycle.next_phase()
		game.save_trip()
	)
	action(column,"Change weather",func():
		game.day_cycle.next_weather()
	)
	pause_tip = label("",16,MUTED)
	pause_tip.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(pause_tip)
	action(column,"Back to your trip",toggle_menu,true)
	var credits=RichTextLabel.new()
	credits.bbcode_enabled=true
	credits.fit_content=true
	credits.text="Tuna Fish by [url=https://www.fab.com/listings/6b90bbe2-3031-4b36-93ad-90f1cb2d01f5]GoldenZtuff[/url] · [url=https://creativecommons.org/licenses/by/4.0/]CC BY 4.0[/url]\nAdapted: resized textures, game scale and orientation.\n\nGiant Trevally by [url=https://sketchfab.com/3d-models/cc0-giant-trevally-caranx-ignobilis-e6446df50ba746ed8ce8a3dd66b3b8e8]ffish.asia / floraZia.com[/url] · [url=https://creativecommons.org/publicdomain/zero/1.0/]CC0[/url]\nAdapted: geometry reduction, alignment and body/tail movement.\n\nFishing Rod, Rigged and Animated by [url=https://sketchfab.com/3d-models/fishing-rod-rigged-and-animated-78991bf44cf54acb8660bef317d72c7a]Ergin ERYILDIR[/url] · [url=https://creativecommons.org/licenses/by/4.0/]CC BY 4.0[/url]\nAdapted: reel parts, animation pivots and preview framing.\n\nBoat Motor by [url=https://sketchfab.com/3d-models/boat-motor-a496b95b40074b91aeeb1e9a2aae913b]Bora Özakaltun[/url] · [url=https://creativecommons.org/licenses/by/4.0/]CC BY 4.0[/url]\nAdapted: mounting, scale and rotating propeller."
	credits.add_theme_font_size_override("normal_font_size",13)
	credits.text+="\n\nSkipjack Tuna by [url=https://sketchfab.com/3d-models/cc0-skipjack-tuna-katsuwonus-pelamis-9431157b2fce4ea9a72d9cfe3ce37a6d]ffish.asia / floraZia.com[/url] · CC0\nAdapted: scan reduction, alignment and swimming.\n\nSailfish by [url=https://sketchfab.com/3d-models/sailfish-78249838285d4f67a24c3832464c37ae]RED SIDE[/url] · [url=https://creativecommons.org/licenses/by/4.0/]CC BY 4.0[/url]\nAdapted: geometry reduction, materials, alignment and swimming.\n\nCoryphaena hippurus by [url=https://randibu.itch.io/3dfish]Randibu[/url] · [url=https://creativecommons.org/licenses/by/4.0/]CC BY 4.0[/url]\nAdapted: FBX conversion, 1k texture, alignment, wet material and swimming."
	credits.text+="\n\n2004 17-foot Scout, 285 Conquest Boston Whaler, Freedom 325 Grady White and Glacier Bay by [url=https://sketchfab.com/boatusfoundation]BoatUS Foundation[/url] · [url=https://creativecommons.org/licenses/by/4.0/]CC BY 4.0[/url]\nAdapted: mesh optimisation, trailer removal, wheel/throttle/outboard pivots, camera mounts and game integration. Manufacturers do not endorse this game."
	credits.text+="\n\nHand With Gloves by [url=https://sketchfab.com/3d-models/hand-with-gloves-5a6a434b8ec943ffacc581358781eecb]JUST (@teenjust500)[/url] · [url=https://creativecommons.org/licenses/by/4.0/]CC BY 4.0[/url]\nAdapted: finger poses, fishing grips and two arm IK chains. Authored rod blank by Ergin ERYILDIR: live geometry alignment, bending material and right-hand reel conversion."
	credits.text+="\n\nMarket customers: [url=https://quaternius.com/packs/ultimatemodularcharacters.html]Quaternius Ultimate Modular Men[/url] · CC0 1.0. Adapted: retained idle/walk/interact clips, GLB packing, scale and clothing colours.\nCash register: [url=https://kenney.nl/assets/mini-market]Kenney Mini Market[/url] · CC0 1.0.\nMVR 100 specimen artwork: [url=https://www.mma.gov.mv/Public%20Education/currency/RDF%20book/RDF%20booklet.pdf]Maldives Monetary Authority, Ran Dhihafaheh booklet[/url], page 13. Used as an in-game payment prop; not covered by the CC0 model licences."
	credits.meta_clicked.connect(func(url): OS.shell_open(str(url)))
	column.add_child(credits)
	menu.visible = false

func build_catch() -> void:
	game.catch_overlay = PanelContainer.new()
	game.catch_overlay.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	game.catch_overlay.offset_left = -440
	game.catch_overlay.offset_right = -30
	game.catch_overlay.offset_top = -310
	game.catch_overlay.offset_bottom = -28
	game.catch_overlay.add_theme_stylebox_override("panel",panel_style(Color(0.025,0.085,0.12,0.97),24))
	add_child(game.catch_overlay)
	var column = VBoxContainer.new()
	column.add_theme_constant_override("separation",10)
	game.catch_overlay.add_child(column)
	var caption = label("FRESH FROM THE OCEAN",13,MINT)
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(caption)
	game.catch_text = label("",23)
	game.catch_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(game.catch_text)
	action(column,"Store in icebox",game.close_catch,true)
	game.catch_overlay.visible = false

func build_intro() -> void:
	game.intro = PanelContainer.new()
	game.intro.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var style = panel_style(Color(0.025,0.075,0.105,0.5),0)
	style.content_margin_left = 30
	style.content_margin_right = 30
	game.intro.add_theme_stylebox_override("panel",style)
	add_child(game.intro)
	var center=CenterContainer.new()
	game.intro.add_child(center)
	var column=VBoxContainer.new()
	column.custom_minimum_size.x=480
	column.add_theme_constant_override("separation",14)
	center.add_child(column)
	var space = Control.new()
	space.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(space)
	for text in ["THE MALDIVES AWAIT", "Ishaq's", "Fishing Trip", "A small boat. An ocean of possibilities."]:
		var item = label(text,48 if text in ["Ishaq's","Fishing Trip"] else 16,MINT if text=="THE MALDIVES AWAIT" else WHITE)
		item.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		column.add_child(item)
	action(column,"Set sail",start_trip,true)
	var bottom_space = Control.new()
	bottom_space.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(bottom_space)

func start_trip() -> void:
	game.intro_visible = false
	game.intro.visible = false
	game.hud.visible = true
	game.leave_fishing()

func toggle_menu() -> void:
	menu_visible = not menu_visible
	menu.visible = menu_visible
	if menu_visible:
		menu.move_to_front()
	game.reeling = false
	game.driving_controls.release_pointers()
	game.driving_controls.neutral()
	game.drive.set_lever(0)
	refresh()

func apply_safe_area() -> void:
	var sides = {"left":20,"right":20,"top":22,"bottom":24}
	if OS.get_name() in ["Android","iOS"]:
		var safe = DisplayServer.get_display_safe_area()
		var window = DisplayServer.window_get_size()
		if window.x>0 and window.y>0 and safe.size.x>0:
			var scale_factor = get_viewport().get_visible_rect().size/Vector2(window)
			sides.left = maxi(20,int(safe.position.x*scale_factor.x)+12)
			sides.top = maxi(22,int(safe.position.y*scale_factor.y)+12)
			sides.right = maxi(20,int((window.x-safe.end.x)*scale_factor.x)+12)
			sides.bottom = maxi(24,int((window.y-safe.end.y)*scale_factor.y)+12)
	for side in sides:
		margin.add_theme_constant_override("margin_"+side,sides[side])

func refresh() -> void:
	var driving = not game.fishing_view and not game.market_mode and not game.shop_mode
	var at_dock = game.boat.position.distance_to(game.DOCK)<18 and absf(game.speed)<1
	var nearest=game.World.nearest(game.boat.position)
	var spot_distance=Vector2(game.boat.position.x,game.boat.position.z).distance_to(nearest.at)
	var at_spot=spot_distance<14 and game.catches>=int(nearest.unlock)
	mini_map.visible = driving and not menu_visible and not map_visible
	game.driving_controls.visible = driving and not menu_visible and not map_visible
	game.fish_button.visible = not game.market_mode and not game.shop_mode and not game.can_put_fish_on_boat() and not game.landing_to_boat
	game.fish_button.disabled = driving and (not at_spot or absf(game.speed)>1 or (game.drive.engine_running and game.drive.gear!=0))
	var stopped_safe=absf(game.speed)<1 and (not game.drive.engine_running or game.drive.gear==0)
	engine_button.visible=driving and not menu_visible and not map_visible
	engine_button.text="⏻ Cut engine" if game.drive.engine_running else "⏻ Start engine"
	put_fish_button.visible=game.can_put_fish_on_boat()
	put_fish_button.custom_minimum_size.y=70
	game.market_button.disabled=not stopped_safe
	tackle_button.disabled=not stopped_safe
	workshop_button.disabled=not stopped_safe
	game.market_button.visible = driving and at_dock
	tackle_button.visible = driving and at_dock
	workshop_button.visible = driving and at_dock
	game.drive_button.visible = game.fishing_view and not game.shop_mode and not game.landing_to_boat
	game.drive_button.text = "Leave market" if game.market_mode else "Back to helm"
	game.market_action.visible = game.market_mode and not game.shop_mode
	market_panel.visible=game.market_mode
	preview_card.visible=game.shop_mode
	if game.fishing_view and not game.market_mode:
		action_stack.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
		action_stack.offset_left=-255
		action_stack.offset_right=-10
		action_stack.offset_top=-280
	elif game.first_person_driving and driving:
		action_stack.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
		action_stack.offset_left=0
		action_stack.offset_right=380
		action_stack.offset_top=-190
	else:
		action_stack.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
		action_stack.offset_left=-210
		action_stack.offset_right=210
		action_stack.offset_top=-280
	travel_box.visible=not game.shop_mode and not game.market_mode and not game.fishing_view
	map_button.visible=not game.shop_mode and not game.market_mode
	camera_button.visible=driving
	camera_button.text="External" if game.first_person_driving else "POV"
	game.upgrade_button.text = "Engine fully upgraded" if game.upgrade>=2 else "Upgrade engine · MVR %d" % game.item_price("engine")
	game.upgrade_button.disabled = not at_dock or game.coins<game.item_price("engine") or game.upgrade>=2
	pause_tip.text = "Dock at home to upgrade your engine." if not at_dock else "Engine level %d / 3 · MVR %d" % [game.upgrade+1,game.coins]
	if game.market_mode:
		var customer_names=["Aishath","Hassan","Mariyam","Ibrahim","Fathimath"]
		customer_label.text="%s · customer %d\n" % [customer_names[game.market.customer_number%5],game.market.customer_number+1]
		if game.pending_payment>0:
			customer_label.text+="Fish delivered · MVR %d due" % game.pending_payment
		elif not game.inventory.is_empty():
			var sale=game.inventory[0]
			customer_label.text+="%s\n%.1f kg · MVR %d" % [sale.species,sale.weight,sale.value]
		else:
			customer_label.text+="Your icebox is empty."
		game.market.set_species(str(game.inventory[0].species) if not game.inventory.is_empty() else "Yellowfin tuna")
		game.market.set_sale(not game.inventory.is_empty(),game.pending_payment>0)
		game.market.register_total.text="MVR %d" % (game.pending_payment if game.pending_payment>0 else (int(game.inventory[0].value) if not game.inventory.is_empty() else 0))
		game.market_action.disabled = game.market.queue_moving or game.market.handing_over or (game.inventory.is_empty() and game.pending_payment==0)
		game.market_action.text = "Collect MVR %d" % game.pending_payment if game.pending_payment>0 else "Serve next customer"
		if game.inventory.is_empty() and game.pending_payment==0:
			game.market_action.text = "Icebox empty"
	game.fishing_meters.visible = game.fishing
	gauge_panel.visible=false
	fight_gauge.visible=game.fishing and game.bite_announced
	fight_gauge.queue_redraw()
	reel_ring.queue_redraw()
	game.tension_bar.value = game.tension*100
	game.tension_bar.modulate = Color("f19b83") if game.tension>0.75 else WHITE
	game.landing_bar.value = game.progress*100
	var mode = "fishing" if game.fishing_view else "driving"
	if mode!=mode_before:
		mode_before = mode
		game.fish_button.custom_minimum_size = Vector2(182,182) if game.fishing_view else Vector2(0,54)
		game.fish_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER if game.fishing_view else Control.SIZE_EXPAND_FILL
		game.fish_button.add_theme_color_override("font_color",Color.TRANSPARENT if game.fishing_view else WHITE)
		game.fish_button.add_theme_color_override("font_hover_color",Color.TRANSPARENT if game.fishing_view else WHITE)
		game.fish_button.add_theme_color_override("font_pressed_color",Color.TRANSPARENT if game.fishing_view else WHITE)
		game.fish_button.add_theme_stylebox_override("normal",cast_round if game.fishing_view else cast_normal)
		game.fish_button.add_theme_stylebox_override("hover",cast_round if game.fishing_view else cast_normal)
		game.fish_button.add_theme_stylebox_override("pressed",cast_round_pressed if game.fishing_view else cast_pressed)
		game.fish_button.add_theme_stylebox_override("focus",StyleBoxEmpty.new() if game.fishing_view else panel_style(Color.TRANSPARENT,18))
		game.fish_button.add_theme_stylebox_override("disabled",cast_round if game.fishing_view else cast_normal)
	if game.fishing:
		game.fish_button.text = ("HOOK" if not game.fight.hooked else ("REEL IN\n↑ POWER" if game.fight.power_charge>=1 else "REEL IN")) if game.fish_timer>=2.5 else "WAIT…"
	else:
		game.fish_button.text = ("DROP JIG" if game.feedback.overhead else "CAST") if game.fishing_view else ("Start fishing" if at_spot else "%s · %d m" % [nearest.name,spot_distance])
	game.info.text = "MVR %d  /  %d fish  /  %s" % [game.coins,game.inventory.size(),game.World.vessel(game.equipped_boat).name]
	zone.text = ("BOAT SHOWROOM" if shop_category=="Boats" else ("BOAT WORKSHOP" if shop_category=="Boat" else "TACKLE HOUSE")) if game.shop_mode else ("KELAA FISH MARKET" if game.market_mode else ("ON THE LINE" if game.fishing_view else "HA. KELAA"))
	objective.visible = not game.market_mode and not game.shop_mode
	objective.text = "Eastern waters unlocked" if game.unlocked else "Discover eastern waters · %d / 3 catches" % mini(game.catches,3)
	if game.fishing_view:
		objective.text = "%s · %s" % [game.Catalog.item(str(game.equipped.Reels)).name,"JIGGING" if game.feedback.overhead else "SPINNING"]
	game.hint_label.visible = not game.shop_mode
	game.status.text = game.message
	game.hint_label.text = "Hold to reel. Release to ease tension." if game.fishing_view else "Drag the wheel · slide the throttle"
	if game.fishing and game.bite_announced and not game.fight.hooked:game.hint_label.text="Tap HOOK in the green zone"
	if game.fishing and game.fight.power_charge>=1:game.hint_label.text="Swipe up on reel · R on keyboard"
	if game.market_mode:
		game.hint_label.text="Fresh catch. Fair trade."
	clock_label.text="%s  ·  %s" % [game.day_cycle.clock_text(),game.day_cycle.weather_name()]
	if game.navigation.has_destination:
		var nav=game.navigation
		var course="Arrived · select neutral" if nav.arrived else "On course"
		if nav.route.size()>1 and not nav.arrived:
			var point=nav.route[1]
			var local=game.boat.to_local(Vector3(point.x,game.boat.position.y,point.y))
			var angle=atan2(local.x,-local.z)
			if absf(angle)>0.18: course="Steer right →" if angle>0 else "← Steer left"
		route_label.text="%s · %d m\n%s" % [nav.destination_name,nav.remaining(Vector2(game.boat.position.x,game.boat.position.z)),course]
	else:
		route_label.text="Open the chart to plan your trip"

func reel_gesture(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and swipe_pointer<0:swipe_pointer=event.index
		elif not event.pressed and event.index==swipe_pointer:swipe_pointer=-1;reel_swipe=0
	if event is InputEventScreenDrag and event.index==swipe_pointer:
		reel_swipe-=event.relative.y
	elif event is InputEventMouseMotion and event.button_mask&MOUSE_BUTTON_MASK_LEFT:
		reel_swipe-=event.relative.y
	if reel_swipe>65:
		game.power_reel()
		reel_swipe=0

func build_shop() -> void:
	shop_panel = PanelContainer.new()
	shop_panel.set_anchors_and_offsets_preset(Control.PRESET_RIGHT_WIDE)
	shop_panel.offset_left = -550
	shop_panel.offset_right = -24
	shop_panel.offset_top = 24
	shop_panel.offset_bottom = -24
	shop_panel.add_theme_stylebox_override("panel",panel_style(Color(0.025,0.085,0.12,0.98),24))
	add_child(shop_panel)
	var column = VBoxContainer.new()
	column.add_theme_constant_override("separation",10)
	shop_panel.add_child(column)
	shop_title = label("Island tackle",22)
	column.add_child(shop_title)
	shop_tabs = HBoxContainer.new()
	shop_tabs.add_theme_constant_override("separation",8)
	column.add_child(shop_tabs)
	for category in ["Reels","Rods","Line","Boat","Boats"]:
		action(shop_tabs,category,func(): show_shop(category))
	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	column.add_child(scroll)
	shop_list = VBoxContainer.new()
	shop_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	shop_list.add_theme_constant_override("separation",14)
	scroll.add_child(shop_list)
	column.add_child(label("Earned MVR · in-game currency · tap a name to preview",12,MUTED))
	action(column,"Return to dinghy",game.leave_fishing)
	shop_panel.visible = false

func show_shop(category: String) -> void:
	shop_category = category
	shop_panel.visible = true
	shop_title.text = "Boat showroom" if category=="Boats" else ("Boat workshop" if category=="Boat" else "Island tackle house")
	for child in shop_list.get_children():
		shop_list.remove_child(child)
		child.queue_free()
	var first_id = ""
	for item in game.Catalog.ITEMS:
		if item.category!=category:
			continue
		if first_id.is_empty():
			first_id = item.id
		var row = HBoxContainer.new()
		row.add_theme_constant_override("separation",10)
		shop_list.add_child(row)
		var text_column = VBoxContainer.new()
		text_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(text_column)
		var name_label = label(item.name,17,MINT)
		name_label.custom_minimum_size.y = 48
		name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		name_label.mouse_filter = Control.MOUSE_FILTER_STOP
		name_label.gui_input.connect(func(event: InputEvent):
			if (event is InputEventMouseButton and event.pressed) or (event is InputEventScreenTouch and event.pressed):
				selected_item = item.id
				game.shop.show_item(item)
				preview_label.text=item.name+"\nDrag to rotate · use + / − to zoom"
		)
		text_column.add_child(name_label)
		var detail = label(item.detail,13,MUTED)
		detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		text_column.add_child(detail)
		var owned = game.item_owned(item.id)
		var active = game.equipped_boat==item.id if category=="Boats" else game.equipped.get(category)==item.id
		var locked=game.catches<int(item.get("unlock",0))
		var text = "Equipped" if active else ("Owned" if owned and category=="Boat" else ("Equip" if owned else "MVR %d" % game.item_price(item.id)))
		var buy = action(row,"%d catches" % item.unlock if locked else text,func():
			game.purchase_item(item.id)
			selected_item = item.id
			show_shop(shop_category)
		)
		buy.custom_minimum_size.x = 105
		buy.size_flags_horizontal = 0
		buy.add_theme_font_size_override("font_size",16)
		buy.disabled = locked or active or (owned and category=="Boat") or (not owned and game.coins<game.item_price(item.id))
		row.custom_minimum_size.y = 94
	if game.Catalog.item(selected_item).get("category")!=category:
		selected_item = first_id
	game.shop.show_item(game.Catalog.item(selected_item))
	preview_label.text=str(game.Catalog.item(selected_item).name)+"\nDrag to rotate · use + / − to zoom"
	refresh()

func hide_shop() -> void:
	if shop_panel:
		shop_panel.visible = false

func build_map() -> void:
	map_panel=PanelContainer.new()
	map_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	map_panel.offset_left=35
	map_panel.offset_right=-35
	map_panel.offset_top=25
	map_panel.offset_bottom=-25
	map_panel.add_theme_stylebox_override("panel",panel_style(Color("0a202e"),24))
	add_child(map_panel)
	var row=HBoxContainer.new()
	row.add_theme_constant_override("separation",20)
	map_panel.add_child(row)
	map_chart=preload("res://scripts/sea_map.gd").new()
	map_chart.game=game
	map_chart.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	map_chart.size_flags_vertical=Control.SIZE_EXPAND_FILL
	row.add_child(map_chart)
	var sidebar=VBoxContainer.new()
	sidebar.custom_minimum_size.x=300
	sidebar.add_theme_constant_override("separation",12)
	row.add_child(sidebar)
	sidebar.add_child(label("YOUR OCEAN CHART",13,MINT))
	sidebar.add_child(label("Plan your trip",28))
	var selected=label("Tap a fishing marker or open water to set a course. The route avoids islands.",17)
	selected.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	sidebar.add_child(selected)
	map_chart.selected_label=selected
	for legend in ["▲  Your boat / heading","□  Home dock and shops","○  Fishing spot","○  Grey: locked spot","─  Gold: planned route","+  Your waypoint"]:
		sidebar.add_child(label(legend,16,MUTED))
	var note=label("Prototype chart · fictional geography",12,MUTED)
	note.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	sidebar.add_child(note)
	action(sidebar,"Clear route",func(): game.navigation.clear())
	action(sidebar,"Back to your boat",toggle_map,true)
	map_panel.visible=false

func toggle_map() -> void:
	if menu_visible: return
	map_visible=not map_visible
	map_panel.visible=map_visible
	if map_visible:
		map_panel.move_to_front()
		game.driving_controls.release_pointers()
		game.driving_controls.neutral()
		game.drive.set_lever(0)
		game.reeling=false
	refresh()

func build_preview_card() -> void:
	preview_card=PanelContainer.new()
	add_child(preview_card)
	preview_card.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	preview_card.offset_left=24
	preview_card.offset_right=620
	preview_card.offset_top=-135
	preview_card.offset_bottom=-24
	preview_card.add_theme_stylebox_override("panel",panel_style(Color(0.025,0.085,0.12,0.95),20))
	var column=VBoxContainer.new()
	preview_card.add_child(column)
	preview_label=label("",19)
	column.add_child(preview_label)
	var row=HBoxContainer.new()
	row.add_child(label("INSPECT",12,MINT))
	column.add_child(row)
	action(row,"−",func(): game.shop.zoom=clampf(game.shop.zoom-0.15,0.7,1.5))
	action(row,"+",func(): game.shop.zoom=clampf(game.shop.zoom+0.15,0.7,1.5))
	preview_card.visible=false

func apply_glass(root: Node) -> void:
	if root is PanelContainer:
		var glass=ShaderMaterial.new()
		glass.shader=preload("res://shaders/ui_glass.gdshader")
		root.material=glass
	for child in root.get_children(): apply_glass(child)
