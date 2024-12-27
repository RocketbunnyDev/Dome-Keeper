extends Node

var fixedLocale: String

var masterVolume: float
var musicVolume: float
var ambienceVolume: float
var soundVolume: float
var cyclesWithoutMusic: int

var tryAutoSwitchGamepad: = false
var useGamepad: = false
var fullscreen: = false
var borderless: = false
var vsync: = false
var targetfps: int

var photosensitive: = false
var visibleMonsters: = false
var disableCritters: = false

var stretchmode: = 0
var gamepadStickDeadZone: float = 0.2
var gamepadTriggerDeadZone: float = 0.2
var vibrationStrength: = 1.0

var shakeIntensity: = 1.0
var shakeDrill: = true

var enableSeasonalContent: bool

var lastGamepadDeviceId: = - 1

const optionsPath: = "user://options.txt"
const KEY_BINDINGS = "user://keybindings.cfg"

const GamepadTranslations: = {
	"0": "A", 
	"1": "B", 
	"2": "X", 
	"3": "Y", 
	"4": "LB", 
	"5": "RB", 
	"6": "LT", 
	"7": "RT", 
	"12": "Up", 
	"13": "Down", 
	"14": "Left", 
	"15": "Right", 
	"axis0": "Left Stick Horizontal", 
	"axis1": "Left Stick Vertical", 
	"axis2": "Right Stick Horizontal", 
	"axis3": "Right Stick Vertical", 
	"axis6": "LT", 
	"axis7": "RT", 
}

const GamepadTranslationsPs4: = {
	"0": "Cross", 
	"1": "Circle", 
	"2": "Square", 
	"3": "Triangle", 
	"4": "LB", 
	"5": "RB", 
	"6": "LT", 
	"7": "RT", 
	"12": "Up", 
	"13": "Down", 
	"14": "Left", 
	"15": "Right", 
	"axis0": "Left Stick Horizontal", 
	"axis1": "Left Stick Vertical", 
	"axis2": "Right Stick Horizontal", 
	"axis3": "Right Stick Vertical", 
	"axis6": "LT", 
	"axis7": "RT", 
}

const GamepadTranslationsSwitchPro: = {
	"0": "B", 
	"1": "A", 
	"2": "Y", 
	"3": "X", 
	"4": "LB", 
	"5": "RB", 
	"6": "LT", 
	"7": "RT", 
	"12": "Up", 
	"13": "Down", 
	"14": "Left", 
	"15": "Right", 
	"axis0": "Left Stick Horizontal", 
	"axis1": "Left Stick Vertical", 
	"axis2": "Right Stick Horizontal", 
	"axis3": "Right Stick Vertical", 
	"axis6": "LT", 
	"axis7": "RT", 
}

func getGamepadName()->String:
	var gamepad: String = Input.get_joy_name(0)
	gamepad = gamepad.to_lower()
	if gamepad.find("sony") >= 0 or gamepad.find("ps4") >= 0 or gamepad.find("dualshock") >= 0:
		gamepad = "ps4"
	elif gamepad.find("nintendo") >= 0 and gamepad.find("pro") >= 0:
		gamepad = "switchpro"
	else:
		
		gamepad = "xbox"
	return gamepad
	
func getGamepadTranslations(input):
	match getGamepadName():
		"ps4":
			return GamepadTranslationsPs4.get(str(input), str(input))
		"switchpro":
			return GamepadTranslationsSwitchPro.get(str(input), str(input))
		_:
			return GamepadTranslations.get(str(input), str(input))

func init():
	loadOptions()
	updateFontSizes()

func setActionIcons(node):
	if node.name.begins_with("Action") and node.has_method("updateGlyph"):
		node.updateGlyph()
	for c in node.get_children():
		setActionIcons(c)

func saveOptions():
	
	updateAudioBusses()
	updateControlGlyphs()
	updateDeadzone()
	
	OS.window_fullscreen = fullscreen
	if OS.get_name() != "OSX":
		OS.window_borderless = borderless
	OS.vsync_enabled = vsync
	get_tree().set_screen_stretch(stretchmode, SceneTree.STRETCH_ASPECT_EXPAND, Vector2(1920, 1080))
	
	var save = File.new()
	var err = save.open(optionsPath, File.WRITE)
	if err == 0:
		var d = {
			"gamepadStickDeadZone": gamepadStickDeadZone, 
			"tryAutoSwitchGamepad": tryAutoSwitchGamepad, 
			"fullscreen": fullscreen, 
			"borderless": borderless, 
			"stretchmode": stretchmode, 
			"vsync": vsync, 
			"photosensitive": photosensitive, 
			"visibleMonsters": visibleMonsters, 
			"disableCritters": disableCritters, 
			"masterVolume": masterVolume, 
			"musicVolume": musicVolume, 
			"ambienceVolume": ambienceVolume, 
			"soundVolume": soundVolume, 
			"cyclesWithoutMusic": cyclesWithoutMusic, 
			"vibrationStrength": vibrationStrength, 
			"shakeIntensity": shakeIntensity, 
			"shakeDrill": shakeDrill, 
			"enableSeasonalContent": enableSeasonalContent, 
			
			"locale": TranslationServer.get_locale()
			}
		save.store_string(JSON.print(d))
		save.close()
		Backend.event("options_changed", d)
		
func loadOptions():
	var save: = File.new()
	var err = save.open(optionsPath, File.READ)
	var options = {}
	if err == OK:
		var i = save.get_as_text()
		var parsed = JSON.parse(i)
		if parsed.result:
			options = parsed.result
	
	gamepadStickDeadZone = options.get("gamepadStickDeadZone", 0.2)
	tryAutoSwitchGamepad = options.get("tryAutoSwitchGamepad", false)
	fullscreen = options.get("fullscreen", true)
	borderless = options.get("borderless", false)
	borderless = false
	stretchmode = options.get("stretchmode", SceneTree.STRETCH_MODE_2D)
	vsync = options.get("vsync", true)
	photosensitive = options.get("photosensitive", false)
	visibleMonsters = options.get("visibleMonsters", false)
	disableCritters = options.get("disableCritters", false)
	masterVolume = options.get("masterVolume", 1.0)
	soundVolume = options.get("soundVolume", 1.0)
	ambienceVolume = options.get("ambienceVolume", 1.0)
	musicVolume = options.get("musicVolume", 0.9)
	cyclesWithoutMusic = options.get("cyclesWithoutMusic", 2)
	shakeIntensity = options.get("shakeIntensity", 1.0)
	vibrationStrength = options.get("vibrationStrength", 1.0)
	shakeDrill = options.get("shakeDrill", false)
	targetfps = options.get("targetfps", 250)
	Logger.info("setting target fps to " + str(targetfps))
	Engine.set_target_fps(targetfps)
	
	enableSeasonalContent = options.get("enableSeasonalContent", true)
	GameWorld.updateSeasonalEvents()
	updateDeadzone()
	
	updateAudioBusses()
	OS.window_fullscreen = fullscreen
	if OS.get_name() != "OSX":
		OS.window_borderless = borderless
	OS.vsync_enabled = vsync
	
	get_tree().set_screen_stretch(stretchmode, SceneTree.STRETCH_ASPECT_EXPAND, Vector2(1920, 1080))
	if not fullscreen:
		var w = OS.get_real_window_size()
		var s = OS.get_screen_size()
		s.y *= 0.95
		if w.x > s.x or w.y > s.y:
			OS.window_maximized = true
	
	loadKeyBindings()
	
	var locale: String
	if fixedLocale:
		locale = fixedLocale
	else:
		locale = options.get("locale", OS.get_locale())
	if locale != TranslationServer.get_locale():
		Logger.info("current locale is " + str(TranslationServer.get_locale()) + ", changing to " + locale)
		$Tween.interpolate_callback(TranslationServer, 1.0, "set_locale", locale)
		$Tween.start()
	else:
		Logger.info("leaving locale at " + locale)

func loadKeyBindings():
	var config = ConfigFile.new()
	var err = config.load(KEY_BINDINGS)
	if err:
		config.save(KEY_BINDINGS)
	else:
		for section in config.get_sections():
			for action_name in config.get_section_keys(section):
				InputMap.action_erase_events(action_name)
				var allBindings = config.get_value(section, action_name)
				for binding in allBindings:
					if binding and binding.find(":") != - 1:
						var split = binding.split(":")
						var event: InputEvent
						match split[0]:
							"keyboard":
								event = InputEventKey.new()
								event.scancode = int(split[1])
							"gamepadbutton":
								event = InputEventJoypadButton.new()
								event.button_index = int(split[1])
							"gamepad":
								
								event = InputEventJoypadButton.new()
								event.button_index = int(split[1])
							"gamepadaxis":
								event = InputEventJoypadMotion.new()
								event.axis = int(split[1])
								event.axis_value = int(split[2])
						InputMap.action_add_event(action_name, event)

func updateAudioBusses():
	if masterVolume == 0:
		Audio.set_bus_volume(Audio.BUS_MASTER, - 90)
	else:
		Audio.set_bus_volume(Audio.BUS_MASTER, (masterVolume * 24) - 24)
	if soundVolume == 0:
		Audio.set_bus_volume(Audio.BUS_SOUNDS, - 90)
	else:
		Audio.set_bus_volume(Audio.BUS_SOUNDS, (soundVolume * 24) - 24)
	if musicVolume == 0:
		Audio.set_bus_volume(Audio.BUS_MUSIC, - 90)
	else:
		Audio.set_bus_volume(Audio.BUS_MUSIC, (musicVolume * 24) - 24)
	if ambienceVolume == 0:
		Audio.set_bus_volume(Audio.BUS_AMBIENCE, - 90)
	else:
		Audio.set_bus_volume(Audio.BUS_AMBIENCE, (ambienceVolume * 24) - 24)

func updateDeadzone():
	for action in ["ui_left", "ui_right", "ui_up", "ui_down"]:
		InputMap.action_set_deadzone(action, 0.5)

func setUseGamepad(b, deviceId: int = - 1):
	if SteamGlobal.Steam.isSteamRunningOnSteamDeck():
		useGamepad = true
		GameWorld.setShowMouse(false)
		updateControlGlyphs()
	else:
		if useGamepad != b:
			useGamepad = b
			updateControlGlyphs()
			GameWorld.setShowMouse(GameWorld.showMouse)
		if tryAutoSwitchGamepad:
			if useGamepad and lastGamepadDeviceId != deviceId:
				Logger.info("changing gamepad input events from device " + str(lastGamepadDeviceId) + " to device " + str(deviceId))
				for action in InputMap.get_actions():
					for inputEvent in InputMap.get_action_list(action):
						if inputEvent is InputEventJoypadButton or inputEvent is InputEventJoypadMotion:
							inputEvent.device = deviceId
				lastGamepadDeviceId = deviceId
	
func updateControlGlyphs():
	for l in get_tree().get_nodes_in_group("gamepadListeners"):
		Options.setActionIcons(l)

func eventToKeyConfig(event: InputEvent):
	if event is InputEventKey:
		return "keyboard:" + str(event.scancode)
	elif event is InputEventJoypadButton:
		return "gamepadbutton:" + str(event.button_index)
	elif event is InputEventJoypadMotion:
		return "gamepadaxis:" + str(event.axis) + ":" + str(event.axis_value)

func remapInputEvent(from: String, to: String):
	Logger.info("remapping input action '" + from + "' to " + str(to))








	var config = ConfigFile.new()
	var err = config.load(KEY_BINDINGS)
	if err:
		return 
	var hasChanges: = false
	for section in config.get_sections():
		for action_name in config.get_section_keys(section):
			if action_name == from:
				config.set_value(section, to, config.get_value(section, action_name))
				config.erase_section_key(section, from)
				hasChanges = true
	
	if hasChanges:
		config.save(Options.KEY_BINDINGS)

func updateFontSizes():
	if SteamGlobal.Steam.isSteamRunningOnSteamDeck():
		for font in [
			preload("res://gui/fonts/FontNormal.tres"), 
			preload("res://gui/fonts/cyrillic/FontCyNormal.tres"), 
			preload("res://gui/fonts/hungarian/FontNormal.tres"), 
			preload("res://gui/fonts/ja/FontNormal.tres"), 
			preload("res://gui/fonts/korean/FontNormal.tres"), 
			preload("res://gui/fonts/simplified chinese/FontNormal.tres"), 
			preload("res://gui/fonts/traditional chinese/FontNormal.tres"), 
		]:
			font.size = 28
		
		for font in [
			preload("res://gui/fonts/FontButton.tres"), 
			preload("res://gui/fonts/cyrillic/FontCyButton.tres"), 
			preload("res://gui/fonts/hungarian/FontButton.tres"), 
			preload("res://gui/fonts/ja/FontButton.tres"), 
			preload("res://gui/fonts/korean/FontButton.tres"), 
			preload("res://gui/fonts/simplified chinese/FontButton.tres"), 
			preload("res://gui/fonts/traditional chinese/FontButton.tres"), 
		]:
			font.size = 28
		
		for font in [
			preload("res://gui/fonts/FontSmall.tres"), 
			preload("res://gui/fonts/cyrillic/FontCySmall.tres"), 
			preload("res://gui/fonts/hungarian/FontSmall.tres"), 
			preload("res://gui/fonts/ja/FontSmall.tres"), 
			preload("res://gui/fonts/korean/FontSmall.tres"), 
			preload("res://gui/fonts/simplified chinese/FontSmall.tres"), 
			preload("res://gui/fonts/traditional chinese/FontSmall.tres"), 
		]:
			font.size = 24
