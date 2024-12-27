extends Tutorial

var stage: = 1

func _ready():
	trigger()
	find_node("Text2").visible = false
	find_node("Text3").visible = false
	find_node("BackButton").disabled = true

func _on_VideoPlayer_finished():
	find_node("VideoPlayer").play()

func _on_Button_pressed():
	Audio.sound("gui_select")
	if stage < 3:
		stage += 1
		updatePlayers()
	else:
		confirm()

func updatePlayers():
	for i in range(1, 4):
		var player = find_node("VideoPlayer" + str(i))
		if i == stage:
			player.play()
		else:
			player.stop()
	find_node("Text" + str(stage)).visible = true
	find_node("BackButton").disabled = stage == 1

func onMovedIn():
	InputSystem.grabFocus(find_node("Button"))
	popupInput = preload("res://gui/PopupInput.gd").new()
	popupInput.popup = self
	popupInput.canClose = false
	popupInput.blockAllKeys = true
	popupInput.focusControlOnLeaf = get_focus_owner()
	popupInput.integrate(Level.stage)

func _on_VideoPlayer1_finished():
	find_node("VideoPlayer1").play()

func _on_VideoPlayer2_finished():
	find_node("VideoPlayer2").play()

func _on_VideoPlayer3_finished():
	find_node("VideoPlayer3").play()

func _on_BackButton_pressed():
	if stage > 1:
		Audio.sound("gui_select")
		stage -= 1
		updatePlayers()
	else:
		Audio.sound("gui_err")
