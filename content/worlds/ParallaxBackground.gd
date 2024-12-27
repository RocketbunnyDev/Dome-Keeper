extends Node2D

export (Array) var scrollSpeeds: = []
export (bool) var enabled: = true

func _ready():
	var z = - get_child_count() + 1
	for c in get_children():
		if c.z_index == 0:
			c.z_index = z
		z += 1

func _process(delta):
	if not enabled:
		return 
	
	var cam = InputSystem.getCamera()
	if not cam:
		return 
	
	var dy: = 0.0
	dy = cam.position.y - cam.getCameraRestPosition(1 / cam.zoom.x)
	for i in range(0, get_child_count()):
		var off = scrollSpeeds[i]
		var background = get_child(i)
		background.position.y = (1.0 - off) * dy


