extends Tutorial

func _ready():
	splitTutorialText("level.tutorial.teleporter.teleport1", "Label1", "Label2")

func process_trigger(delta: float)->bool:
	return not tutorialParent.isCarried() and (Level.keeper.global_position - tutorialParent.global_position).length() < 48

func process_confirm(delta: float):
	if tutorialParent.isTeleporting():
		confirm()
