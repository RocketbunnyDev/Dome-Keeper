extends Sprite

func _ready():
	material.set_shader_param("coord", global_position)
