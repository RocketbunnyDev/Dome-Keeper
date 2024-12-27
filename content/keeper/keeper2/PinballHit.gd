extends AnimatedSprite

func _ready():
	play("hit")


func _on_PinballHit_animation_finished():
	queue_free()
