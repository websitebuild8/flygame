extends SceneTree
# Godot's Android exporter can report a blank configuration error when the host
# prefers desktop textures and mobile texture imports have not been enabled.
func _initialize() -> void:
	if not ProjectSettings.get_setting("rendering/textures/vram_compression/import_etc2_astc",false):
		printerr("Android export requires rendering/textures/vram_compression/import_etc2_astc=true in project.godot. Enable it before importing on CI.")
		quit(1)
		return
	var preset=ConfigFile.new()
	if preset.load("res://export_presets.cfg")!=OK or preset.get_value("preset.0","platform","")!="Android":
		printerr("Missing Android export preset in export_presets.cfg")
		quit(1)
		return
	print("PASS: mobile texture imports enabled and Android export preset present")
	quit()
