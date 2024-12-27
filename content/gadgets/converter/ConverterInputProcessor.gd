extends "res://gui/PopupInput.gd"

signal conversion_selected

var lastFocusElement

func becameLeaf():
	if lastFocusElement:
		lastFocusElement.grab_focus()
		lastFocusElement = null

func notLeaf():
	lastFocusElement = popup.get_focus_owner()

func keyEvent(event)->bool:
	if justPressed(event, "ui_select"):
		var focus = popup.getFocussedConversion()
		if not focus:
			return false
		
		if focus.enoughResources:
			Audio.sound("gui_select")
			emit_signal("conversion_selected", focus)
			desintegrate()
		else:
			Audio.sound("gui_err")
		return true
	return .keyEvent(event)
