extends "res://gui/PopupInput.gd"

var scrollTarget: ScrollBar

var axisChange: = 0.0

func stick_move(event: InputEventJoypadMotion)->bool:
	if InputMap.event_is_action(event, "ui_page_down"):
		axisChange = event.axis_value
		return true
	if InputMap.event_is_action(event, "ui_page_up"):
		axisChange = - event.axis_value
		return true
	return false

func _process(delta):
	scrollTarget.value += sign(axisChange) * pow(axisChange, 2) * 1000 * delta
