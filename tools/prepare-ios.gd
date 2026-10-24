extends SceneTree
## Set CI metadata without committing Apple account details to the repository.
func fail(message: String) -> void:
	printerr(message)
	quit(1)
func _initialize() -> void:
	var team=OS.get_environment("APPLE_TEAM_ID").strip_edges()
	var bundle=OS.get_environment("BUNDLE_ID").strip_edges()
	var build=OS.get_environment("IOS_BUILD_NUMBER").strip_edges()
	var team_pattern=RegEx.new()
	team_pattern.compile("^[A-Z0-9]{10}$")
	if team_pattern.search(team)==null:
		fail("Set APPLE_TEAM_ID to your 10-character Apple Developer Team ID in the ios_testflight variable group.")
		return
	if bundle.is_empty() or bundle.count(".")<2:
		fail("Set BUNDLE_ID to the identifier registered in Apple Developer and App Store Connect.")
		return
	if not build.is_valid_int() or int(build)<1 or int(build)>9999:
		fail("IOS_BUILD_NUMBER must be a positive integer below 10000 and greater than any previously uploaded build.")
		return
	var preset=ConfigFile.new()
	if preset.load("res://export_presets.cfg")!=OK or preset.get_value("preset.1","name","")!="iOS TestFlight":
		fail("Missing iOS TestFlight preset.")
		return
	preset.set_value("preset.1.options","application/app_store_team_id",team)
	preset.set_value("preset.1.options","application/bundle_identifier",bundle)
	preset.set_value("preset.1.options","application/version",build)
	if preset.save("res://export_presets.cfg")!=OK:
		fail("Could not save iOS export settings.")
		return
	# Load the committed artwork directly, before the CI asset-import step.
	var image=Image.new()
	if image.load("res://assets/icons/ios-app-icon.png")!=OK:
		fail("Missing iOS artwork: assets/icons/ios-app-icon.png")
		return
	if image.get_width()!=1024 or image.get_height()!=1024 or image.is_invisible() or image.detect_alpha():
		fail("The iOS icon must be an opaque 1024 by 1024 PNG.")
		return
	image.convert(Image.FORMAT_RGB8)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://build"))
	if image.save_png("res://build/ios-icon.png")!=OK:
		fail("Could not save iOS icon.")
		return
	print("Prepared iOS TestFlight: ",bundle," build ",build)
	quit()
