extends RigidBody2D

func _ready():
	Style.init($Sprite)
	$Sprite.frame = randi() % $Sprite.hframes
	apply_central_impulse(rand_range(100, 500) * (Vector2.UP.rotated(rand_range( - 1.8, 1.8))))

func _on_deathTimer_timeout():
	queue_free()

func _physics_process(delta):
	$Sprite.modulate.a = ease($deathTimer.time_left / $deathTimer.wait_time, 0.5)
