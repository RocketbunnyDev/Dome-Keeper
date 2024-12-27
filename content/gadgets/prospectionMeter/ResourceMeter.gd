extends ColorRect

var goalFilling: float = 0.0

func _process(delta):
	var diff = 13 * goalFilling - rect_size.x
	diff = clamp(diff + sign(diff) * 1.0, 0, rect_size.x)
	rect_size.x += 0.75 * delta * (diff)
