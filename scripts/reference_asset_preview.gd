extends PanelContainer
## Inspect the converted rig before applying it to the player's fishing pose.
const Clay=preload("res://scripts/clay_theme.gd")
const SOURCES=["res://assets/models/reference/yellowfin.glb","res://assets/models/reference/deep_blue.glb","res://assets/models/reference/rusty_jobfish.glb","res://assets/models/reference/giant_grouper.glb"]
var game: Node3D
var viewport: SubViewport
var camera: Camera3D
var model_frame: Node3D
var model: Node3D
var player: AnimationPlayer
var asset_picker: OptionButton
var clip_picker: OptionButton
var caption: Label
var angle=-.4
var pitch=.12
var zoom=1.0
var pointer=-99
var last_point=Vector2.ZERO
var reel_focus: Button
var selected=0
var clip_ids: Array[String]=[]
const CLIP_NAMES={"Swim01":"Swimming","Pulling01":"Fighting the line","Show01":"Catch / equipment display","Hurt01":"Fish reaction","Jump01":"Jumping","Waiting01":"Waiting for a bite","Reeling01":"Reeling in","Throwing01":"Casting"}
func _ready():
 set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);anchor_left=.04;anchor_right=.96;anchor_top=.05;anchor_bottom=.95
 add_theme_stylebox_override("panel",Clay.surface())
 var column=VBoxContainer.new();column.add_theme_constant_override("separation",12);add_child(column)
 var heading=HBoxContainer.new();column.add_child(heading)
 var title=Label.new();title.text="FISHING SHOWCASE";title.add_theme_font_size_override("font_size",23);title.add_theme_color_override("font_color",Clay.INK);title.size_flags_horizontal=Control.SIZE_EXPAND_FILL;heading.add_child(title)
 var back=Button.new();back.text="Back";Clay.button(back);heading.add_child(back);back.pressed.connect(close)
 var row=HBoxContainer.new();row.add_theme_constant_override("separation",15);row.size_flags_vertical=Control.SIZE_EXPAND_FILL;column.add_child(row)
 var view=SubViewportContainer.new();view.stretch=true;view.size_flags_horizontal=Control.SIZE_EXPAND_FILL;view.size_flags_vertical=Control.SIZE_EXPAND_FILL;view.custom_minimum_size=Vector2(300,220);row.add_child(view);view.gui_input.connect(gesture)
 viewport=SubViewport.new();viewport.size=Vector2i(640,500);viewport.own_world_3d=true;viewport.render_target_update_mode=SubViewport.UPDATE_DISABLED;view.add_child(viewport)
 var world=Node3D.new();viewport.add_child(world)
 var environment=WorldEnvironment.new();world.add_child(environment);environment.environment=Environment.new();environment.environment.background_mode=Environment.BG_COLOR;environment.environment.background_color=Color("213b43");environment.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;environment.environment.ambient_light_color=Color("d8e3e4");environment.environment.ambient_light_energy=.7;environment.environment.tonemap_mode=Environment.TONE_MAPPER_FILMIC
 var key=DirectionalLight3D.new();world.add_child(key);key.rotation_degrees=Vector3(-35,-25,0);key.light_energy=1.2;key.shadow_enabled=false
 var fill=DirectionalLight3D.new();world.add_child(fill);fill.rotation_degrees=Vector3(20,140,0);fill.light_energy=.55;fill.light_color=Color("a4cfdd");fill.shadow_enabled=false
 camera=Camera3D.new();world.add_child(camera);camera.current=true;camera.fov=40;camera.near=.01
 model_frame=Node3D.new();world.add_child(model_frame)
 var sidebar=VBoxContainer.new();sidebar.custom_minimum_size.x=255;sidebar.add_theme_constant_override("separation",12);row.add_child(sidebar)
 asset_picker=OptionButton.new();Clay.button(asset_picker);sidebar.add_child(asset_picker)
 for title_text in ["Yellowfin tuna","Deep Blue rod & reel","Rusty jobfish","Giant grouper"]:asset_picker.add_item(title_text)
 asset_picker.item_selected.connect(show_asset)
 clip_picker=OptionButton.new();Clay.button(clip_picker);sidebar.add_child(clip_picker);clip_picker.item_selected.connect(func(index):play_clip(clip_ids[index]))
 reel_focus=Button.new();reel_focus.text="Reel close-up";Clay.button(reel_focus);sidebar.add_child(reel_focus);reel_focus.pressed.connect(focus_reel)
 caption=Label.new();caption.add_theme_color_override("font_color",Clay.MUTED);caption.add_theme_font_size_override("font_size",16);caption.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;sidebar.add_child(caption)
 var hint=Label.new();hint.text="Drag to rotate · scroll to zoom\nChoose a movement to see it in action.";hint.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;hint.add_theme_color_override("font_color",Clay.MUTED);hint.add_theme_font_size_override("font_size",14);sidebar.add_child(hint)
 visible=false
func open():
 if game:
  game.interface.menu_visible=true;game.interface.menu.visible=false;game.driving_controls.release_pointers();game.reeling=false
 visible=true;move_to_front();viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS;show_asset(selected)
 if game:game.interface.refresh()
func close():
 visible=false;viewport.render_target_update_mode=SubViewport.UPDATE_DISABLED;pointer=-99
 if model:model_frame.remove_child(model);model.queue_free();model=null;player=null
 if game:game.interface.menu_visible=false;game.interface.refresh()
func show_asset(index: int):
 selected=index;asset_picker.select(index);reel_focus.visible=index==1;pointer=-99;angle=.5 if index==1 else 1.15;pitch=.12;zoom=1
 if model:model_frame.remove_child(model);model.queue_free()
 model=load(SOURCES[index]).instantiate();model_frame.add_child(model)
 for mesh in model.find_children("*","MeshInstance3D",true,false):mesh.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
 player=model.find_children("*","AnimationPlayer",true,false)[0];clip_picker.clear();clip_ids.clear()
 for clip in player.get_animation_list():clip_ids.append(clip);clip_picker.add_item(CLIP_NAMES.get(clip,clip))
 var start="Show01" if index==1 else "Swim01"
 for i in range(clip_picker.item_count):
  if clip_ids[i]==start:clip_picker.select(i)
 play_clip(start)
 caption.text="Deep Blue spinning outfit\nRod flex, reel retrieval and casting" if index==1 else ((["Yellowfin tuna","","Rusty jobfish · Rankarumas","Giant grouper · Mudu faana"][index])+"\nSwimming, fighting and catch celebrations")
 update_camera()
func play_clip(clip: String):
 var animation=player.get_animation(clip);animation.loop_mode=Animation.LOOP_LINEAR;player.active=true;player.play(clip)
 model_frame.transform=Transform3D.IDENTITY
 var bounds=AABB();var first=true
 for fraction in [0.0,.25,.5,.75,.99]:
  player.seek(animation.length*fraction,true);player.advance(0)
  var box=preload("res://scripts/rigged_asset_bounds.gd").measure(model_frame);bounds=box if first else bounds.merge(box);first=false
 var factor=2.0/maxf(bounds.size.x,maxf(bounds.size.y,bounds.size.z));model_frame.scale=Vector3.ONE*factor;model_frame.position=-bounds.get_center()*factor
 player.seek(0,true);player.advance(0);update_camera()
func update_camera():
 camera.position=Vector3(sin(angle)*2.8,1.1+pitch*2,cos(angle)*2.8)/zoom;camera.look_at(Vector3.ZERO)
func gesture(event: InputEvent):
 if event is InputEventMouseButton:
  if event.button_index==MOUSE_BUTTON_LEFT:pointer=-1 if event.pressed else -99;last_point=event.position
  elif event.pressed and event.button_index in [MOUSE_BUTTON_WHEEL_UP,MOUSE_BUTTON_WHEEL_DOWN]:zoom=clampf(zoom*(1.1 if event.button_index==MOUSE_BUTTON_WHEEL_UP else .9),.6,2.2);update_camera()
 elif event is InputEventMouseMotion and pointer==-1:
  angle-=(event.position.x-last_point.x)*.008;pitch=clampf(pitch+(event.position.y-last_point.y)*.004,-.4,.6);last_point=event.position;update_camera()
 elif event is InputEventScreenTouch:
  if event.pressed and pointer==-99:pointer=event.index;last_point=event.position
  elif not event.pressed and pointer==event.index:pointer=-99
 elif event is InputEventScreenDrag and event.index==pointer:
  angle-=event.relative.x*.008;pitch=clampf(pitch+event.relative.y*.004,-.4,.6);update_camera()

func focus_reel():
 if selected!=1:return
 model_frame.transform=Transform3D.IDENTITY
 var reel: MeshInstance3D
 for mesh in model.find_children("*","MeshInstance3D",true,false):
  if "Reel" in str(mesh.name):reel=mesh;break
 if not reel:return
 var bounds=reel.global_transform*preload("res://scripts/rigged_asset_bounds.gd").measure(reel)
 var factor=1.2/maxf(bounds.size.x,maxf(bounds.size.y,bounds.size.z));model_frame.scale=Vector3.ONE*factor;model_frame.position=-bounds.get_center()*factor;zoom=1;angle=.6;pitch=.0;update_camera()
