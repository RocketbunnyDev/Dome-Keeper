extends Node2D

onready var hit_mask_sprite_scene = preload("res://content/dome/damage_mask/hit_mask_sprite.tscn")

func _ready():
	Data.listen(self, "dome.health")

func hit(position, damage):
	
	var damagePercent: float = 100 * damage / float(Data.of("dome.maxHealth"))
	var power = 20.0 / damagePercent
	
	var relative_position = position - $Cracks.global_position
	var sprite = hit_mask_sprite_scene.instance()
	sprite.material = sprite.material.duplicate()
	sprite.material.set_shader_param("power", power)
	$Viewport.add_child(sprite)
	
	
	sprite.position = relative_position

func propertyChanged(property: String, oldValue, newValue):
	if oldValue and newValue > oldValue:
		heal(oldValue, newValue)
	
	var damage = 1 - newValue / float(Data.of("dome.maxHealth"))
	$Cracks.material.set_shader_param("damage", damage)

func heal(oldValue, newValue):
	var maxHealth = Data.of("dome.maxHealth")
	var previous_health_remaining: float = maxHealth - oldValue
	var current_health_remaining: float = maxHealth - newValue
	var shrink = 1 - (current_health_remaining / previous_health_remaining)
	propagate_call("shrink_mask", [shrink])

