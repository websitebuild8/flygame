extends Node3D
## Adapted CC0 lighthouse: white column, gallery and coloured entrance lantern.
const MODEL=preload("res://assets/models/harbour/white_beacon.glb")
var red=true
var lamp: StandardMaterial3D
func _ready():
 name="RedHarbourBeacon" if red else "GreenHarbourBeacon"
 add_to_group("harbour_beacons")
 var source=MODEL.instantiate();add_child(source);source.scale=Vector3(1.4,1,1.4)
 for part in source.find_children("*","MeshInstance3D",true,false):
  part.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;part.visibility_range_end=160
  if str(part.name).begins_with("Lens"):
   lamp=part.get_active_material(0).duplicate();lamp.albedo_color=Color("d64542") if red else Color("32b77b");lamp.emission=lamp.albedo_color;part.material_override=lamp
 update_light(0,0)
func update_light(night: float,clock: float):
 if lamp:
  var flash=.20 if fmod(clock,4.0)>.8 else 1.0
  lamp.emission_energy_multiplier=lerpf(.20,.55+flash*2.0,night)
