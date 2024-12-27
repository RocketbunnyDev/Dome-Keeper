extends "res://stages/loadout/ModePopup.gd"

func _ready():
	find_node("DifficultyButton3").visible = GameWorld.isUnlocked(CONST.DIFFICULTY_YAFI)
	
	match int(GameWorld.difficulty):
		2:
			find_node("DifficultyButton3").pressed = true
			_on_DifficultyButton3_pressed(false)
		0:
			find_node("DifficultyButton2").pressed = true
			_on_DifficultyButton2_pressed(false)
		- 1:
			find_node("DifficultyButton1").pressed = true
			_on_DifficultyButton1_pressed(false)
		- 2:
			find_node("DifficultyButton4").pressed = true
			_on_DifficultyButton4_pressed(false)
	
	find_node("MapSizeButton2").disabled = not GameWorld.isUnlocked(CONST.MAP_MEDIUM)
	find_node("MapSizeButton3").disabled = not GameWorld.isUnlocked(CONST.MAP_LARGE)
	find_node("MapSizeButton4").disabled = not GameWorld.isUnlocked(CONST.MAP_HUGE)
	find_node("HintPopup").visible = false
	
	for i in range(1, 5):
		var button = find_node("MapSizeButton" + str(i))
		button.connect("focus_entered", self, "mapSizeFocussed", [i])
		button.connect("focus_exited", self, "clearHintButton")
	
	if not GameWorld.lastMapSize:
		GameWorld.lastMapSize = CONST.MAP_SMALL
	
	if GameWorld.isUnlocked("world-modifiers"):
		find_node("ModifiersBox").visible = true
		if GameWorld.lastWorldModifiers.has("worldmodifiermonsterfast"):
			find_node("ModHyperactiveButton").pressed = true
		if GameWorld.lastWorldModifiers.has("worldmodifiermonsterwavesspaced"):
			find_node("ModLongTimeButton").pressed = true
		if GameWorld.lastWorldModifiers.has("worldmodifiermapmaze"):
			find_node("ModMazeButton").pressed = true
		if GameWorld.lastWorldModifiers.has("worldmodifierdoubleiron"):
			find_node("ModDoubleIronButton").pressed = true
	else:
		find_node("ModifiersBox").visible = false
	
	match GameWorld.lastMapSize:
		CONST.MAP_SMALL:
			find_node("MapSizeButton1").pressed = true
			_on_MapSizeButton1_pressed(false)
		CONST.MAP_MEDIUM:
			find_node("MapSizeButton2").pressed = true
			_on_MapSizeButton2_pressed(false)
		CONST.MAP_LARGE:
			find_node("MapSizeButton3").pressed = true
			_on_MapSizeButton3_pressed(false)
		CONST.MAP_HUGE:
			find_node("MapSizeButton4").pressed = true
			_on_MapSizeButton4_pressed(false)

func _on_DifficultyButton1_pressed(playSound: = true):
	if playSound:
		Audio.sound("gui_select")
	find_node("DifficultyIcon").texture = preload("res://content/icons/loadout_diff1.png")
	find_node("DifficultyExplanationLabel").text = "loadout.difficulty.easy.description"
	GameWorld.difficulty = - 1

func _on_DifficultyButton2_pressed(playSound: = true):
	if playSound:
		Audio.sound("gui_select")
	find_node("DifficultyIcon").texture = preload("res://content/icons/loadout_diff2.png")
	find_node("DifficultyExplanationLabel").text = "loadout.difficulty.medium.description"
	GameWorld.difficulty = 0

func _on_DifficultyButton3_pressed(playSound: = true):
	if playSound:
		Audio.sound("gui_select")
	find_node("DifficultyIcon").texture = preload("res://content/icons/loadout_diff3.png")
	find_node("DifficultyExplanationLabel").text = "loadout.difficulty.hard.description"
	GameWorld.difficulty = 2

func _on_DifficultyButton4_pressed(playSound: = true):
	if playSound:
		Audio.sound("gui_select")
	find_node("DifficultyIcon").texture = preload("res://content/icons/loadout_diff4.png")
	find_node("DifficultyExplanationLabel").text = "loadout.difficulty.veryeasy.description"
	GameWorld.difficulty = - 2

func _on_MapSizeButton1_pressed(playSound: = true):
	if playSound:
		Audio.sound("gui_select")
	GameWorld.lastMapSize = CONST.MAP_SMALL
	find_node("MapSizeExplanationLabel").text = "loadout.mapsize.small.description"

func _on_MapSizeButton2_pressed(playSound: = true):
	if playSound:
		Audio.sound("gui_select")
	GameWorld.lastMapSize = CONST.MAP_MEDIUM
	find_node("MapSizeExplanationLabel").text = "loadout.mapsize.medium.description"

func _on_MapSizeButton3_pressed(playSound: = true):
	if playSound:
		Audio.sound("gui_select")
	GameWorld.lastMapSize = CONST.MAP_LARGE
	find_node("MapSizeExplanationLabel").text = "loadout.mapsize.large.description"

func _on_MapSizeButton4_pressed(playSound: = true):
	if playSound:
		Audio.sound("gui_select")
	GameWorld.lastMapSize = CONST.MAP_HUGE
	find_node("MapSizeExplanationLabel").text = "loadout.mapsize.huge.description"

func getWorldModifiers()->Array:
	var mods: = []
	if find_node("ModHyperactiveButton").pressed:
		mods.append("worldmodifiermonsterfast")
	if find_node("ModLongTimeButton").pressed:
		mods.append("worldmodifiermonsterwavesspaced")
	if find_node("ModMazeButton").pressed:
		mods.append("worldmodifiermapmaze")
	if find_node("ModDoubleIronButton").pressed:
		mods.append("worldmodifierdoubleiron")
	
	return mods

func _on_ModHyperactiveButton_toggled(button_pressed):
	Audio.sound("gui_select")
	find_node("ModifierExplanationLabel").text = tr("loadout.mode.hyperactive.desc")

func _on_ModLongTimeButton_toggled(button_pressed):
	Audio.sound("gui_select")
	find_node("ModifierExplanationLabel").text = tr("loadout.mode.longtime.desc")

func _on_ModMazeButton_toggled(button_pressed):
	Audio.sound("gui_select")
	find_node("ModifierExplanationLabel").text = tr("loadout.mode.maze.desc")

func _on_ModDoubleIronButton_toggled(button_pressed):
	Audio.sound("gui_select")
	find_node("ModifierExplanationLabel").text = tr("loadout.mode.doubleiron.desc")

func _on_HarderButton_pressed():
	Audio.sound("gui_select")
	GameWorld.difficulty = min(3, GameWorld.difficulty + 1)
	find_node("DifficultyBadge").setStage(GameWorld.difficulty)

func _on_EasierButton_pressed():
	Audio.sound("gui_select")
	GameWorld.difficulty = max( - 2, GameWorld.difficulty - 1)
	find_node("DifficultyBadge").setStage(GameWorld.difficulty)

func mapSizeFocussed(size: int):
	var pop = find_node("HintPopup")
	pop.visible = false
	var but = find_node("MapSizeButton" + str(size))
	if but.disabled:
		find_node("HintLabel").text = "loadout.mapsize.unlock.description"
		pop.rect_position = but.rect_global_position - pop.get_parent().rect_global_position
		pop.rect_position.y += but.rect_size.y + 12
		pop.visible = true

func clearHintButton():
	find_node("HintPopup").visible = false
