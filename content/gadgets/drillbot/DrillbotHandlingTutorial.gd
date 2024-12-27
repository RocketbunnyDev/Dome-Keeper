extends Tutorial

var wasDropped: = false

func _ready():
	splitTutorialText("level.tutorial.drillbot.handling1", "Label1", "Label2")
	splitTutorialText("level.tutorial.drillbot.handling2", "Label3", "Label4")

func process_trigger(delta: float)->bool:
	return tutorialParent.isWorking() and (Level.keeper.global_position - tutorialParent.global_position).length() < 72

func process_confirm(delta: float):
	if not tutorialParent.isCarried():
		wasDropped = true
	
	if wasDropped and tutorialParent.isCarried():
		confirm()

