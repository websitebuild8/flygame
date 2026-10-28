extends RefCounted
## Native 2D styles: no blur, viewport copy, textures downloaded or per-frame effects.
const INK=Color("203b40")
const MUTED=Color("506968")
const PAPER=Color("f3eee2")
const CARD=Color("e6ede3")
const SEA=Color("176459")
const FOAM=Color("eaf6ed")
static func surface(color: Color=PAPER,radius: int=26,pressed: bool=false) -> StyleBoxFlat:
 var s=StyleBoxFlat.new();s.bg_color=color;s.set_corner_radius_all(radius)
 s.set_border_width_all(1);s.border_width_top=2;s.border_color=Color("fffdf5") if not pressed else Color("b1c3b5")
 s.shadow_color=Color(.12,.21,.20,.22);s.shadow_size=3 if pressed else 9;s.shadow_offset=Vector2(0,2 if pressed else 5)
 s.content_margin_left=20;s.content_margin_right=20;s.content_margin_top=14;s.content_margin_bottom=14
 return s
static func button(item: Button,primary: bool=false,selected: bool=false):
 var strong=primary or selected
 var bg=SEA if strong else CARD;var fg=FOAM if strong else INK
 for state in ["normal","hover","pressed","disabled"]:
  var color=bg
  if state=="hover":color=bg.lightened(.07)
  elif state=="pressed":color=bg.darkened(.10)
  elif state=="disabled":color=Color("dddcd1")
  var box=surface(color,18,state=="pressed");box.content_margin_left=14;box.content_margin_right=14;box.content_margin_top=9;box.content_margin_bottom=9
  if strong:box.border_color=Color("3e8a7a")
  item.add_theme_stylebox_override(state,box)
 for state in ["font_color","font_hover_color","font_pressed_color","font_focus_color"]:item.add_theme_color_override(state,fg)
 item.add_theme_color_override("font_disabled_color",Color("556562"))
 var focus=StyleBoxFlat.new();focus.bg_color=Color.TRANSPARENT;focus.set_corner_radius_all(18);focus.set_border_width_all(3);focus.border_color=Color("a3552c");item.add_theme_stylebox_override("focus",focus)
 item.custom_minimum_size.y=maxf(54,item.custom_minimum_size.y)
static func switch_icon(on: bool) -> ImageTexture:
 var image=Image.new();var bg="#176459" if on else "#697c75";var cx="43" if on else "17"
 image.load_svg_from_string('<svg xmlns="http://www.w3.org/2000/svg" width="60" height="34"><rect x="1" y="2" width="58" height="30" rx="15" fill="'+bg+'"/><circle cx="'+cx+'" cy="17" r="12" fill="#fffdf5"/></svg>')
 return ImageTexture.create_from_image(image)
static func apply(root: Node):
 if root is PanelContainer:
  root.set_meta("clay_surface",true);root.material=null;root.add_theme_stylebox_override("panel",surface())
 if root is Label:
  var old=root.get_theme_color("font_color");var muted=old.is_equal_approx(Color("a6c0c7"))
  root.add_theme_color_override("font_color",MUTED if muted else (SEA if old.is_equal_approx(Color("8bdecb")) else INK))
 if root is RichTextLabel:
  root.add_theme_color_override("default_color",MUTED);root.add_theme_color_override("font_selected_color",INK)
 if root is Button:
  if root is CheckButton:
   root.add_theme_color_override("font_color",INK);root.add_theme_color_override("font_hover_color",SEA);root.add_theme_color_override("font_pressed_color",INK)
   root.add_theme_icon_override("checked",switch_icon(true));root.add_theme_icon_override("unchecked",switch_icon(false))
   root.add_theme_stylebox_override("normal",StyleBoxEmpty.new());root.add_theme_stylebox_override("hover",StyleBoxEmpty.new())
  else:
   button(root,root.get_meta("primary_action",false))
   if root is OptionButton:
    var popup=root.get_popup();popup.add_theme_stylebox_override("panel",surface(PAPER,18));popup.add_theme_stylebox_override("hover",surface(SEA,12,true));popup.add_theme_color_override("font_color",INK);popup.add_theme_color_override("font_hover_color",FOAM);popup.add_theme_font_size_override("font_size",18);popup.add_theme_constant_override("v_separation",14)
 for child in root.get_children():apply(child)
