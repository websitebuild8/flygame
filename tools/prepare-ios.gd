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
	# Original opaque icon. Godot generates all required iPhone icon sizes from it.
	var svg='<svg xmlns="http://www.w3.org/2000/svg" width="1024" height="1024" viewBox="0 0 1024 1024"><rect width="1024" height="1024" fill="#073e52"/><circle cx="512" cy="512" r="407" fill="#126b79"/><path d="M190 520 Q420 220 733 498 L870 365 L850 645 L729 552 Q420 815 190 520Z" fill="#d8f2ed"/><path d="M420 350 L535 240 L597 350 M416 671 L530 752 L582 660" fill="#54d1bc"/><circle cx="291" cy="493" r="28" fill="#073e52"/><path d="M240 833 Q510 720 790 833" fill="none" stroke="#54d1bc" stroke-width="20"/></svg>'
	var image=Image.new()
	if image.load_svg_from_string(svg)!=OK:
		fail("Could not generate iOS icon.")
		return
	image.convert(Image.FORMAT_RGB8)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://build"))
	if image.save_png("res://build/ios-icon.png")!=OK:
		fail("Could not save iOS icon.")
		return
	print("Prepared iOS TestFlight: ",bundle," build ",build)
	quit()
