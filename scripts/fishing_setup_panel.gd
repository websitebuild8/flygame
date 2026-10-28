extends PanelContainer
const Clay=preload("res://scripts/clay_theme.gd")
const Conditions=preload("res://scripts/fishing_conditions.gd")
var game: Node3D
var list: VBoxContainer
var forecast: Label
var pickers: Array[OptionButton]=[]
func _ready():
 set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);anchor_left=.20;anchor_right=.80;anchor_top=.08;anchor_bottom=.92
 add_theme_stylebox_override("panel",Clay.surface())
 var column=VBoxContainer.new();column.add_theme_constant_override("separation",12);add_child(column)
 var heading=HBoxContainer.new();column.add_child(heading)
 var title=game.interface.label("Read the water",26,Clay.INK);title.size_flags_horizontal=Control.SIZE_EXPAND_FILL;heading.add_child(title)
 var back=game.interface.action(heading,"Done",close);Clay.button(back,true)
 var scroll=ScrollContainer.new();scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL;scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;column.add_child(scroll)
 list=VBoxContainer.new();list.size_flags_horizontal=Control.SIZE_EXPAND_FILL;list.add_theme_constant_override("separation",10);scroll.add_child(list)
 for entries in [["Lure finish",Conditions.LURES],["Target depth",Conditions.DEPTHS]]:
  list.add_child(game.interface.label(entries[0],19,Clay.INK));var picker=OptionButton.new();picker.custom_minimum_size.y=52;picker.add_theme_font_size_override("font_size",18)
  for value in entries[1]:picker.add_item(value)
  list.add_child(picker);pickers.append(picker)
 pickers[0].item_selected.connect(func(index):game.fishing_conditions.lure=index;game.feedback.lure.apply_finish(index);update_forecast();game.save_trip())
 pickers[1].item_selected.connect(func(index):game.fishing_conditions.depth=index;update_forecast();game.save_trip())
 forecast=game.interface.label("",17,Clay.INK);forecast.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;list.add_child(forecast)
 var note=game.interface.label("All choices are free. These are game-balanced chances, never guaranteed catches. Depth selects the feeding layer; it does not change cast controls. Reef flash suits a deeper jig; skirts favour bluewater species.",14,Clay.MUTED);note.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;list.add_child(note)
 Clay.apply(self);visible=false
func open():
 if game.fishing:return
 game.interface.menu_visible=true;game.reeling=false;game.driving_controls.release_pointers();visible=true;move_to_front()
 pickers[0].select(game.fishing_conditions.lure);pickers[1].select(game.fishing_conditions.depth);update_forecast();game.interface.refresh()
func close():visible=false;game.interface.menu_visible=false;game.interface.refresh()
func update_forecast():
 var spot=game.World.nearest(game.boat.position);var total=0.0;var weights=[]
 for index in spot.fish:
  var value=game.fishing_conditions.weight(game.World.FISH[index].name,game.day_cycle.hours,game.day_cycle.weather,game.feedback.overhead);weights.append(value);total+=value
 forecast.text=spot.name+" · "+game.day_cycle.clock_text()+" · "+game.day_cycle.weather_name()+"\n\nLikely visitors with this setup:\n"
 for i in range(spot.fish.size()):forecast.text+="%s · %d%%\n"%[game.World.FISH[spot.fish[i]].name,roundi(weights[i]/total*100)]
