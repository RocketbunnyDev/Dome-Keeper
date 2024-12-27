extends Area2D

func getDeliverableDrop(type: String):
	var p = get_parent()
	if not p.absorbed and p.type == type:
		return p
	else:
		return null
