extends Node

var id: String

func _process(delta):
	var p = get_parent()
	if p.timeAlive >= 17 and p.consecutiveReflections == 0:
		Achievements.triggerIfOpen(id)
		queue_free()
