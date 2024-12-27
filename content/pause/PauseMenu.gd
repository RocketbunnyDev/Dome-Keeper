extends CanvasLayer

signal close

var closed: = false

func _ready():
	$ColorRect.color = Style.OVERLAY_COLOR_OUT
	fadeIn(0.3)
	$VersionBox / VersionLabel.text = GameWorld.getVersionPrint()
	Style.init(self)
	
	if GameWorld.buildType == CONST.BUILD_TYPE.EXHIBITION:
		$BippinbitsBox.visible = false
		if not GameWorld.devMode:
			find_node("ButtonOptions").visible = false

	update_supportbox()
	
func update_supportbox():
	if Data.of("keeper.insidestation"):
		$SupportBox / PanelContainer / VBoxContainer / Dome.show()
		$SupportBox / PanelContainer / VBoxContainer / Mine.hide()
	else:
		$SupportBox / PanelContainer / VBoxContainer / Dome.hide()
		$SupportBox / PanelContainer / VBoxContainer / Mine.show()
		
	if Options.useGamepad:
		match Options.getGamepadName():
			"ps4":
				$SupportBox / PanelContainer / VBoxContainer / Gamepad.texture = preload("res://gui/gamepad_controller_ps4.png")
			_:
				$SupportBox / PanelContainer / VBoxContainer / Gamepad.texture = preload("res://gui/gamepad_controller.png")
		$SupportBox / PanelContainer / VBoxContainer / Gamepad.show()
		$SupportBox / PanelContainer / VBoxContainer / Keyboard.hide()
		get_tree().call_group("hide_for_gamepad", "hide")
	else:
		$SupportBox / PanelContainer / VBoxContainer / Gamepad.hide()
		$SupportBox / PanelContainer / VBoxContainer / Keyboard.show()
		get_tree().call_group("hide_for_gamepad", "show")
		

func _on_ButtonFeedback_pressed()->void :
	Audio.sound("gui_select")
	var i = preload("res://gui/PopupInput.gd").new()
	i.stopNamed = "PopupInput"
	i.popup = $FeedbackPopup
	$FeedbackPopup.connect("quit", i, "desintegrate")
	$FeedbackPopup.init()
	i.integrate(self)

func _on_ButtonBug_pressed()->void :
	pass

func _on_ButtonDiscord_pressed()->void :
	Audio.sound("gui_select")
	OS.shell_open("https://discord.gg/AxYpX7AaFP")

func _on_ButtonOptions_pressed()->void :
	Audio.sound("gui_select")
	var i = preload("res://systems/options/OptionsInputProcessor.gd").new()
	i.blockAllKeys = true
	i.popup = preload("res://systems/options/OptionsPanel.tscn").instance()
	i.stickReceiver = i.popup
	add_child(i.popup)
	i.popup.setFromOptions()
	i.integrate(self)
	i.connect("onStop", self, "optionsClosed", [i.popup])
	i.popup.connect("close", i, "desintegrate")

func optionsClosed(popup):
	InputSystem.grabFocus(find_node("ButtonResume"))
	remove_child(popup)
	popup.queue_free()

func _on_ButtonBackToTitle_pressed()->void :
	if find_node("ReallyQuitToTitlePopup").visible:
		Audio.sound("gui_quit_confirm")
		if not Data.of("monsters.wavepresent"):
			GameWorld.saveGame(0)
		closed = true
		StageManager.startStage("stages/title/title")
		find_node("ButtonBackToTitle").disabled = true
		find_node("ButtonQuitGame").disabled = true
	else:
		Audio.sound("gui_quit_ask")
		enterQuitConfirmation()

func _on_ButtonQuitGame_pressed()->void :
	if find_node("ReallyQuitToTitlePopup").visible:
		Audio.sound("gui_quit_confirm")
		if not Data.of("monsters.wavepresent"):
			GameWorld.saveGame(0)
		closed = true
		Backend.event("game", {"action": "quit"})
		Backend.sendBufferedEvents()
		$Tween.interpolate_callback(get_tree(), 0.4, "quit")
		$Tween.start()
		find_node("ButtonBackToTitle").disabled = true
		find_node("ButtonQuitGame").disabled = true
	else:
		Audio.sound("gui_quit_ask")
		enterQuitConfirmation()

func enterQuitConfirmation():
	var p = find_node("ReallyQuitToTitlePopup")
	p.modulate.a = 0
	p.visible = true
	var causingButton = find_node("ButtonBackToTitle")
	p.rect_position.x = causingButton.rect_size.x + 30
	var d = (1.0 - p.modulate.a) * 0.2
	$ConfirmationTween.stop_all()
	$ConfirmationTween.remove_all()
	$ConfirmationTween.interpolate_property(p, "modulate:a", p.modulate.a, 1.0, d, Tween.TRANS_QUAD, Tween.EASE_OUT)
	$ConfirmationTween.start()

func exitQuitConfirmation():
	if closed:
		return 
	
	var p = find_node("ReallyQuitToTitlePopup")
	if not p.visible:
		return 
	
	var d = p.modulate.a * 0.2
	$ConfirmationTween.stop_all()
	$ConfirmationTween.remove_all()
	$ConfirmationTween.interpolate_property(p, "modulate:a", p.modulate.a, 0.0, d, Tween.TRANS_QUAD, Tween.EASE_IN)
	$ConfirmationTween.interpolate_callback(p, d, "set", "visible", false)
	$ConfirmationTween.start()

func _on_ButtonResume_pressed()->void :
	emit_signal("close")

func fadeIn(t: float):
	Audio.sound("gui_pause_start")
	Audio.muteSounds()
	find_node("ReallyQuitToTitlePopup").visible = false
	
	$MenuPanel.rect_pivot_offset = $MenuPanel.rect_size * 0.5
	$MenuPanel.rect_scale = Vector2.ZERO
	$Tween.interpolate_property($ColorRect, "color", $ColorRect.color, Style.OVERLAY_COLOR_IN, t * 0.5)
	$Tween.interpolate_property($MenuPanel, "rect_scale", Vector2.ZERO, Vector2.ONE, t, Tween.TRANS_CUBIC)
	
	var d = $SupportBox.rect_size.x * 1.5
	$SupportBox.rect_position.x -= d
	$Tween.interpolate_property($SupportBox, "rect_position", $SupportBox.rect_position, $SupportBox.rect_position + Vector2(d, 0), t * 2, Tween.TRANS_CUBIC)
	
	d = $VersionBox.rect_size.x * 1.5
	$VersionBox.rect_position.x -= d
	$Tween.interpolate_property($VersionBox, "rect_position", $VersionBox.rect_position, $VersionBox.rect_position + Vector2(d, 0), t * 2, Tween.TRANS_CUBIC)
	
	d = $BippinbitsBox.rect_size.x * 1.2
	$BippinbitsBox.rect_position.x += d
	$Tween.interpolate_property($BippinbitsBox, "rect_position", $BippinbitsBox.rect_position, $BippinbitsBox.rect_position - Vector2(d, 0), t * 2, Tween.TRANS_CUBIC)
	
	d = $GodotBox.rect_size.x
	$GodotBox.rect_position.x += d
	$Tween.interpolate_property($GodotBox, "rect_position", $GodotBox.rect_position, $GodotBox.rect_position - Vector2(d, 0), t * 2, Tween.TRANS_CUBIC)
	
	$Tween.interpolate_callback(InputSystem, t, "grabFocus", find_node("ButtonResume"))
	$Tween.start()

func fadeOut(t: float):
	Audio.sound("gui_pause_stop")
	Audio.unmuteSounds()
	closed = true
	$Tween.interpolate_property($ColorRect, "color", $ColorRect.color, Style.OVERLAY_COLOR_OUT, t * 0.5, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT, t * 0.5)
	$Tween.interpolate_property($MenuPanel / , "rect_scale", $MenuPanel.rect_scale, Vector2.ZERO, t, Tween.TRANS_CUBIC, Tween.EASE_OUT)

	var d = $SupportBox.rect_size.x
	$Tween.interpolate_property($SupportBox, "rect_position", $SupportBox.rect_position, $SupportBox.rect_position - Vector2(d, 0), t, Tween.TRANS_CUBIC)
	
	d = $VersionBox.rect_size.x
	$Tween.interpolate_property($VersionBox, "rect_position", $VersionBox.rect_position, $VersionBox.rect_position - Vector2(d, 0), t, Tween.TRANS_CUBIC)
	
	d = $BippinbitsBox.rect_size.x
	$Tween.interpolate_property($BippinbitsBox, "rect_position", $BippinbitsBox.rect_position, $BippinbitsBox.rect_position + Vector2(d, 0), t, Tween.TRANS_CUBIC)
	
	d = $GodotBox.rect_size.x
	$Tween.interpolate_property($GodotBox, "rect_position", $GodotBox.rect_position, $GodotBox.rect_position + Vector2(d, 0), t, Tween.TRANS_CUBIC)
	

	$Tween.interpolate_callback(self, t, "queue_free")
	
	$Tween.start()
