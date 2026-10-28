extends Control
## Gesture surface occupies only the 3D preview, never the product list.
var game: Node3D
var touches: Dictionary={}
var mouse_drag=false
func _ready():
 mouse_filter=Control.MOUSE_FILTER_STOP
 mouse_default_cursor_shape=Control.CURSOR_DRAG
 tooltip_text="Drag to rotate · pinch to zoom · mouse wheel to zoom"
 visibility_changed.connect(func():
  if not is_visible_in_tree():release()
 )
func release():touches.clear();mouse_drag=false
func set_zoom(value: float):
 game.shop.zoom=clampf(value,.7,1.8);game.shop.manual_spin=2.5
func _gui_input(event: InputEvent):
 if not game.shop_mode or not game.app_active or game.interface.menu_visible or not game.shop:return
 if event is InputEventScreenTouch:
  if event.pressed and touches.size()<2:touches[event.index]=event.position
  elif not event.pressed:touches.erase(event.index)
  mouse_drag=false;accept_event()
 elif event is InputEventScreenDrag and touches.has(event.index):
  if touches.size()==2:
   var ids=touches.keys();var before=Vector2(touches[ids[0]]).distance_to(touches[ids[1]])
   touches[event.index]=event.position
   var after=Vector2(touches[ids[0]]).distance_to(touches[ids[1]])
   if before>8 and after>8:set_zoom(game.shop.zoom*after/before)
  else:
   touches[event.index]=event.position;game.shop.angle+=event.relative.x*.009;game.shop.manual_spin=2.5
  accept_event()
 elif event is InputEventMagnifyGesture:
  set_zoom(game.shop.zoom*event.factor);accept_event()
 elif event is InputEventMouseButton and touches.is_empty():
  if event.button_index==MOUSE_BUTTON_LEFT:mouse_drag=event.pressed;accept_event()
  elif event.pressed and event.button_index in [MOUSE_BUTTON_WHEEL_UP,MOUSE_BUTTON_WHEEL_DOWN]:
   set_zoom(game.shop.zoom*(1.12 if event.button_index==MOUSE_BUTTON_WHEEL_UP else 1/1.12));accept_event()
 elif event is InputEventMouseMotion and mouse_drag and touches.is_empty():
  game.shop.angle+=event.relative.x*.009;game.shop.manual_spin=2.5;accept_event()

func _notification(what: int):
 if what==NOTIFICATION_APPLICATION_FOCUS_OUT:release()
