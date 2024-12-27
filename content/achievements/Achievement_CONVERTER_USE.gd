extends Node

var id: String

var count: = 0
var lastVal: = 0

func _ready():
	count = Data.ofOr("achievement.converter.use", 0)
	lastVal = count

func _process(delta):
	var newVal = get_parent().state
	if newVal > 0:
		if lastVal == 0:
			lastVal = 1
			count += 1
			if count >= 10:
				Achievements.triggerIfOpen(id)
				queue_free()
			else:
				Data.apply("achievement.converter.use", count)
	else:
		lastVal = 0
