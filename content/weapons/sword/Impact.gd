extends AnimatedSprite

func _ready():
	play("hit")

func _on_Impact_animation_finished():
	queue_free()
