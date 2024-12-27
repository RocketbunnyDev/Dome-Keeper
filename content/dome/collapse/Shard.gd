extends RigidBody2D

func _ready():
	Style.init(self)
	
	
	var n = randi() % $Sprite.hframes
	$Sprite.frame = n
	
	
	apply_central_impulse(Vector2(randf() * 100, 0).rotated(randf() * - PI))
