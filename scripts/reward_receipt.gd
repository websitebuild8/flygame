extends Control
## A receipt confirms an already-saved claim; this screen never awards currency.
const Clay=preload("res://scripts/clay_theme.gd")
const Art=preload("res://scripts/ui_art.gd")
var game: Node3D
var panel: PanelContainer
var heading: Label
var amount: Label
var experience: Label
var extra: Label
var medal: TextureRect
func _ready():
 set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);mouse_filter=Control.MOUSE_FILTER_STOP
 var backdrop=ColorRect.new();backdrop.color=Color(.015,.055,.075,.76);backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);add_child(backdrop)
 panel=PanelContainer.new();add_child(panel);panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);panel.anchor_left=.25;panel.anchor_right=.75;panel.anchor_top=.12;panel.anchor_bottom=.88;panel.add_theme_stylebox_override("panel",Clay.surface())
 var margin=MarginContainer.new();panel.add_child(margin)
 var column=VBoxContainer.new();column.add_theme_constant_override("separation",10);margin.add_child(column)
 medal=Art.picture(column,Art.medal(2),Vector2(70,72))
 heading=label(column,"REWARD COLLECTED",24,Clay.INK)
 var line=HBoxContainer.new();line.alignment=BoxContainer.ALIGNMENT_CENTER;line.add_theme_constant_override("separation",12);column.add_child(line);Art.picture(line,Art.icon("coin"),Vector2(32,32));amount=label(line,"MVR 0",29,Color("8b591b"))
 experience=label(column,"+0 XP",25,Clay.SEA)
 extra=label(column,"",16,Clay.MUTED)
 var hint=label(column,"Saved to your trip",14,Clay.MUTED);hint.size_flags_vertical=Control.SIZE_EXPAND_FILL
 var button=Button.new();button.text="Continue";Clay.button(button,true);column.add_child(button);button.pressed.connect(close);button.set_meta("receipt_continue",true)
 visible=false
func label(parent: Control,text: String,font_size: int,color: Color) -> Label:
 var result=Label.new();result.text=text;result.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;result.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;result.add_theme_font_size_override("font_size",font_size);result.add_theme_color_override("font_color",color);parent.add_child(result);return result
func open(prize: Dictionary):
 if prize.is_empty():return
 amount.text="MVR %d"%int(prize.get("mvr",0));experience.text="+%d XP"%int(prize.get("xp",0))
 medal.texture=Art.medal(clampi(int(prize.get("stars",3))-1,0,2))
 heading.text="LEVEL UP!" if prize.get("level_up",false) else "REWARD COLLECTED"
 var details: Array[String]=[]
 if prize.get("level_up",false):details.append("Level %d"%int(prize.get("level",1)))
 if not prize.get("gifts",[]).is_empty():details.append("Finish unlocked · "+", ".join(prize.gifts))
 extra.text="\n".join(details);extra.visible=not details.is_empty();visible=true;move_to_front()
 for button in panel.find_children("*","Button",true,false):button.grab_focus()
func close():visible=false
