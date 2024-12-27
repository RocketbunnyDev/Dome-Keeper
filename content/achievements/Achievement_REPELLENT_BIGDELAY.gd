extends Node

var id: String

func _process(delta):
	if GameWorld.waveDelay >= 0.5 * GameWorld.getTimeBetweenWaves():
		Achievements.triggerIfOpen(id)
		queue_free()
