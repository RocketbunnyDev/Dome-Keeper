extends Node

var id: String

func _ready():
	Data.listen(self, "orchard.remainingbuffduration")

func propertyChanged(property: String, oldValue, newValue):
	match property:
		
		"orchard.remainingbuffduration":
			if newValue >= 0.6 * GameWorld.getTimeBetweenWaves():
				Achievements.triggerIfOpen(id)
				Data.unlisten(self, "orchard.remainingbuffduration")
				queue_free()
