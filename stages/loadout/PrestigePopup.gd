extends "res://stages/loadout/ModePopup.gd"

var pressedFocusText: = ""
var lastMouseEntered: = 0

func _ready():
	find_node("PrestigeMode2Button").visible = GameWorld.isUnlocked(CONST.MODE_PRESTIGE_COBALT)
	find_node("PrestigeMode3Button").visible = GameWorld.isUnlocked(CONST.MODE_PRESTIGE_COUNTDOWN)
	find_node("PrestigeMode4Button").visible = GameWorld.isUnlocked(CONST.MODE_PRESTIGE_MINER)
	
	if find_node("PrestigeMode2Button").visible and find_node("PrestigeMode3Button").visible and find_node("PrestigeMode4Button").visible:
		find_node("HBoxContainer").columns = 2
	
	match GameWorld.lastGameModeVariation:
		CONST.MODE_PRESTIGE_COBALT:
			find_node("PrestigeMode2Button").pressed = true
			_on_PrestigeMode2Button_pressed()
		CONST.MODE_PRESTIGE_COUNTDOWN:
			find_node("PrestigeMode3Button").pressed = true
			_on_PrestigeMode3Button_pressed()
		CONST.MODE_PRESTIGE_MINER:
			find_node("PrestigeMode4Button").pressed = true
			_on_PrestigeMode4Button_pressed()
		_:
			find_node("PrestigeMode1Button").pressed = true
			_on_PrestigeMode1Button_pressed()

func _on_PrestigeMode1Button_pressed():
	if isIn:
		Audio.sound("loadout_modebasic")
		GameWorld.lastGameModeVariation = ""
	pressedFocusText = "loadout.prestige.normal.description"
	updateFocusText()
	if lastMouseEntered != 1:
		InputSystem.grabFocus(find_node("StartButton"))

func _on_PrestigeMode2Button_pressed():
	if isIn:
		Audio.sound("loadout_modecobolt")
		GameWorld.lastGameModeVariation = CONST.MODE_PRESTIGE_COBALT
	pressedFocusText = "loadout.prestige.cobalt.description"
	updateFocusText()
	if lastMouseEntered != 2:
		InputSystem.grabFocus(find_node("StartButton"))

func _on_PrestigeMode3Button_pressed():
	if isIn:
		Audio.sound("loadout_modetimed")
		GameWorld.lastGameModeVariation = CONST.MODE_PRESTIGE_COUNTDOWN
	pressedFocusText = "loadout.prestige.countdown.description"
	updateFocusText()
	if lastMouseEntered != 3:
		InputSystem.grabFocus(find_node("StartButton"))

func _on_PrestigeMode4Button_pressed():
	if isIn:
		Audio.sound("loadout_modeminer")
		GameWorld.lastGameModeVariation = CONST.MODE_PRESTIGE_MINER
	pressedFocusText = "loadout.prestige.miner.description"
	updateFocusText()
	if lastMouseEntered != 4:
		InputSystem.grabFocus(find_node("StartButton"))

func _on_PrestigeMode1Button_focus_entered():
	find_node("ModeExplanationLabel").text = "loadout.prestige.normal.description"

func _on_PrestigeMode2Button_focus_entered():
	find_node("ModeExplanationLabel").text = "loadout.prestige.cobalt.description"

func _on_PrestigeMode3Button_focus_entered():
	find_node("ModeExplanationLabel").text = "loadout.prestige.countdown.description"

func _on_PrestigeMode4Button_focus_entered():
	find_node("ModeExplanationLabel").text = "loadout.prestige.miner.description"

func updateFocusText():
	find_node("ModeExplanationLabel").text = pressedFocusText

func _on_PrestigeMode1Button_mouse_entered():
	_on_PrestigeMode1Button_focus_entered()
	lastMouseEntered = 1

func _on_PrestigeMode2Button_mouse_entered():
	_on_PrestigeMode2Button_focus_entered()
	lastMouseEntered = 2

func _on_PrestigeMode3Button_mouse_entered():
	_on_PrestigeMode3Button_focus_entered()
	lastMouseEntered = 3

func _on_PrestigeMode4Button_mouse_entered():
	_on_PrestigeMode4Button_focus_entered()
	lastMouseEntered = 4
