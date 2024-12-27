extends InputProcessor

signal buyUpgrade
signal toggleMode

var popup
var lastPanel

func handleStart():
	popup.moveIn()

	if not Options.useGamepad:
		GameWorld.setShowMouse(true)
	
	Audio.sound("open_upgrades")

func handleStop():
	popup.moveOut()

	GameWorld.setShowMouse(false)
	
	Audio.sound("close_upgrades")

func becameLeaf():
	if lastPanel:
		popup.techTree().focussedTechPanel = lastPanel
		lastPanel = null
		
	popup.focus()

func notLeaf():
	lastPanel = popup.techTree().focussedTechPanel

func keyEvent(event)->bool:
	if justPressed(event, "ui_cancel"):
		Audio.sound("gui_cancel")
		desintegrate()
	elif justPressed(event, "ui_select"):
		emit_signal("buyUpgrade")
	elif justPressed(event, "cheats"):
		
		return false
	elif justPressed(event, "escape"):
		return false
	
	return true
