extends PanelContainer

var from
var to
var resourcesIn
var resourcesOut
var time

var enoughResources: = false

func _ready():
	_on_Conversion_focus_exited()
	find_node("Label2").text = find_node("Label2").text
	$SelectedPanel.visible = false

func setConversion(from, to, ratio, time):
	self.from = from
	self.to = to
	self.resourcesIn = ratio if ratio >= 1 else 1
	self.resourcesOut = 1 if ratio >= 1 else int(round(1.0 / float(ratio)))
	self.time = time
	
	find_node("LabelTime").text = tr("level.converter.popup.conversion.time").format({"time": "%.1f" % time})
	find_node("Res1").texture = Data.DROP_ICONS.get(from)
	find_node("Res2").texture = Data.DROP_ICONS.get(to)
	find_node("LabelAmount1").text = str(resourcesIn)
	find_node("LabelAmount2").text = str(resourcesOut)
	updateInventory(from, Data.getInventory(from))

func updateInventory(type: String, amount: int):
	if type == from:
		if amount >= resourcesIn:
			enoughResources = true
			find_node("LabelAmount1").set("custom_colors/font_color", null)
		else:
			enoughResources = false
			find_node("LabelAmount1").set("custom_colors/font_color", Style.FONT_COLOR_WARNING)
		updatePanel()

func _on_Conversion_focus_entered():
	$SelectedPanel.visible = true
	Audio.sound("gui_hover")

func _on_Conversion_focus_exited():
	$SelectedPanel.visible = false

func updatePanel():
	if enoughResources:
		set("custom_styles/panel", preload("res://gui/buttons/button_normal.tres"))
	else:
		set("custom_styles/panel", preload("res://gui/buttons/button_disabled.tres"))
