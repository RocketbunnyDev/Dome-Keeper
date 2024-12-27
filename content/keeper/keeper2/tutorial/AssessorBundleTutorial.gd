extends Tutorial

var bundlesActive: = false

func _ready():
	splitTutorialText("level.tutorial.assessor.bundle.desc1", "LabelDesc1", "LabelDesc2")
	listen("keeper2.bundlespheres")

func propertyChanged(property: String, oldValue, newValue):
	match property:
		
		"keeper2.bundlespheres":
			if newValue:
				bundlesActive = true

func process_trigger(delta: float)->bool:
	if bundlesActive:
		return tutorialParent.carryables.size() > 0
	else:
		return false

func process_confirm(delta: float):
	if get_tree().get_nodes_in_group("bundle").size() > 0:
		confirm()
