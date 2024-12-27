extends TextureRect

var goalDir: float = 0.0

func _process(delta):
	if goalDir - rect_rotation > 180:
		goalDir -= 360
	elif goalDir - rect_rotation < - 180:
		goalDir += 360
	rect_rotation = rect_rotation + (goalDir - rect_rotation) * delta
