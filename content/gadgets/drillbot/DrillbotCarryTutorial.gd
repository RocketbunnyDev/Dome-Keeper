extends Tutorial

func process_trigger(delta: float)->bool:
	return Data.of("keeper.insidedome") and not Data.of("keeper.insidestation")

func process_confirm(delta: float):
	if get_tree().get_nodes_in_group("drillbots").size() > 0:
		confirm()
