extends SceneTree
const Paint=preload("res://scripts/cosmetic_art.gd")
const Cosmetics=preload("res://scripts/cosmetics.gd")
func _initialize():call_deferred("checks")
func styled(root: Node3D) -> int:
 var count=0
 for mesh in root.find_children("*","MeshInstance3D",true,false):
  for i in range(mesh.mesh.get_surface_count()):
   var material=mesh.get_active_material(i)
   if material is ShaderMaterial and material.shader==Paint.Paint:count+=1
 return count
func checks():
 var game=load("res://scenes/main.tscn").instantiate();game.save_path="user://cosmetic-check.json";root.add_child(game);game.set_physics_process(false);game.interface.start_trip()
 var money=game.coins;var inventory=game.inventory.duplicate(true);var power=game.Catalog.item("island_rod").power;var speed=game.World.vessel("skiff").speed
 assert(game.equip_style("island_rod","lagoon") and game.equip_style("island_reel","seafoam") and game.equip_style("skiff","lagoon"),"Free colours equip independently on owned rods/reels/boats")
 var blank=game.feedback.equipment.get_meta("authored_blank")
 assert(blank.get_surface_override_material(0).get_shader_parameter("custom_paint"),"Live rod uses custom blank finish while retaining the bending shader")
 assert(styled(game.feedback.equipment.get_meta("reel"))>0 and styled(game.boat_visual)>0,"Imported reel and boat get local paint materials")
 assert(game.coins==money and game.inventory==inventory and game.Catalog.item("island_rod").power==power and game.World.vessel("skiff").speed==speed,"Cosmetics do not charge MVR or change game balance")
 var old=game.cosmetics.selected("skiff")
 assert(not game.equip_style("skiff","midnight") and game.cosmetics.selected("skiff")==old,"Premium preview cannot equip without a real purchase integration")
 assert(not game.equip_style("launch","seafoam"),"Unowned boats cannot receive equipped finishes")
 assert(not game.cosmetics.choose("skiff","bad_id"),"Unknown styles are rejected")
 var save=JSON.parse_string(FileAccess.get_file_as_string(game.save_path));save.cosmetic_styles.skiff="midnight";save["owned_premium"]=true
 var file=FileAccess.open(game.save_path,FileAccess.WRITE);file.store_string(JSON.stringify(save));file.close();game.load_trip()
 assert(game.cosmetics.selected("skiff")=="original" and game.cosmetics.selected("island_rod")=="lagoon","Ordinary save flags do not grant paid finishes; free styles survive reload")
 game.drive.engine_running=false;game.open_shop("Reels");game.interface.customisation.open();var ui=game.interface.customisation
 assert(ui.visible and not game.interface.shop_panel.visible,"Customisation opens from the existing shore shop")
 for category in ["Rods","Reels","Boats"]:
  ui.show_category(category)
  for finish in Cosmetics.STYLES:
   ui.style_id=finish.id;ui.preview();ui.update_status()
   assert(ui.use_button.disabled if finish.premium else true,"Premium choices are clearly preview-only")
  ui.style_id="seafoam";ui.apply_choice();assert(game.cosmetics.selected(ui.item_id)=="seafoam","Free choice applies through the UI")
 game.equip_style("skiff","original");assert(styled(game.boat_visual)==0,"Original restores original imported materials")
 for id in ["skiff","launch","glacier","grady"]:
  game.equipped_boat=id;game.apply_boat();Paint.apply(game.boat_visual,"Boats",Cosmetics.STYLES[5]);assert(styled(game.boat_visual)>0,"Premium finish previews on every hull")
  var sources=0
  for mesh in game.boat_visual.find_children("*","MeshInstance3D",true,false):
   for i in range(mesh.mesh.get_surface_count()):
    var mat=mesh.get_active_material(i)
    if mat is StandardMaterial3D and mat.transparency!=BaseMaterial3D.TRANSPARENCY_DISABLED:sources+=1
  assert(sources>0,"Imported transparent glass is retained")
 ui.close();assert(game.interface.shop_panel.visible and not ui.visible,"Back restores the normal shop")
 game.queue_free();await create_timer(.2).timeout
 print("PASS: free per-item finishes, persistent loadouts, original restoration, paid-preview lock, save tamper rejection, four hulls, protected glass and unchanged MVR/performance")
 quit()
