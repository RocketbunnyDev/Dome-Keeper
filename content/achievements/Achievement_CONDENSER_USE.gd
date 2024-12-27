extends Node

var id: String

var count: = 0
var lastVal: = 0

func _ready():
	count = Data.ofOr("achievement.condenser.use", 0)
	lastVal = count

func _process(delta):
	var newVal = get_parent().resourceCount
	var d = lastVal - newVal
	if d > 0:
		count += d
	if count >= 10:
		Achievements.triggerIfOpen(id)
		queue_free()
	else:
		Data.apply("achievement.condenser.use", count)
	lastVal = newVal
