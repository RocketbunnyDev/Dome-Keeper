extends Container

var isIn: = false
var animationDone: = false

func init():
	if GameWorld.won:
		find_node("TitleLabel").text = "level.gameover.win.title"
		find_node("KeepGadgetPopup").visible = false
	else:
		find_node("KeepGadgetPopup").init()
		find_node("TitleLabel").text = "level.gameover.lose.title"

	if GameWorld.won and GameWorld.modeVariation == "" and GameWorld.unlockableElements.size() > 0:
		find_node("NavigationButtons").visible = false
		find_node("UnlockElementButton").visible = true
	else:
		find_node("NavigationButtons").visible = true
		find_node("UnlockElementButton").visible = false
	
	find_node("RunStats").init()
	
	Style.init(self)

func updateFocus():
	var fo = find_node("KeepGadgetPopup").getFirstOption()
	var ueb = find_node("UnlockElementButton")
	if fo:
		InputSystem.grabFocus(fo)
	elif ueb and ueb.visible:
		InputSystem.grabFocus(ueb)
	else:
		InputSystem.grabFocus(find_node("AnotherRunButton"))

func moveIn():
	if isIn:
		return 
	
	GameWorld.setShowMouse(true)
	isIn = true
	$Tween.stop_all()
	$Tween.remove_all()
	$Tween.interpolate_property(self, "rect_position:y", rect_position.y, (get_viewport_rect().size.y - rect_size.y) * 0.5, 1.2, Tween.TRANS_CUBIC, Tween.EASE_OUT)
	$Tween.interpolate_callback(self, 1.3, "set", "animationDone", true)
	$Tween.interpolate_callback(self, 2.5, "updateFocus")
	$Tween.start()

func _on_MainMenuButton_pressed():
	if isIn:
		continuePressed()
		StageManager.startStage("stages/title/title")

func _on_AnotherRunButton_pressed():
	if isIn:
		continuePressed()
		StageManager.startStage("stages/loadout/loadout")

func continuePressed():
	Audio.stopMusic()
	Audio.sound("gui_select")
	find_node("MainMenuButton").disabled = true
	find_node("AnotherRunButton").disabled = true

func _on_UnlockElementButton_pressed():
	Audio.sound("gui_select")
	var i = preload("res://gui/PopupInput.gd").new()
	var unlockablesPopup = preload("res://content/gamemode/unlockables/UnlockablesPopup.tscn").instance()
	unlockablesPopup.connect("proceed", i, "desintegrate")
	unlockablesPopup.connect("back", i, "desintegrate")
	unlockablesPopup.connect("back", self, "updateFocus")
	unlockablesPopup.connect("back", unlockablesPopup, "queue_free")
	get_parent().add_child(unlockablesPopup)
	i.popup = unlockablesPopup
	i.integrate(Level.stage)
