extends Node

var id: String

func _ready():
	Data.listen(self, "shield.strength")
	Data.listen(self, "shield.additionalstrength")

func propertyChanged(property: String, oldValue, newValue):
	match property:
		
		"shield.additionalstrength":
			finishIfEnough(newValue + Data.of("shield.strength"))
		"shield.strength":
			finishIfEnough(newValue + Data.of("shield.additionalstrength"))

func finishIfEnough(newValue):
	if newValue >= 150:
		Achievements.triggerIfOpen(id)
		Data.unlisten(self, "shield.strength")
		queue_free()
