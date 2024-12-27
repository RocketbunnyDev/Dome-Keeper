extends Area2D


func _process(delta):
	position += Vector2(0, - 150).rotated(rotation) * delta
