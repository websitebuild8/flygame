extends PanelContainer
## Lightweight illustrated voyage hub. Live gameplay stays behind the menu.
const Clay=preload("res://scripts/clay_theme.gd")
const Art=preload("res://scripts/ui_art.gd")
const Board=preload("res://scripts/reward_board.gd")
var game: Node3D
var primary: Button
var wallet: Label
var rank: Label
var rank_bar: ProgressBar
var ready_label: Label
var portrait: TextureRect
func _ready():
 set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);anchor_left=.07;anchor_right=.93;anchor_top=.08;anchor_bottom=.92
 set_meta("clay_surface",true);add_theme_stylebox_override("panel",Clay.surface())
 var column=VBoxContainer.new();column.add_theme_constant_override("separation",12);add_child(column)
 var head=HBoxContainer.new();head.add_theme_constant_override("separation",12);column.add_child(head);Art.picture(head,Art.medal(2),Vector2(38,45))
 var titles=VBoxContainer.new();titles.size_flags_horizontal=Control.SIZE_EXPAND_FILL;head.add_child(titles);label(titles,"ISHAQ’S FISHING TRIP",27);label(titles,"HA & HDh · The Maldives",14,Clay.MUTED)
 var settings=button(head,"","gear",func():game.interface.toggle_menu());settings.custom_minimum_size.x=58;settings.tooltip_text="Trip settings"
 var body=HBoxContainer.new();body.add_theme_constant_override("separation",22);body.size_flags_vertical=Control.SIZE_EXPAND_FILL;column.add_child(body)
 var voyage=VBoxContainer.new();voyage.size_flags_horizontal=Control.SIZE_EXPAND_FILL;voyage.add_theme_constant_override("separation",10);body.add_child(voyage)
 label(voyage,"YOUR NEXT CAST\nSTARTS HERE",28);label(voyage,"Explore island waters. Land your next record.",16,Clay.MUTED)
 rank=label(voyage,"",18,Clay.SEA)
 rank_bar=ProgressBar.new();rank_bar.show_percentage=false;rank_bar.custom_minimum_size.y=10;voyage.add_child(rank_bar)
 wallet=label(voyage,"",20)
 var spacer=Control.new();spacer.size_flags_vertical=Control.SIZE_EXPAND_FILL;voyage.add_child(spacer)
 primary=button(voyage,"Set sail","arrowRight",func():game.interface.start_trip(),true);primary.custom_minimum_size.y=62
 var shell=PanelContainer.new();shell.size_flags_horizontal=Control.SIZE_EXPAND_FILL;shell.add_theme_stylebox_override("panel",Clay.surface(Clay.CARD,20));body.add_child(shell)
 var feature=VBoxContainer.new();feature.add_theme_constant_override("separation",6);shell.add_child(feature)
 label(feature,"BUILD YOUR COLLECTION",13,Clay.SEA)
 portrait=Art.picture(feature,Art.fish("Yellowfin tuna"),Vector2(0,95))
 label(feature,"One more species. One more story.",16)
 ready_label=label(feature,"",17,Clay.SEA)
 button(feature,"Rewards & medals","trophy",func():open_club("Rewards"))
 var links=HBoxContainer.new();links.add_theme_constant_override("separation",10);column.add_child(links)
 button(links,"Collection","book",func():open_club("Collection"))
 button(links,"Chart","chart",func():game.interface.start_trip();game.interface.toggle_map())
 button(links,"Diving spots","pin",open_diving)
 var shop=button(links,"Harbour shop","shoppingCart",func():game.interface.start_trip();game.open_shop())
 shop.disabled=not game.at_home_dock();shop.tooltip_text="Stop at an island harbour to shop" if shop.disabled else "Rods, reels and vessels"
 refresh_data()
 primary.call_deferred("grab_focus")
func label(parent: Control,text: String,font_size: int,color: Color=Clay.INK) -> Label:
 var result=Label.new();result.text=text;result.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;result.add_theme_font_size_override("font_size",font_size);result.add_theme_color_override("font_color",color);parent.add_child(result);return result
func button(parent: Control,text: String,icon: String,callback: Callable,strong: bool=false) -> Button:
 var result=Button.new();result.text=text;result.size_flags_horizontal=Control.SIZE_EXPAND_FILL;result.set_meta("primary_action",strong);Clay.button(result,strong);Art.colours(result,Clay.FOAM if strong else Clay.INK);Art.button_icon(result,icon,23);parent.add_child(result);result.pressed.connect(callback);return result
func refresh_data():
 var level=game.experience.status();rank.text="Lv %d · %s"%[level.level,level.title];rank_bar.max_value=level.next;rank_bar.value=level.current
 wallet.text="MVR %d  ·  %d / %d species"%[game.coins,game.trip_progress.records.size(),game.World.FISH.size()]
 var summary=Board.overview(game);ready_label.text="%d reward%s ready"%[summary.count,"" if summary.count==1 else "s"] if summary.count>0 else "Earn XP, medals and free finishes"
 primary.text="Continue trip" if game.catches>0 else "Set sail"
func open_club(tab: String):game.interface.start_trip();game.interface.logbook.open(tab)

func open_diving():
 game.interface.start_trip()
 if game.has_method("open_diving_chart"):game.call("open_diving_chart")
 else:game.interface.toggle_map()
