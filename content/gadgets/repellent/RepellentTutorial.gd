extends Tutorial

func _ready():
	splitTutorialText("level.tutorial.repellent.popup_2", "Label1", "Label2")

func process_trigger(delta: float)->bool:
	return Data.of("keeper.insidedome") and not Data.of("keeper.insidestation") and Data.of("repellent.currentgrowth") >= 1.0

func process_confirm(delta: float):
	if GameWorld.waveDelay > 0.0:
		confirm()
