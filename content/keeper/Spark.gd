extends RigidBody2D

func _ready():
	scale = Vector2.ONE * rand_range(1, 2.5)
	$Sprite.modulate = lerp(Style.getColor(Style.keeper_highlight), Color.white, randf())
	$AnimationPlayer.playback_speed = rand_range(1.0, 5.0)
