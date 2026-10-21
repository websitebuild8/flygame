extends Control
## Independent pointer ownership permits wheel and throttle simultaneously.
var wheel_command = 0.0
var lever_value = 0.0
var wheel_display = 0.0
var shown_speed = 0.0
var shown_gear = "N"
var shown_rpm = 0.0
var shift_waiting = false
var skin="dinghy"
var pov=false
var pov_wheel=Vector2.ZERO
var pov_lever=Vector2.ZERO
var rim_color=Color("729097")
var spokes=3
var wheel_pointer = -99
var lever_pointer = -99
var previous_angle = 0.0
const WHEEL_LIMIT = 2.3
var accent = Color("83dfd0")
var white = Color("edf5f2")
var muted = Color("9bb5bc")

func _ready() -> void:
	custom_minimum_size.y = 224
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func wheel_center() -> Vector2:
	return pov_wheel if pov else Vector2(94,size.y*0.5)

func rail_center() -> Vector2:
	return pov_lever if pov else Vector2(size.x-63,size.y*0.5)

func local_point(point: Vector2) -> Vector2:
	return get_global_transform_with_canvas().affine_inverse()*point

func release_pointers() -> void:
	wheel_pointer = -99
	lever_pointer = -99
	wheel_command = 0

func neutral() -> void:
	lever_value = 0
	queue_redraw()

func _input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		release_pointers()
		return
	if event is InputEventScreenTouch:
		pointer(event.index,local_point(event.position),event.pressed)
	elif event is InputEventScreenDrag:
		drag(event.index,local_point(event.position))
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		pointer(-1,local_point(event.position),event.pressed)
	elif event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		drag(-1,local_point(event.position))

func pointer(id: int, point: Vector2, down: bool) -> void:
	if down:
		if point.distance_to(wheel_center()) < 87 and wheel_pointer == -99:
			wheel_pointer = id
			previous_angle = (point-wheel_center()).angle()
			get_viewport().set_input_as_handled()
		elif Rect2(rail_center()-Vector2(60,108),Vector2(120,216)).has_point(point) and lever_pointer == -99:
			lever_pointer = id
			update_lever(point)
			get_viewport().set_input_as_handled()
	else:
		if wheel_pointer == id:
			wheel_pointer = -99
			wheel_command = 0
		if lever_pointer == id:
			lever_pointer = -99
	queue_redraw()

func drag(id: int, point: Vector2) -> void:
	if wheel_pointer == id:
		var angle = (point-wheel_center()).angle()
		wheel_command = clampf(wheel_command+wrapf(angle-previous_angle,-PI,PI)/WHEEL_LIMIT,-1,1)
		previous_angle = angle
		get_viewport().set_input_as_handled()
	if lever_pointer == id:
		update_lever(point)
		get_viewport().set_input_as_handled()
	queue_redraw()

func update_lever(point: Vector2) -> void:
	lever_value = clampf((rail_center().y-point.y)/74,-1,1)
	if absf(lever_value)<0.13:
		lever_value = 0

func panel(rect: Rect2) -> void:
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.025,0.085,0.12,0.90)
	style.set_corner_radius_all(24)
	style.set_border_width_all(1)
	style.border_color = Color(0.65,0.88,0.88,0.16)
	draw_style_box(style,rect)

func text_at(text: String, position: Vector2, font_size: int, color: Color) -> void:
	draw_string(ThemeDB.fallback_font,position,text,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,color)

func set_skin(id: String) -> void:
	skin=id
	accent={"dinghy":Color("83dfd0"),"skiff":Color("90c8ff"),"runner":Color("f2b16e"),"launch":Color("dec58c")}.get(id,Color("83dfd0"))
	rim_color={"dinghy":Color("729097"),"skiff":Color("e3e9e2"),"runner":Color("384854"),"launch":Color("8e6447")}.get(id,Color("729097"))
	spokes={"dinghy":3,"skiff":5,"runner":3,"launch":6}.get(id,3)
	queue_redraw()

func _draw() -> void:
	if pov:
		var wheel=wheel_center()
		draw_arc(wheel,77,-PI*.85,-PI*.15,30,Color(accent,0.5),2,true)
		text_at("DRAG WHEEL",wheel+Vector2(-45,100),12,accent)
		var lever=rail_center()
		text_at("F",lever+Vector2(38,-72),16,accent)
		text_at("N",lever+Vector2(38,4),16,white)
		text_at("R",lever+Vector2(38,78),16,accent)
		draw_line(lever+Vector2(29,-74),lever+Vector2(29,74),Color(accent,0.45),2,true)
		draw_circle(lever+Vector2(29,-lever_value*74),5,accent)
		panel(Rect2(size.x-188,size.y-70,188,70))
		text_at("%.1f kn · %s" % [shown_speed*1.94384,shown_gear],Vector2(size.x-170,size.y-28),24,white)
		return
	panel(Rect2(0,0,188,size.y))
	panel(Rect2(size.x-130,0,130,size.y))
	var c = wheel_center()
	text_at("STEERING",Vector2(52,23),13,muted)
	draw_circle(c,72,Color("182e3b"))
	if skin=="runner":
		draw_arc(c,69,PI*0.8,PI*2.2,65,rim_color,13,true)
		draw_line(c+Vector2(-56,40),c+Vector2(56,40),rim_color,13,true)
		draw_line(c+Vector2(-64,-10),c+Vector2(-65,16),accent,5,true)
		draw_line(c+Vector2(64,-10),c+Vector2(65,16),accent,5,true)
	else:
		draw_arc(c,69,0,TAU,80,rim_color,13,true)
		if skin=="launch":
			draw_arc(c,65,0,TAU,80,Color("b28b60"),2,true)
			draw_arc(c,73,0,TAU,80,Color("5d4938"),1,true)
	draw_arc(c,68,-PI*0.85,-PI*0.15,30,Color("c5d5d3"),4,true)
	var angle = wheel_display*WHEEL_LIMIT
	for i in range(spokes):
		var a = angle+float(i)*TAU/spokes-PI/2
		draw_line(c+Vector2(cos(a),sin(a))*12,c+Vector2(cos(a),sin(a))*60,Color("9db4b9"),9,true)
	draw_circle(c,23,Color("29424e"))
	draw_arc(c,22,0,TAU,40,Color("6c9298"),1.5,true)
	text_at("I",c+Vector2(-4,6),18,accent)
	var marker = c+Vector2(sin(angle),-cos(angle))*69
	draw_circle(marker,4,accent)
	text_at("DRAG TO TURN",Vector2(39,size.y-13),12,muted)
	var rail = rail_center()
	text_at("TWIN DRIVE" if skin=="launch" else ("SPORT" if skin=="runner" else "THROTTLE"),rail+Vector2(-38,-89),13,muted)
	draw_line(rail+Vector2(0,-72),rail+Vector2(0,74),Color("344e5b"),14,true)
	if skin=="launch":
		draw_line(rail+Vector2(-15,-72),rail+Vector2(-15,74),Color("7d745a"),5,true)
	for i in range(9):
		var y = rail.y-72+i*18
		draw_line(Vector2(rail.x-16,y),Vector2(rail.x+16,y),Color("729095"),1,true)
	text_at("F",rail+Vector2(33,-64),18,accent)
	text_at("N",rail+Vector2(33,6),18,white)
	text_at("R",rail+Vector2(33,78),18,Color("f0bf82"))
	var handle = rail-Vector2(0,lever_value*74)
	draw_line(rail,handle,Color("c3d7d4"),6,true)
	var knob = StyleBoxFlat.new()
	knob.bg_color = accent if lever_value>=0 else Color("edb877")
	knob.set_corner_radius_all(10)
	draw_style_box(knob,Rect2(handle-Vector2(27,14),Vector2(54,28)))
	for i in [-1,0,1]:
		draw_line(handle+Vector2(i*7,-6),handle+Vector2(i*7,6),Color("31666b"),2,true)
	var center_x = 264.0 if size.x>700 else (188.0+size.x-130)/2.0
	panel(Rect2(center_x-61,49,122,160))
	text_at("%02.1f" % (shown_speed*1.94384),Vector2(center_x-37,92),34,white)
	text_at("KNOTS",Vector2(center_x-22,112),12,muted)
	text_at(shown_gear,Vector2(center_x-10,155),29,accent)
	text_at("SHIFTING" if shift_waiting else "%d%%" % (absf(lever_value)*100),Vector2(center_x-28,176),12,muted)
	for i in range(5):
		draw_rect(Rect2(center_x-25+i*11,194,7,5),accent if shown_rpm > float(i)/5 else Color("2b4552"))
