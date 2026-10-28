extends ScrollContainer
## One vertical gesture owner across cards/buttons, with frame-independent inertia.
## Native scrollbars and keyboard navigation remain available.
const DEADZONE=9.0
var pointer=-99
var origin=Vector2.ZERO
var last=Vector2.ZERO
var dragging=false
var velocity=0.0
var last_sample=0
var last_motion=0
var suppress_until=0
var wheel_active=false
var wheel_target=0.0
var restore_value=-1.0
var restore_frames=0
func _ready():
 # Native touch drag is replaced here, so two inertia systems cannot compete.
 scroll_deadzone=2147483647
 horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
 vertical_scroll_mode=ScrollContainer.SCROLL_MODE_RESERVE
 get_v_scroll_bar().changed.connect(func():
  if restore_value>=0:set_value(restore_value)
 )
 get_v_scroll_bar().custom_minimum_size.x=18
 get_v_scroll_bar().add_theme_constant_override("grabber_min_size",48)
 mouse_force_pass_scroll_events=false
func local_point(point: Vector2) -> Vector2:return get_global_transform_with_canvas().affine_inverse()*point
func contains(point: Vector2) -> bool:return Rect2(Vector2.ZERO,size).has_point(local_point(point))
func limit() -> float:
 var bar=get_v_scroll_bar();return maxf(0,bar.max_value-bar.page)
func set_value(value: float):get_v_scroll_bar().value=clampf(value,0,limit())
func accepts_tap() -> bool:return not dragging and Time.get_ticks_msec()>=suppress_until
func excluded(point: Vector2) -> bool:
 # Allow direct scrollbar dragging and selecting/editing a boat name.
 for child in find_children("*","Control",true,false):
  if (child is LineEdit or child is ScrollBar) and child.is_visible_in_tree() and child.get_global_rect().has_point(point):return true
 return false
func _input(event: InputEvent):
 if not is_visible_in_tree():return
 if event is InputEventScreenTouch:
  if event.pressed:begin(event.index,event.position)
  elif event.index==pointer:end()
 elif event is InputEventScreenDrag and event.index==pointer:
  move(event.position)
 elif event is InputEventMouseButton:
  if event.device==-1:return # Mouse events emulated from touch use the touch owner.
  if event.button_index==MOUSE_BUTTON_LEFT:
   if event.pressed:begin(-1,event.position)
   elif pointer==-1:end()
  elif event.pressed and contains(event.position) and event.button_index in [MOUSE_BUTTON_WHEEL_UP,MOUSE_BUTTON_WHEEL_DOWN]:
   wheel((-1 if event.button_index==MOUSE_BUTTON_WHEEL_UP else 1)*80*event.factor);get_viewport().set_input_as_handled()
 elif event is InputEventMouseMotion and event.device!=-1 and pointer==-1:move(event.position)
 elif event is InputEventPanGesture and contains(event.position):
  wheel(event.delta.y*32);get_viewport().set_input_as_handled()
func begin(id: int,point: Vector2):
 if pointer!=-99 or not contains(point):return
 if excluded(point):stop();return
 var was_moving=absf(velocity)>30 or wheel_active
 velocity=0;wheel_active=false
 if limit()<=0:return
 restore_value=-1;restore_frames=0
 pointer=id;origin=local_point(point);last=origin;last_sample=Time.get_ticks_usec();last_motion=last_sample;dragging=false
 if was_moving:
  # A tap during a fling stops the list, without opening the card beneath it.
  suppress_until=Time.get_ticks_msec()+220
  propagate_notification(Control.NOTIFICATION_SCROLL_BEGIN);get_viewport().set_input_as_handled()
func move(point: Vector2):
 var at=local_point(point);var total=at-origin
 if not dragging and absf(total.y)>DEADZONE and absf(total.y)>absf(total.x)*.7:
  dragging=true;suppress_until=Time.get_ticks_msec()+220
  propagate_notification(Control.NOTIFICATION_SCROLL_BEGIN);scroll_started.emit()
 if dragging:
  var now=Time.get_ticks_usec();var dt=clampf(float(now-last_sample)/1000000,.008,.06)
  var distance=at.y-last.y
  set_value(get_v_scroll_bar().value-distance)
  velocity=lerpf(velocity,clampf(-distance/dt,-2200,2200),.55)
  last_motion=now;get_viewport().set_input_as_handled()
 last=at;last_sample=Time.get_ticks_usec()
func end():
 if pointer==-99:return
 if dragging:
  suppress_until=Time.get_ticks_msec()+200
  if Time.get_ticks_usec()-last_motion>100000:velocity=0
  scroll_ended.emit();propagate_notification(Control.NOTIFICATION_SCROLL_END)
 pointer=-99;dragging=false
func wheel(amount: float):
 restore_value=-1;restore_frames=0
 velocity=0
 wheel_target=clampf((wheel_target if wheel_active else get_v_scroll_bar().value)+amount,0,limit());wheel_active=true
func _process(delta: float):
 if not is_visible_in_tree():stop();return
 if restore_frames>0:
  set_value(restore_value);restore_frames-=1
  if restore_frames==0:restore_value=-1
 if pointer!=-99:return
 if wheel_active:
  var value=lerpf(get_v_scroll_bar().value,wheel_target,1-exp(-delta*17))
  if absf(value-wheel_target)<.5:value=wheel_target;wheel_active=false
  set_value(value)
 elif absf(velocity)>8:
  var before=get_v_scroll_bar().value
  set_value(before+velocity*(1-exp(-6*delta))/6)
  velocity*=exp(-6*delta)
  if is_equal_approx(before,get_v_scroll_bar().value):velocity=0
 else:velocity=0
func stop():
 if dragging:propagate_notification(Control.NOTIFICATION_SCROLL_END);scroll_ended.emit()
 pointer=-99;dragging=false;velocity=0;wheel_active=false;restore_value=-1;restore_frames=0
func reset_to(value: float=0):
 stop();restore_value=value;restore_frames=3;set_value(value)
 # Range.changed reapplies after the new page has actually been laid out.
func _notification(what: int):
 if what==NOTIFICATION_APPLICATION_FOCUS_OUT:stop()
