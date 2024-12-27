extends Tutorial

func _ready():
	splitTutorialText("level.tutorial.teleporter.carry2", "Label1", "Label2")
	splitTutorialText("level.tutorial.teleporter.carry3", "Label3", "Label4")

func process_trigger(delta: float)->bool:
	return not tutorialParent.isCarried() and (Level.keeper.global_position - tutorialParent.global_position).length() < 72

func process_confirm(delta: float):
	if tutorialParent.isCarried():
		confirm()
