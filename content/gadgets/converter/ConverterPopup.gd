extends Control

const transitionTime: = 0.3
var isIn: = false

func _ready():
	$Container.rect_position.y += get_viewport_rect().size.y
	$ColorRect.color = Style.OVERLAY_COLOR_OUT
	$ColorRect.visible = false
	
	var container = find_node("ConversionsContainer")
	var ratio = Data.of("converter.watertoiron")
	if ratio > 0:
		var con = preload("res://content/gadgets/converter/Conversion.tscn").instance()
		con.setConversion("water", "iron", ratio, Data.of("converter.ironwatertime"))
		container.add_child(con)
	ratio = Data.of("converter.irontowater")
	if ratio > 0:
		var con = preload("res://content/gadgets/converter/Conversion.tscn").instance()
		con.setConversion("iron", "water", ratio, Data.of("converter.ironwatertime"))
		container.add_child(con)
	ratio = Data.of("converter.irontocobalt")
	if ratio > 0:
		var con = preload("res://content/gadgets/converter/Conversion.tscn").instance()
		con.setConversion("iron", "sand", ratio, Data.of("converter.ironcobalttime"))
		container.add_child(con)
	ratio = Data.of("converter.cobalttoiron")
	if ratio > 0:
		var con = preload("res://content/gadgets/converter/Conversion.tscn").instance()
		con.setConversion("sand", "iron", ratio, Data.of("converter.ironcobalttime"))
		container.add_child(con)
	ratio = Data.of("converter.irontoiron")
	if ratio > 0:
		var con = preload("res://content/gadgets/converter/Conversion.tscn").instance()
		con.setConversion("iron", "iron", ratio, Data.of("converter.ironirontime"))
		container.add_child(con)
	
	Style.init(self)
	
	Data.listen(self, "inventory.iron")
	Data.listen(self, "inventory.water")
	Data.listen(self, "inventory.sand")

func getFocussedConversion():
	for c in find_node("ConversionsContainer").get_children():
		if c.has_focus():
			return c
	return null

func propertyChanged(property: String, oldValue, newValue):
	match property:
		"inventory.iron":
			for c in find_node("ConversionsContainer").get_children():
				c.updateInventory("iron", newValue)
		"inventory.water":
			for c in find_node("ConversionsContainer").get_children():
				c.updateInventory("water", newValue)
		"inventory.sand":
			for c in find_node("ConversionsContainer").get_children():
				c.updateInventory("sand", newValue)

func moveIn():
	if isIn:
		return 
	
	isIn = true
	$Tween.stop_all()
	$Tween.remove_all()
	get_tree().get_nodes_in_group("level_canvas_overlay").front().showOverlay()

	$Tween.interpolate_property($Container, "rect_position:y", $Container.rect_position.y, 0, 0.6, Tween.TRANS_CUBIC, Tween.EASE_OUT)
	$Tween.start()
	
	find_node("CancelButton").grab_focus()
	
func moveOut():
	if not isIn:
		return 
	
	for c in find_node("ConversionsContainer").get_children():
		if c.has_focus():
			c.release_focus()
	
	Data.unlisten(self, "inventory.iron")
	Data.unlisten(self, "inventory.water")
	Data.unlisten(self, "inventory.sand")
	
	isIn = false
	$Tween.stop_all()
	$Tween.remove_all()
	get_tree().get_nodes_in_group("level_canvas_overlay").front().hideOverlay()

	$Tween.interpolate_property($Container, "rect_position:y", $Container.rect_position.y, get_viewport_rect().size.y, 0.3, Tween.TRANS_CUBIC, Tween.EASE_IN)
	$Tween.interpolate_callback(self, transitionTime, "queue_free")
	$Tween.start()
