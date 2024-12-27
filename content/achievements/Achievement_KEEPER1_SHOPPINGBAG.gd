extends Node

var id: String

func _ready():
	Data.listen(self, "keeper.insidedome")

func propertyChanged(property: String, oldValue, newValue):
	match property:
		
		"keeper.insidedome":
			if newValue and Level.keeper:
				if Level.keeper.carriedCarryables.size() >= 20:
					Achievements.triggerIfOpen(id)
					Data.unlisten(self, "keeper.insidedome")
					queue_free()
