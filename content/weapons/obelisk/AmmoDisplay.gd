extends Node2D

const AMMO_SINGLE = preload("res://content/weapons/obelisk/AmmoDisplaySingle.tscn")

var maxAmmo = 12

export  var radius = 0
export (float, 360) var starting_angle = 0.0
var origin = Vector2.ZERO
var ammo_displays: = []

func init(newMaxAmmo)->void :
	for c in get_children():
		ammo_displays.erase(c)
		c.queue_free()
	maxAmmo = newMaxAmmo
	var index = 0
	
	while index < maxAmmo:
		
		var new_node = AMMO_SINGLE.instance()
		add_child(new_node)
		new_node.init(maxAmmo)
		new_node.ammo_index = index
		
		
		



		new_node.rotation_degrees = (float(index) / float(maxAmmo)) * 360 + starting_angle
		new_node.set_radius(radius)
		
		ammo_displays.append(new_node)
		index += 1

func set_current_ammo(value: int):
	for a in ammo_displays:
		if a.ammo_index < value:
			a.appear()
		else:
			a.vanish()

func empty_ammo():
	set_current_ammo(0)

func fill_ammo():
	set_current_ammo(maxAmmo)
