extends Node2D


func _ready():
	$AnimatedSprite.play("burst")


func flip():
	$AnimatedSprite.flip_h = true


func _on_AnimatedSprite_animation_finished():
	queue_free()
