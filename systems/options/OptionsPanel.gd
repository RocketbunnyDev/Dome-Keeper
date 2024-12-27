extends CenterContainer

signal close

var useGamepad: = false
var autoSwitchGamepad: = true
var fullscreen: = false
var borderless: = false
var stretchmode: int
var gamepadStickDeadZone: float = 0.2

var readied: = false

const categories: = ["Game", "Video", "Audio", "Input", "Accessibility"]
var currentCategory: String

func _ready():
	find_node("StickMoveRect").color = Style.STRUCT_DARK
	find_node("ButtonBorderless").visible = OS.get_name() != "OSX"
	
	if GameWorld.qaOptions:
		categories.insert(0, "QA")
		find_node("QACategoryButton").visible = true
	else:
		find_node("QACategoryButton").visible = false
		find_node("QACategory").visible = false
	
	showCategory(GameWorld.lastViewedOptionsCategory if GameWorld.lastViewedOptionsCategory else "Game")
	
	Style.init(self)

func showCategory(cat: String):
	currentCategory = cat
	find_node(cat + "Category").visible = true
	var categoryButton = find_node(cat + "CategoryButton")
	categoryButton.pressed = true
	for c in categories:
		if c != cat:
			find_node(c + "Category").visible = false
	InputSystem.grabFocus(categoryButton)


func setUseGamepad(b):
	if useGamepad != b:
		useGamepad = b
		for l in get_tree().get_nodes_in_group("gamepadListeners"):
			Options.setActionIcons(l)

func setFromOptions():
	find_node("MasterVolumeSlider").value = Options.masterVolume
	find_node("SoundVolumeSlider").value = Options.soundVolume
	find_node("AmbienceVolumeSlider").value = Options.ambienceVolume
	find_node("MusicVolumeSlider").value = Options.musicVolume
	find_node("MusicFrequencySlider").value = Options.cyclesWithoutMusic
	find_node("GamepadDeadZoneSlider").value = Options.gamepadStickDeadZone
	find_node("ButtonPhotoSensitivity").pressed = Options.photosensitive
	find_node("ButtonDisableCritters").pressed = Options.disableCritters
	find_node("AutoSwitchGamepadCheckBox").pressed = Options.tryAutoSwitchGamepad
	find_node("EnableSeasonalEventButton").pressed = Options.enableSeasonalContent
	
	find_node("ButtonVsync").pressed = Options.vsync
	fullscreen = Options.fullscreen
	borderless = Options.borderless
	if fullscreen:
		find_node("ButtonFullscreen").pressed = true
		find_node("ButtonWindowed").pressed = false
		find_node("ButtonBorderless").pressed = false
	elif borderless:



		find_node("ButtonFullscreen").pressed = false
		find_node("ButtonBorderless").pressed = true
		find_node("ButtonWindowed").pressed = false
	else:
		find_node("ButtonFullscreen").pressed = false
		find_node("ButtonBorderless").pressed = false
		find_node("ButtonWindowed").pressed = true
	
	stretchmode = Options.stretchmode
	if stretchmode == SceneTree.STRETCH_MODE_2D:
		find_node("ButtonResized").pressed = true
		find_node("ButtonScaled").pressed = false
	else:
		find_node("ButtonResized").pressed = false
		find_node("ButtonScaled").pressed = true
	
	find_node("ShakeIntensitySlider").value = Options.shakeIntensity
	find_node("ShakeDrill").pressed = Options.shakeDrill
	find_node("VibrationIntensitySlider").value = Options.vibrationStrength
	
	find_node("ButtonHighlightedMonsters").pressed = Options.visibleMonsters
	
	readied = true

func _on_ButtonWindow_pressed()->void :
	fullscreen = false
	borderless = false
	Audio.sound("gui_select")

func _on_ButtonBorderlessWindow_pressed():
	fullscreen = false
	borderless = true
	Audio.sound("gui_select")

func _on_ButtonFullscreen_pressed()->void :
	fullscreen = true
	borderless = false
	Audio.sound("gui_select")

func _on_ButtonApply_pressed()->void :
	Options.fullscreen = fullscreen
	Options.borderless = borderless
	Options.stretchmode = stretchmode
	Options.vsync = find_node("ButtonVsync").pressed
	Options.masterVolume = find_node("MasterVolumeSlider").value
	Options.soundVolume = find_node("SoundVolumeSlider").value
	Options.ambienceVolume = find_node("AmbienceVolumeSlider").value
	Options.musicVolume = find_node("MusicVolumeSlider").value
	Options.gamepadStickDeadZone = find_node("GamepadDeadZoneSlider").value
	Options.shakeIntensity = find_node("ShakeIntensitySlider").value
	Options.vibrationStrength = find_node("VibrationIntensitySlider").value
	Options.shakeDrill = find_node("ShakeDrill").pressed
	Options.photosensitive = find_node("ButtonPhotoSensitivity").pressed
	Options.disableCritters = find_node("ButtonDisableCritters").pressed
	Options.tryAutoSwitchGamepad = find_node("AutoSwitchGamepadCheckBox").pressed
	Options.enableSeasonalContent = find_node("EnableSeasonalEventButton").pressed
	Options.cyclesWithoutMusic = find_node("MusicFrequencySlider").value
	GameWorld.updateSeasonalEvents()
	
	Options.visibleMonsters = find_node("ButtonHighlightedMonsters").pressed
	Options.saveOptions()
	Audio.sound("gui_select")
	emit_signal("close")

func _on_ButtonCancel_pressed()->void :
	Options.updateAudioBusses()
	Audio.sound("gui_select")

func _on_MasterVolumeSlider_value_changed(value: float)->void :






	if readied:
		Audio.sound("gui_slider")
	find_node("MasterVolumeLabel").text = "%.0f" % (10 * value)
	if value == 0:
		Audio.set_bus_volume(Audio.BUS_MASTER, - 90)
	else:
		Audio.set_bus_volume(Audio.BUS_MASTER, (value * 24) - 24)

func _on_ShakeIntensitySlider_value_changed(value: float)->void :
	find_node("ShakeIntensityLabel").text = "%0.f%%" % (100 * value)

func _on_MusicVolumeSlider_value_changed(value: float)->void :
	if readied:
		Audio.sound("gui_slider")
	find_node("MusicVolumeLabel").text = "%.0f" % (10 * value)
	if value == 0:
		Audio.set_bus_volume(Audio.BUS_MUSIC, - 90)
	else:
		Audio.set_bus_volume(Audio.BUS_MUSIC, (value * 24) - 24)

func _on_SoundVolumeSlider_value_changed(value: float)->void :
	if readied:
		Audio.sound("gui_slider")
	find_node("SoundVolumeLabel").text = "%.0f" % (10 * value)
	if value == 0:
		Audio.set_bus_volume(Audio.BUS_SOUNDS, - 90)
	else:
		Audio.set_bus_volume(Audio.BUS_SOUNDS, (value * 24) - 24)
	
	if readied:
		$SoundExample.play()

func _on_AmbienceVolumeSlider_value_changed(value):
	if readied:
		Audio.sound("gui_slider")
	find_node("AmbienceVolumeLabel").text = "%.0f" % (10 * value)
	if value == 0:
		Audio.set_bus_volume(Audio.BUS_AMBIENCE, - 90)
	else:
		Audio.set_bus_volume(Audio.BUS_AMBIENCE, (value * 24) - 24)

func _on_GamepadDeadZoneSlider_value_changed(value: float)->void :
	gamepadStickDeadZone = value
	find_node("GamepadDeadZoneLabel").text = "%.2f" % (value)

func _on_GamepadStickDeadZoneTimer_timeout()->void :
	find_node("StickMoveRect").color = Style.STRUCT_DARK

func stick_move(event: InputEventJoypadMotion):
	if abs(event.axis_value) >= gamepadStickDeadZone:
		find_node("StickMoveRect").color = Style.LIVE
	else:
		$GamepadStickDeadZoneTimer.start()

func toggleButtonSound(button_pressed):
	Audio.sound("gui_toggle")

func _on_CategoryButton_pressed(cat):
	Audio.sound("gui_tab")
	showCategory(cat)

func tabLeft():
	var i = categories.find(currentCategory)
	if i > 0:
		showCategory(categories[i - 1])

func tabRight():
	var i = categories.find(currentCategory)
	if i < categories.size() - 1:
		showCategory(categories[i + 1])

func _on_KeybindingsButton_pressed():
	Audio.sound("gui_select")
	var i = preload("res://gui/PopupInput.gd").new()
	i.popup = preload("res://systems/options/KeyBindingsPanel.tscn").instance()
	i.popup.connect("quit", i, "desintegrate")
	i.connect("stopping", i.popup, "queue_free")
	i.connect("stopping", InputSystem, "grabFocus", [find_node("KeybindingsButton")])
	get_parent().add_child(i.popup)
	i.integrate(self)

func _on_ButtonResized_pressed():
	stretchmode = SceneTree.STRETCH_MODE_2D

func _on_ButtonScaled_pressed():
	stretchmode = SceneTree.STRETCH_MODE_VIEWPORT

func _on_LanguageSelectButton_pressed():
	Audio.sound("gui_select")
	var i = preload("res://gui/PopupInput.gd").new()
	i.popup = preload("res://systems/options/LanguageSelectPanel.tscn").instance()
	i.popup.connect("quit", i, "desintegrate")
	i.connect("stopping", i.popup, "queue_free")
	i.connect("stopping", InputSystem, "grabFocus", [find_node("LanguageSelectButton")])
	get_parent().add_child(i.popup)
	i.integrate(self)

func _on_ResetTutorialsButton_pressed():
	Audio.sound("gui_select")
	find_node("ResetTutorialsButton").disabled = true
	GameWorld.resetTutorials()

func playButtonSound():
	Audio.sound("gui_select")

func _on_UnlockEverythingButton_pressed():
	GameWorld.unlockEverything()

func _on_ResetProgressButton_pressed():
	GameWorld.unlockedElements.clear()
	GameWorld.unlockedSkins.clear()
	GameWorld.unlockedPets.clear()
	GameWorld.deleteMetaState()
	GameWorld.loadMetaState()

func _on_ResetAchievementsButton_pressed():
	SteamGlobal.Steam.resetAllStats(true)

func _on_VibrationIntensitySlider_value_changed(value):
	find_node("VibrationIntensityLabel").text = "%0.f%%" % (100 * value)

func _on_MusicFrequencySlider_value_changed(value):
	if readied:
		Audio.sound("gui_slider")
	find_node("MusicFrequencyLabel").text = "%.0f" % (value)
