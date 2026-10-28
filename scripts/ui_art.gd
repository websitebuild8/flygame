extends RefCounted
static var textures: Dictionary={}
static func icon(name: String) -> Texture2D:
 var path="res://assets/ui/icons/"+name+".svg"
 if not ResourceLoader.exists(path):path="res://assets/ui/icons/"+name+".png"
 return texture(path)
static func texture(path: String) -> Texture2D:
 if not textures.has(path):textures[path]=load(path)
 return textures[path]
static func fish(species: String) -> Texture2D:
 return texture("res://assets/ui/fish/"+species.to_lower().replace(" ","_")+".png")
static func medal(tier: int) -> Texture2D:
 return texture("res://assets/ui/medals/"+["bronze","silver","gold"][clampi(tier,0,2)]+".png")
static func picture(parent: Control,tex: Texture2D,dimensions: Vector2,color: Color=Color.WHITE) -> TextureRect:
 var rect=TextureRect.new();rect.texture=tex;rect.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;rect.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;rect.custom_minimum_size=dimensions;rect.modulate=color;rect.mouse_filter=Control.MOUSE_FILTER_IGNORE;parent.add_child(rect);return rect
static func button_icon(button: Button,name: String,size: int=25):
 button.icon=icon(name);button.expand_icon=true;button.add_theme_constant_override("icon_max_width",size);button.add_theme_constant_override("h_separation",9)
static func colours(button: Button,color: Color):
 for key in ["icon_normal_color","icon_hover_color","icon_pressed_color","icon_focus_color"]:button.add_theme_color_override(key,color)
