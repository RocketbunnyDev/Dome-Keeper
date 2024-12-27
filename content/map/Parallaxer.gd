extends Node

export (float) var start_offset: = 0.6
export (float) var scaling: = 0.6

var basePos: Vector2

func _ready():
	basePos = get_child(0).position

func _process(delta):
	var cam = InputSystem.getCamera()
	if not cam:
		return 
	
	var a: = start_offset
	for i in range(0, get_child_count() - 1):
		var background = get_child(i)
		background.position = basePos + (cam.global_position - background.global_position) * a
		a *= pow(scaling, 1.5)
