extends Node

var id: String

func _ready():
	Data.listen(self, "prestige.score")

func propertyChanged(property: String, oldValue, newValue):
	if GameWorld.currentLoadingSavegame:
		return 
	
	match property:
		
		"prestige.score":
			if newValue - oldValue >= 200:
				Achievements.triggerIfOpen(id)
				Data.unlisten(self, "prestige.score")
				queue_free()
