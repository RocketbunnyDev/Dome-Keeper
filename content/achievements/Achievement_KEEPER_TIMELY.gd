extends Node

var id: String
var wavePresentTime: float = - 2000
var enterDomeTime: float = - 1000

func _ready():
	Data.listen(self, "keeper.insidedome")
	Data.listen(self, "monsters.wavepresent")

func propertyChanged(property: String, oldValue, newValue):
	if GameWorld.currentLoadingSavegame:
		return 
	
	match property:
		
		"monsters.wavepresent":
			if newValue:
				wavePresentTime = GameWorld.runTime
				triggerIfClose()
		"keeper.insidedome":
			if newValue:
				if GameWorld.runTime - enterDomeTime < 20.0:
					
					enterDomeTime = GameWorld.runTime
				else:
					enterDomeTime = GameWorld.runTime
					triggerIfClose()

func triggerIfClose():
	if abs(wavePresentTime - enterDomeTime) <= 1.0:
		Achievements.triggerIfOpen(id)
		Data.unlisten(self, "monsters.wavepresent")
		Data.unlisten(self, "keeper.insidedome")
		queue_free()
