extends PanelContainer


func _ready():
	_on_GadgetChoice_focus_exited()
	Style.init(self)

func _on_GadgetChoice_focus_entered():
	set("custom_styles/panel", preload("res://gui/buttons/button_hover.tres"))

func _on_GadgetChoice_focus_exited():
	set("custom_styles/panel", preload("res://gui/buttons/button_normal.tres"))
