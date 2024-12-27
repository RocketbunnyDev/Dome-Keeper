extends Tutorial

func process_trigger(delta: float)->bool:
	return Data.of("keeper.insidedome") and not Data.of("keeper.insidestation")

func process_confirm(delta: float):
	if not tutorialParent.hasTeleporter:
		confirm()
