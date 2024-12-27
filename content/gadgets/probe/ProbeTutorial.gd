extends Tutorial

func _ready():
	listen("probe.chargesremaining")
	
	splitTutorialText("level.tutorial.probe.popup_1", "Label1", "Label2")

func propertyChanged(property: String, oldValue, newValue):
	match property:
		
		"probe.chargesremaining":
			if oldValue and newValue < oldValue:
				confirm()

func process_trigger(delta: float)->bool:
	return Level.keeper.position.y > 100.0
