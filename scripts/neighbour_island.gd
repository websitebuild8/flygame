extends "res://scripts/kelaa_island.gd"
func _init(title: String):
 map=preload("res://scripts/neighbour_map_data.gd").new(title)
 is_home=false;island_title=title
