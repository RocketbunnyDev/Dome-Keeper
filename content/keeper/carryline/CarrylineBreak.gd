extends Node2D

var target: Vector2

func _ready():
	var angle = target.angle_to_point(global_position)
	rotation = angle
	
	var length = (target - global_position).length()
	$Particles2D.position.x = length / 2
	$Particles2D.process_material.emission_box_extents.x = length / 2
	


	
	Style.init(self)

	
func _on_AnimationPlayer_animation_finished(anim_name):
	queue_free()
