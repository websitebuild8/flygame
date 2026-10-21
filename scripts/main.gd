extends Node3D

const SAVE_PATH = "user://trip.json"
const DOCK = Vector3(0, 0, 12)
const SPOT = Vector3(0, 0, -45)
var boat: Node3D
var camera: Camera3D
var status: Label
var info: Label
var fish_button: Button
var message = "Welcome, Ishaq. Follow the golden buoy to fish."
var coins = 0
var catches = 0
var hold_value = 0
var upgrade = 0
var unlocked = false
var speed = 0.0
var elapsed = 0.0
var fishing = false
var fish_timer = 0.0
var progress = 0.0
var tension = 0.0
var reeling = false
var touch = {"forward": false, "back": false, "left": false, "right": false}
var rng = RandomNumberGenerator.new()

func _ready() -> void:
	rng.randomize()
	load_trip()
	build_world()
	build_ui()

func material(color: Color) -> StandardMaterial3D:
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.7
	return mat

func box(parent: Node3D, pos: Vector3, size: Vector3, color: Color) -> MeshInstance3D:
	var node = MeshInstance3D.new()
	var mesh = BoxMesh.new()
	mesh.size = size
	node.mesh = mesh
	node.material_override = material(color)
	parent.add_child(node)
	node.position = pos
	return node

func island(center: Vector3, radius: float) -> void:
	var sand = MeshInstance3D.new()
	var mesh = CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius + 4.0
	mesh.height = 2.0
	mesh.radial_segments = 32
	sand.mesh = mesh
	sand.material_override = material(Color("ead8a1"))
	add_child(sand)
	sand.position = center
	for i in range(7):
		var angle = float(i) * TAU / 7.0
		var point = center + Vector3(cos(angle) * radius * 0.55, 3.5, sin(angle) * radius * 0.55)
		box(self, point, Vector3(0.5, 5, 0.5), Color("846443"))
		for j in range(3):
			var leaf = box(self, point + Vector3(0, 2.4, 0), Vector3(5, 0.25, 1.1), Color("357a59"))
			leaf.rotation.y = float(j) * PI / 3.0

func build_world() -> void:
	var environment = WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.background_mode = Environment.BG_COLOR
	environment.environment.background_color = Color("8bcbdc")
	environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color = Color.WHITE
	environment.environment.ambient_light_energy = 0.65
	add_child(environment)
	var sun = DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50, -30, 0)
	add_child(sun)
	box(self, Vector3(0, -1.1, 0), Vector3(700, 1, 700), Color("139da7"))
	island(Vector3(-25, -0.4, 30), 19)
	island(Vector3(85, -0.4, -80), 24)
	box(self, Vector3(-8, 0.5, 14), Vector3(19, 0.6, 4), Color("8b6749"))
	box(self, SPOT + Vector3(0, 1, 0), Vector3(1, 2.5, 1), Color("f6c96b"))
	boat = Node3D.new()
	add_child(boat)
	boat.position = DOCK
	box(boat, Vector3.ZERO, Vector3(2.5, 0.6, 5), Color("f0e9d8"))
	box(boat, Vector3(-1.15, 0.5, 0), Vector3(0.2, 0.8, 5), Color("ebf6ef"))
	box(boat, Vector3(1.15, 0.5, 0), Vector3(0.2, 0.8, 5), Color("ebf6ef"))
	box(boat, Vector3(0, 0.5, 0.5), Vector3(2.2, 0.25, 0.8), Color("b18c61"))
	box(boat, Vector3(0, 0.2, 2.7), Vector3(0.65, 1.1, 0.6), Color("334452"))
	var rod = box(boat, Vector3(0.9, 1.7, -1.3), Vector3(0.06, 3, 0.06), Color("263c46"))
	rod.rotation.x = -0.5
	camera = Camera3D.new()
	add_child(camera)
	camera.current = true
	camera.fov = 65
	camera.position = boat.position + Vector3(0, 10, 15)
	camera.look_at(boat.position)

func button(parent: Control, title: String, action: Callable) -> Button:
	var item = Button.new()
	item.text = title
	item.custom_minimum_size = Vector2(130, 56)
	item.add_theme_font_size_override("font_size", 20)
	item.pressed.connect(action)
	parent.add_child(item)
	return item

func build_ui() -> void:
	var layer = CanvasLayer.new()
	add_child(layer)
	var root = MarginContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("margin_left", 26)
	root.add_theme_constant_override("margin_right", 26)
	root.add_theme_constant_override("margin_top", 22)
	root.add_theme_constant_override("margin_bottom", 22)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(root)
	var column = VBoxContainer.new()
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(column)
	var title = Label.new()
	title.text = "ISHAQ'S FISHING TRIP   /   FIRST VOYAGE"
	title.add_theme_font_size_override("font_size", 27)
	column.add_child(title)
	info = Label.new()
	column.add_child(info)
	status = Label.new()
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(status)
	var spacer = Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(spacer)
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	column.add_child(row)
	for entry in [["←", "left"], ["↑", "forward"], ["↓", "back"], ["→", "right"]]:
		var key: String = entry[1]
		var control = button(row, entry[0], func(): pass)
		control.custom_minimum_size.x = 64
		control.button_down.connect(func(): touch[key] = true)
		control.button_up.connect(func(): touch[key] = false)
	fish_button = button(row, "Cast / Reel", cast)
	fish_button.button_down.connect(func(): reeling = true)
	fish_button.button_up.connect(func(): reeling = false)
	button(row, "Sell catch", sell)
	button(row, "Upgrade · 100", buy_upgrade)
	button(row, "Return home", return_home)
	var hint = Label.new()
	hint.text = "WASD / arrows to drive • Space to cast; hold to reel • Placeholder islands, not a navigation map"
	hint.add_theme_font_size_override("font_size", 16)
	column.add_child(hint)

func _physics_process(delta: float) -> void:
	elapsed += delta
	if Input.is_physical_key_pressed(KEY_SPACE) and not fishing:
		if not reeling:
			cast()
		reeling = true
	elif not Input.is_physical_key_pressed(KEY_SPACE) and not fish_button.button_pressed:
		reeling = false
	if fishing:
		speed = 0
		fish_timer += delta
		if fish_timer < 2.5:
			message = "Bait in the water… wait for a bite."
		else:
			var pulling = reeling or Input.is_physical_key_pressed(KEY_SPACE)
			tension = clampf(tension + delta * (0.38 if pulling else -0.5), 0, 1)
			progress = clampf(progress + delta * (0.17 if pulling else -0.035), 0, 1)
			message = "Fish on! Hold Reel, release to ease tension. Landed %d%% · Tension %d%%" % [progress * 100, tension * 100]
			if tension >= 1:
				fishing = false
				message = "The line snapped. Ease off the reel next time."
			elif progress >= 1:
				land_fish()
	else:
		var throttle = float(touch.forward or Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP)) - float(touch.back or Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN))
		var steering = float(touch.left or Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT)) - float(touch.right or Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT))
		speed = move_toward(speed, throttle * (10.0 + upgrade * 4), delta * 5)
		boat.rotation.y += steering * delta * 1.2 * minf(absf(speed) / 2, 1)
		var next = boat.position - boat.basis.z * speed * delta
		var blocked = Vector2(next.x + 25, next.z - 30).length() < 23
		blocked = blocked or Vector2(next.x - 85, next.z + 80).length() < 28
		if not unlocked and next.x > 45:
			blocked = true
			message = "Catch 3 fish to unlock the eastern island waters."
		if not blocked and Vector2(next.x, next.z).length() < 250:
			boat.position = next
		else:
			speed = 0
	boat.position.y = sin(elapsed * 1.6) * 0.12
	var desired = boat.position + boat.basis.z * 15 + Vector3(0, 10, 0)
	camera.position = camera.position.lerp(desired, 1 - exp(-delta * 3))
	camera.look_at(boat.position + Vector3(0, 0.5, 0))
	info.text = "Coins %d   ·   Catch value %d   ·   Fish caught %d/3   ·   Boat level %d   ·   Buoy %dm   ·   %s" % [coins, hold_value, catches, upgrade + 1, boat.position.distance_to(SPOT), "Eastern waters unlocked" if unlocked else "Eastern waters locked"]
	status.text = message

func cast() -> void:
	if fishing:
		return
	if boat.position.distance_to(SPOT) > 14:
		message = "Drive within 14 metres of the golden buoy to fish."
		return
	if absf(speed) > 1:
		message = "Stop the boat before casting."
		return
	fishing = true
	fish_timer = 0
	progress = 0
	tension = 0

func land_fish() -> void:
	fishing = false
	var species = ["Skipjack tuna", "Yellowfin tuna", "Giant trevally"].pick_random()
	var value = rng.randi_range(35, 65)
	catches += 1
	hold_value += value
	unlocked = catches >= 3
	message = "%s landed! Worth %d coins. Return to the dock to sell.%s" % [species, value, " Eastern waters unlocked!" if catches == 3 else ""]
	save_trip()

func sell() -> void:
	if boat.position.distance_to(DOCK) > 18:
		message = "Return to the home dock to sell your catch."
		return
	message = "Sold your catch for %d coins." % hold_value
	coins += hold_value
	hold_value = 0
	save_trip()

func buy_upgrade() -> void:
	if boat.position.distance_to(DOCK) > 18:
		message = "Boat upgrades are available at the home dock."
	elif upgrade >= 2:
		message = "Your prototype dinghy is fully upgraded."
	elif coins < 100:
		message = "Earn 100 coins by catching and selling fish."
	else:
		coins -= 100
		upgrade += 1
		message = "Engine upgraded! Your dinghy now travels faster."
		save_trip()

func return_home() -> void:
	fishing = false
	speed = 0
	boat.position = DOCK
	boat.rotation = Vector3.ZERO
	message = "Back at the dock. Sell your catch or upgrade your dinghy."

func save_trip() -> void:
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify({"coins": coins, "catches": catches, "hold_value": hold_value, "upgrade": upgrade}))

func load_trip() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH))
	if parsed is Dictionary:
		coins = maxi(0, int(parsed.get("coins", 0)))
		catches = maxi(0, int(parsed.get("catches", 0)))
		hold_value = maxi(0, int(parsed.get("hold_value", 0)))
		upgrade = clampi(int(parsed.get("upgrade", 0)), 0, 2)
		unlocked = catches >= 3
