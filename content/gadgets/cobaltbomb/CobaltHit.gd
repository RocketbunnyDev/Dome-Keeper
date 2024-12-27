extends Node2D

func _ready():
	$AnimatedSprite.play("hit")
	rotation = randf() * TAU
	Style.init(self)

func _on_AnimatedSprite_animation_finished():
	queue_free()
