extends PanelContainer





var state: int
var techId: String
var title: String
var cost: String
var costIcon: Texture
var icon: Texture



var track

func build(id: String):
	self.techId = id
	$SelectedPanel.visible = false
	var data = Data.upgrades.get(id)
	if data.has("cost"):
		find_node("CostLabel").text = str(data["cost"])
	
	title = tr("upgrades." + id + ".title")
	
	find_node("TitleLabel").text = title
	
	if ResourceLoader.exists("res://content/icons/" + id + ".png"):
		icon = load("res://content/icons/" + id + ".png")
		find_node("Icon").texture = icon
	
	_on_Tech_focus_exited()

func _on_Tech_focus_entered():
	pass

func _on_Tech_focus_exited():
	pass

func setCount(count: int):
	find_node("UsesLabel").text = str(count)
	
