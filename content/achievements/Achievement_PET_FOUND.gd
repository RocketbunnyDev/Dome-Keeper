extends Node

var id: String

func _process(delta):
	if get_parent().hatched and Data.of("keeper.insidedome"):
		Achievements.triggerIfOpen(id)
		queue_free()
