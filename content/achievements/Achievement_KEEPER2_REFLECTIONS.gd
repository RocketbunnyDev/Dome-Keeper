extends Node

var id: String

func _process(delta):
	if get_parent().consecutiveReflections >= 15:
		Achievements.triggerIfOpen(id)
		queue_free()
