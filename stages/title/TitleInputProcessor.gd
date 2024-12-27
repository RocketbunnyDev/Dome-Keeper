extends InputProcessor

func keyEvent(event)->bool:
	StageManager.startStage("stages/loadout/loadout")
	return true
