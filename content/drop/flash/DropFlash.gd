extends AnimatedSprite

func _ready():
	pass


func _on_flashTimer_timeout():
	frame = 0
	play("flash")
	$flashTimer.wait_time = randf() * 5 + 5
	$flashTimer.start()
