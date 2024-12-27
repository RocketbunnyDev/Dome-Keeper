extends Tutorial

func _ready():
	splitTutorialText("level.tutorial.assessor.reflect.desc", "LabelDesc1", "LabelDesc2")
	listen("keeper2.reflectsphere")

func propertyChanged(property: String, oldValue, newValue):
	match property:
		
		"keeper2.reflectsphere":
			if newValue:
				trigger()

func process_confirm(delta: float):
	if tutorialParent.getBallActionCooldown() > 0.0:
		confirm()
