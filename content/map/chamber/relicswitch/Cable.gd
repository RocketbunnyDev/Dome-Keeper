extends AnimatedSprite

var prefix: = "mine_"
var centerOffset: = 0.0
var inverted: = true

func _ready():
	playing = true
	visible = false

func activate():
	play(animation.replace("off", "on"), inverted)
	$ambSound.play()

func deactivate():
	play(animation.replace("on", "off"), inverted)
	$ambSound.stop()

func tileDestroyed(tileCoord: Vector2):
	visible = true

func asChamberCable(invert: = false):
	prefix = "chamber_"
	inverted = invert
	z_index = - 1

func setDestinationPos(destinationPos: Vector2, originPosition: = global_position):
	rotation = 0
	flip_h = false
	flip_v = false
	
	var delta = destinationPos - originPosition
	
	var angle = delta.angle()
	if angle < 0:
		angle += 2 * PI
	
	var step = 2 * PI / 8.0
	for i in 10:
		if angle <= i * step + step * 0.5:
			match int(i):
				0:
					setAnimation("off_straight")
					if randf() > 0.5:
						rotation = - 0.5 * PI
					else:
						rotation = 0.5 * PI
						flip_v = true
				1:
					setAnimation("off_diag")
					if randf() > 0.5:
						rotation = 0.5 * PI
						flip_v = true
				2:
					setAnimation("off_straight")
					flip_h = randf() > 0.5
				3:
					setAnimation("off_diag")
					if randf() > 0.5:
						flip_h = true
					else:
						rotation = 0.5 * PI
				4:
					setAnimation("off_straight")
					if randf() > 0.5:
						rotation = - 0.5 * PI
						flip_v = true
					else:
						rotation = 0.5 * PI
				5:
					setAnimation("off_diag")
					if randf() > 0.5:
						flip_v = true
						rotation = - 0.5 * PI
					else:
						rotation = PI
				6:
					setAnimation("off_straight")
					rotation = PI
					if randf() > 0.5:
						flip_h = true
				7:
					setAnimation("off_diag")
					if randf() > 0.5:
						rotation = - 0.5 * PI
					else:
						rotation = PI
						flip_h = true
				8:
					setAnimation("off_straight")
					rotation = - 0.5 * PI
					flip_v = randf() > 0.5
				_:
					print("niop ")
					print(angle)
			break
		
	if abs(delta.x) > abs(delta.y):
		delta.y = 0
	else:
		delta.x = 0
	
	position = delta.normalized() * centerOffset
	offset.y = - 10 if flip_v else 10

func setAnimation(ani: String):
	play(prefix + ani + "_" + str(1 + randi() % 5))
