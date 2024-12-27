extends "res://content/caves/Cave.gd"

func _ready():
	Level.map.addSpriteToBGAlpha($AlphaMap)

func onRevealed():
	find_node("Amb").play()

func serialize()->Dictionary:
	var data = .serialize()
	data["cobalt1"] = find_node("Cobalt1") != null
	data["cobalt2"] = find_node("Cobalt2") != null
	return data
	
func deserialize(data: Dictionary):
	.deserialize(data)
	if currentState == State.REVEALED:
		find_node("Amb").play()
	
	if not data["cobalt1"]:
		find_node("Cobalt1").queue_free()
	if not data["cobalt2"]:
		find_node("Cobalt2").queue_free()
