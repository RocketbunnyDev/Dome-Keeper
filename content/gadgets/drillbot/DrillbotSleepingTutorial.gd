extends Tutorial

var readied: = false

func _ready():
	splitTutorialText("level.tutorial.drillbot.sleeping2", "Label1", "Label2")
	splitTutorialText("level.tutorial.drillbot.sleeping3", "Label3", "Label4")

func process_trigger(delta: float)->bool:
	return tutorialParent.getRemainingSleepTime() >= 15 and (Level.keeper.global_position - tutorialParent.global_position).length() < 72

func process_confirm(delta: float):
	if tutorialParent.getRemainingSleepTime() <= 0:
		confirm()
