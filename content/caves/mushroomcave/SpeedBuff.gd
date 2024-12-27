extends Particles2D

func _physics_process(delta):
	emitting = false
	if Level.keeper:
		var speedBuff = Data.of("keeper.speedBuff")
		var maxSpeed = Data.keeper("maxSpeed")
		var velocity = Level.keeper.move
		var speed = velocity.length()
		global_position = Level.keeper.global_position
		rotation = lerp(rotation, velocity.angle(), 0.2)
		rotation = velocity.angle()
		if speedBuff and speed > 0.8 * maxSpeed:
			emitting = true
