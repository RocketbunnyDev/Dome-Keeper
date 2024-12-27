extends "res://gui/PopupInput.gd"

func keyEvent(event)->bool:
	if canClose and (justPressed(event, "ui_cancel") or justPressed(event, "escape")):
		close()
		return true
	elif justPressed(event, "ui_select"):
		emit_signal("confirmed")
		return true
	return blockAllKeys or (blockAllKeysIfGamepad and GameWorld.useGamepad)
