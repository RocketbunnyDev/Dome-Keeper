extends PathFollow2D


export (Vector2) var axisModulation: Vector2

var rotationCenter: Vector2

var actor

func _process(delta):
	var angle = (position - position * axisModulation - rotationCenter).angle() + PI * 0.5
	if angle >= PI - 0.01:
		
		angle -= 2 * PI
	
	actor.rotation = clamp(angle, - 1.0 * PI, 1.0 * PI)
	actor.position = position

func moveBy(move: float)->float:
	var newOffset = clamp(unit_offset + move, 0.0, 1.0)
	var thisMove = newOffset - unit_offset
	unit_offset = newOffset
	return thisMove
