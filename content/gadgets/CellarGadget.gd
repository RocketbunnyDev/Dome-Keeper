extends Node2D

func serialize()->Dictionary:
	var data = {}
	data["meta.priority"] = 200
	data["meta.kind"] = "station"
	return data
	
func deserialize(data: Dictionary):
	pass
	
func flip():
	flipAll(self)

func flipAll(node):
	if node is Sprite or node is AnimatedSprite:
		node.flip_h = not node.flip_h
	
	if node.is_in_group("noflip"):
		return 
	if node is Node2D:
		node.position.x = - node.position.x
	for c in node.get_children():
		flipAll(c)
