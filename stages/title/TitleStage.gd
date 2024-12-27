extends Stage

var fastEntry: = false

func build(data: Array):
	Style.setPalette("1_1")
	if data.size() > 0:
		fastEntry = data[0]
	
	Style.init($Canvas / MainMenu)
	Style.init($Canvas / WhatsNewArea)
	Style.init($Canvas / PatchNotesPanel)
	Style.init($Canvas / CreditsPanel)
	Style.init($Canvas / NoStreamContainer)
	
	match GameWorld.buildType:
		CONST.BUILD_TYPE.DEMO:
			find_node("BuildLabel").text = "Demo Build"
		CONST.BUILD_TYPE.PLAYTEST:
			find_node("BuildLabel").text = "Playtest Build"
		CONST.BUILD_TYPE.FULL:
			find_node("BuildLabel").text = ""
		CONST.BUILD_TYPE.EXHIBITION:
			find_node("BuildLabel").text = "Exhibition Build"
	
	find_node("NoStreamContainer").visible = GameWorld.buildType == CONST.BUILD_TYPE.PLAYTEST
	
	if GameWorld.devMode:
		find_node("BuildLabel").text += "Dev mode "
	if GameWorld.qaOptions:
		find_node("BuildLabel").text += "QA Build "
	if GameWorld.unlockAllButton:
		find_node("BuildLabel").text += "Preview Build "
	
	if GameWorld.buildType == CONST.BUILD_TYPE.EXHIBITION:
		find_node("OptionsButton").visible = false
		find_node("WhatsNewButton").visible = false
		find_node("QuitButton").visible = false
		
		var vid = $Canvas / VideoPlayer
		var ei = preload("res://content/keeper/StationAbandonedInputProcessor.gd").new()
		ei.baseCountdown = 45
		ei.connect("no_inputs", vid, "start")
		ei.connect("got_input", vid, "stop")
		ei.integrate(self)
	
	find_node("UnlockEverythingButton").visible = GameWorld.unlockAllButton

func beforeStart():
	GameWorld.setShowMouse(true)
	var delay: = 0.0 if fastEntry else 1.7
	var moveDuration: = 0.6
	
	var pos1 = $Canvas / MainMenu.rect_position.y
	var pos3 = $Canvas / WhatsNewArea.rect_position.y
	$Canvas / MainMenu.rect_position.y = $Canvas / MainMenu.get_viewport_rect().size.y + 5
	$Canvas / WhatsNewArea.rect_position.y = $Canvas / WhatsNewArea.get_viewport_rect().size.y + 5
	
	$Tween.interpolate_property($Canvas / MainMenu, "rect_position:y", $Canvas / MainMenu.rect_position.y, pos1, moveDuration, Tween.TRANS_CUBIC, Tween.EASE_OUT, delay)
	$Tween.interpolate_property($Canvas / WhatsNewArea, "rect_position:y", $Canvas / WhatsNewArea.rect_position.y, pos3, moveDuration, Tween.TRANS_CUBIC, Tween.EASE_OUT, delay + moveDuration)
	
	find_node("VersionLabel").text = GameWorld.getVersionPrint()
	find_node("PatchNotesPanel").visible = false
	find_node("CreditsPanel").visible = false
	
	if GameWorld.has_autosave():
		find_node("ContinueButton").show()
		$Tween.interpolate_callback(InputSystem, delay + 0.5 * moveDuration, "grabFocus", find_node("ContinueButton"))
	else:
		find_node("ContinueButton").hide()
		$Tween.interpolate_callback(InputSystem, delay + 0.5 * moveDuration, "grabFocus", find_node("NewGameButton"))
		
	$Tween.start()
	
	Audio.startIntro()

func _on_NewGameButton_pressed()->void :
	Audio.sound("gui_title_newgame")
	StageManager.startStage("stages/loadout/loadout")
	find_node("NewGameButton").disabled = true

func _on_ContinueButton_pressed()->void :
	Audio.sound("gui_title_continue")
	GameWorld.loadGame(0)

func _on_OptionsButton_pressed()->void :
	Audio.sound("gui_title_options")
	var i = preload("res://systems/options/OptionsInputProcessor.gd").new()
	i.blockAllKeys = true
	i.popup = preload("res://systems/options/OptionsPanel.tscn").instance()
	i.stickReceiver = i.popup
	$Canvas.add_child(i.popup)
	i.popup.setFromOptions()
	i.integrate(self)
	i.connect("onStop", self, "optionsClosed", [i.popup])
	i.popup.connect("close", i, "desintegrate")
	find_node("Overlay").showOverlay()

func optionsClosed(popup):
	InputSystem.grabFocus(find_node("OptionsButton"))
	$Canvas.remove_child(popup)
	popup.queue_free()
	find_node("Overlay").hideOverlay()
	
func _on_QuitButton_pressed()->void :
	Audio.sound("gui_quit_confirm")
	get_tree().quit()

func _on_LocalCoopButton_pressed()->void :
	Audio.sound("gui_select")
	StageManager.startStage("stages/loadout/loadout", [true])

func _on_WhatsNewButton_pressed()->void :
	Audio.sound("gui_select")
	find_node("PatchNotesPanel").visible = true
	InputSystem.grabFocus(find_node("PatchNotesPanel").find_node("CancelButton"))
	
	var i = preload("res://content/shared/ControllerScrollInputProcessor.gd").new()
	i.popup = find_node("PatchNotesPanel")
	i.scrollTarget = i.popup.find_node("ScrollContainer").get_v_scrollbar()
	i.integrate(self)
	i.connect("onStop", self, "_on_ClosePatchNotesButton_pressed")
	find_node("Overlay").showOverlay()

func _on_ClosePatchNotesButton_pressed()->void :
	Audio.sound("gui_select")
	find_node("PatchNotesPanel").visible = false
	InputSystem.grabFocus(find_node("WhatsNewButton"))
	find_node("Overlay").hideOverlay()

func _on_CreditsButton_pressed():
	Audio.sound("gui_title_credits")
	find_node("CreditsPanel").visible = true
	InputSystem.grabFocus(find_node("CreditsPanel").find_node("CancelButton"))
	
	var i = preload("res://content/shared/ControllerScrollInputProcessor.gd").new()
	i.popup = find_node("CreditsPanel")
	i.scrollTarget = i.popup.find_node("ScrollContainer").get_v_scrollbar()
	i.integrate(self)
	i.connect("onStop", self, "_on_CloseCreditsButton_pressed")
	find_node("Overlay").showOverlay()

func _on_CloseCreditsButton_pressed():
	Audio.sound("gui_select")
	find_node("CreditsPanel").visible = false
	InputSystem.grabFocus(find_node("CreditsButton"))
	find_node("Overlay").hideOverlay()

func _on_UnlockEverythingButton_pressed():
	Audio.sound("gui_select")
	GameWorld.unlockEverything()
	find_node("UnlockEverythingButton").disabled = true
