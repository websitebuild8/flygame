extends PanelContainer
const Catalog=preload("res://scripts/gear_catalog.gd")
const Clay=preload("res://scripts/clay_theme.gd")
var game: Node3D
var category="Reels"
var item_id="island_reel"
var style_id="original"
var item_picker: OptionButton
var tabs: HBoxContainer
var choices: VBoxContainer
var use_button: Button
var status: Label
var item_ids: Array[String]=[]
func _ready():
 set_anchors_and_offsets_preset(Control.PRESET_RIGHT_WIDE);offset_left=-550;offset_right=-24;offset_top=24;offset_bottom=-24
 var column=VBoxContainer.new();column.add_theme_constant_override("separation",10);add_child(column)
 var header=HBoxContainer.new();column.add_child(header)
 var title=game.interface.label("Make it yours",25);title.size_flags_horizontal=Control.SIZE_EXPAND_FILL;header.add_child(title)
 game.interface.action(header,"Back",close).size_flags_horizontal=Control.SIZE_SHRINK_END
 column.add_child(game.interface.label("Cosmetic finishes · no gameplay boosts",14))
 tabs=HBoxContainer.new();column.add_child(tabs)
 for role in ["Rods","Reels","Boats"]:game.interface.action(tabs,role,func():show_category(role))
 item_picker=OptionButton.new();item_picker.custom_minimum_size.y=54;column.add_child(item_picker)
 item_picker.item_selected.connect(func(index):select_item(item_ids[index]))
 var scroll=ScrollContainer.new();scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL;scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;column.add_child(scroll)
 choices=VBoxContainer.new();choices.size_flags_horizontal=Control.SIZE_EXPAND_FILL;choices.add_theme_constant_override("separation",10);scroll.add_child(choices)
 status=game.interface.label("",15);status.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;column.add_child(status)
 use_button=game.interface.action(column,"Use free colour",apply_choice,true)
 Clay.apply(self);visible=false
func open():
 visible=true;game.interface.shop_panel.visible=false
 category=game.interface.shop_category if game.interface.shop_category in ["Rods","Reels","Boats"] else "Boats"
 show_category(category)
func show_category(role: String):
 category=role;item_ids.clear();item_picker.clear()
 for entry in Catalog.ITEMS:
  if entry.category==category and game.item_owned(entry.id):item_ids.append(entry.id);item_picker.add_item(entry.name)
 for button in tabs.get_children():Clay.button(button,false,button.text==category)
 var current=game.equipped_boat if category=="Boats" else str(game.equipped[category])
 var index=maxi(0,item_ids.find(current));item_picker.select(index);select_item(item_ids[index])
func select_item(id: String):
 item_id=id;style_id=game.cosmetics.selected(id);refresh_choices();preview()
func refresh_choices():
 for child in choices.get_children():choices.remove_child(child);child.queue_free()
 for finish in game.cosmetics.STYLES:
  var row=HBoxContainer.new();row.add_theme_constant_override("separation",10);choices.add_child(row)
  var swatch=PanelContainer.new();swatch.custom_minimum_size=Vector2(42,42);swatch.size_flags_vertical=Control.SIZE_SHRINK_CENTER;row.add_child(swatch)
  var material=Clay.surface(finish.color,12);material.content_margin_left=0;material.content_margin_right=0;material.content_margin_top=0;material.content_margin_bottom=0;swatch.add_theme_stylebox_override("panel",material)
  var button=game.interface.action(row,finish.name+(" · Level %d reward"%finish.unlock_level if finish.has("unlock_level") else (" · Premium preview" if finish.premium else " · Free")),func():
   style_id=finish.id;refresh_choices();preview()
  )
  Clay.button(button,false,finish.id==style_id)
 update_status()
func preview():
 game.shop.show_item(Catalog.item(item_id))
 preload("res://scripts/cosmetic_art.gd").apply(game.shop.preview_model,category,game.cosmetics.style(style_id))
func update_status():
 var finish=game.cosmetics.style(style_id)
 var earned=finish.has("unlock_level")
 var locked=not game.cosmetics.can_use(style_id)
 var active=game.cosmetics.selected(item_id)==style_id
 status.text=("Reach angler level %d to earn this finish."%finish.unlock_level) if locked and earned else "Premium Finish Collection · one permanent pack. Purchases are coming soon." if locked else ("This finish is equipped on this item." if active else "Free finish. Your equipment stats stay the same.")
 use_button.disabled=locked or active;use_button.text=("Level %d gift"%finish.unlock_level if earned else "Coming soon") if locked else ("In use" if active else "Use free colour")
func apply_choice():
 if game.equip_style(item_id,style_id):update_status()
func close():
 visible=false;game.interface.show_shop(game.interface.shop_category)
