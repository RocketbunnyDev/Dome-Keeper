extends "res://gui/PopupInput.gd"

var stickReceiver

func stick_move(event: InputEventJoypadMotion)->bool:
	stickReceiver.stick_move(event)
	return true

func handleStop():
	Audio.sound("gui_back")
	.handleStop()

func keyEvent(event)->bool:
	if child:
		return false
	
	if justPressed(event, "ui_tab_left"):
		popup.tabLeft()
		return true
	elif justPressed(event, "ui_tab_right"):
		popup.tabRight()
		return true
	
	return .keyEvent(event)
