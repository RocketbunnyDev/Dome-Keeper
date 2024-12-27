extends Node2D

const DirtParticle = preload("res://content/map/tile/DirtParticle.tscn")
var direction: Vector2
var type: String
var biome_color: Color

func _ready():
	$dust.modulate = biome_color * 1.3
	$dust.modulate.a = 1.0
	
	rotation = direction.angle()
	if get_tree().get_nodes_in_group("dirt_particles").size() > 200:
		return 
	
	for _i in range(14):
		var t = DirtParticle.instance()
		t.type = type
		t.modulate = biome_color
		t.position = position + Vector2(rand_range( - 10, 10), rand_range( - 10, 10))
		t.apply_central_impulse(direction.rotated(rand_range( - 0.6, 0.6)) * rand_range( - 1, 6))
		get_parent().call_deferred("add_child", t)
	
