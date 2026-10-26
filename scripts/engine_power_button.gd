extends Button
var running=false
func _ready():
	text=""
	for state in ["normal","hover","pressed","disabled","focus"]:
		add_theme_stylebox_override(state,StyleBoxEmpty.new())
func set_running(value: bool):
	if running!=value:
		running=value;queue_redraw()
	tooltip_text="Turn engine off" if running else "Start engine"
func _draw():
	var center=size*.5
	var radius=minf(size.x,size.y)*.41
	if running:
		for layer in range(5):
			draw_circle(center,radius+float(5-layer),Color(.2,1,.55,.025+layer*.012))
	draw_circle(center,radius,Color("175c46") if running else Color("304b42"))
	var glow=Color("65ffab") if running else Color("6f9582")
	draw_arc(center,radius,0,TAU,64,Color(glow,.85 if running else .35),2,true)
	draw_arc(center,12,-PI*.3,PI*1.3,32,glow,3,true)
	draw_line(center+Vector2(0,-17),center+Vector2(0,-3),glow,3,true)
	if has_focus():draw_arc(center,radius+3,0,TAU,64,Color("d5f7e7"),1,true)
