extends Node

var id: String

func _ready():
	if GameWorld.modeVariation == CONST.MODE_PRESTIGE_COBALT:
		queue_free()
		return 
	
	Data.listen(self, "inventory.sand")

func propertyChanged(property: String, oldValue, newValue):
	match property:
		
		"inventory.sand":
			if newValue >= 8:
				Achievements.triggerIfOpen(id)
				Data.unlisten(self, "inventory.sand")
				queue_free()
