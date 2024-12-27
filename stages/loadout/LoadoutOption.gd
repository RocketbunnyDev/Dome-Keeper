extends PanelContainer

signal selected

export (bool) var selectable: = true

var id: String
var disabled: = false
var titleText: String

func _ready():
	Style.init(self)

func init(id: String, unlockable: bool = true, isPet: = false, isSkin: = false):
	self.id = id
	if isSkin:
		find_node("IconRect").texture = load("res://content/icons/loadout_" + GameWorld.lastKeeperId + "-" + id + ".png")
	else:
		find_node("IconRect").texture = load("res://content/icons/loadout_" + id + ".png")
	
	if isPet or isSkin:
		find_node("DescriptionLabel").visible = false
		find_node("TitleLabel").visible = false
	else:
		titleText = tr("upgrades." + id + ".title")
		find_node("TitleLabel").text = titleText
		
		if not unlockable:
			find_node("DescriptionLabel").bbcode_text = tr("loadout.choices.comingsoon")
		elif disabled:
			find_node("DescriptionLabel").bbcode_text = tr("loadout.choices.locked")
		else:
			find_node("DescriptionLabel").bbcode_text = tr("upgrades." + id + ".desc")
	
	if disabled:
		set("custom_styles/panel", preload("res://gui/buttons/button_disabled.tres"))
	
	$SelectedPanel.visible = false
	
func _on_LoadoutOption_focus_entered():
	if not selectable:
		return 
	$SelectedPanel.visible = true

func _on_LoadoutOption_focus_exited():
	if not selectable:
		return 
	$SelectedPanel.visible = false

func _on_LoadoutOption_gui_input(event):
	if not selectable:
		return 
	if event is InputEventMouseButton and event.pressed and event.button_index == BUTTON_LEFT:
		emit_signal("selected")

func _on_LoadoutOption_mouse_entered():
	if not selectable:
		return 
	$SelectedPanel.visible = false
	find_node("TitleLabel").set("custom_colors/font_color", Style.LIVE_BRIGHT)
	if not disabled:
		set("custom_styles/panel", preload("res://gui/buttons/button_hover.tres"))

func _on_LoadoutOption_mouse_exited():
	if not selectable:
		return 
	find_node("TitleLabel").set("custom_colors/font_color", null)
	modulate = Color.white
	if not has_focus():
		if disabled:
			set("custom_styles/panel", preload("res://gui/buttons/button_disabled.tres"))
		else:
			set("custom_styles/panel", preload("res://gui/buttons/button_normal.tres"))
