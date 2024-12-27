extends Path2D

export (Vector2) var axisModulation = Vector2(0.5, 0)

func createPathProbe(actor)->PathFollow2D:
	var pathProbe = Data.PATH_PROBE.instance()
	add_child(pathProbe)
	pathProbe.unit_offset = 0.5
	pathProbe.axisModulation = axisModulation
	pathProbe.rotationCenter = getRotationCenter()
	pathProbe.actor = actor
	return pathProbe

func getRotationCenter()->Vector2:
	return get_node("RotationCenter").position
