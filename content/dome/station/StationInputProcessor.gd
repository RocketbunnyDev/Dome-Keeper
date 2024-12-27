extends InputProcessor

signal startBattleInput
signal startUpgradesInput
signal directlyEnded

var popup

func _ready():
	name = "StationInputProcessor"

func handleStart():
	popup.moveIn()
	Audio.sound("enter_station_" + Level.domeId())

func handleStop():
	popup.moveOut()
	Audio.sound("exit_station_" + Level.domeId())

func becameLeaf():
	popup.moveIn(true)
	Level.stage.pause()

func notLeaf():
	popup.moveOut()

func keyEvent(event)->bool:
	if justPressed(event, "dome_battle"):
		Audio.sound("gui_move")
		popup.moveOut()
		emit_signal("startBattleInput")
	elif justPressed(event, "dome_upgrades"):
		Audio.sound("gui_move")
		popup.moveOut()
		emit_signal("startUpgradesInput")
	elif justPressed(event, "ui_cancel"):
		Audio.sound("gui_cancel")
		desintegrate()
		emit_signal("directlyEnded")
	elif justPressed(event, "escape"):
		return false
	elif justPressed(event, "cheats"):
		
		return false
	elif justPressed(event, "escape"):
		return false
	
	return true
