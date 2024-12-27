extends Control

signal quit

const INPUT_ACTIONS = {
	"ui": [
		"ui_select", 
		"ui_cancel", 
		"ui_up", 
		"ui_left", 
		"ui_down", 
		"ui_right", 
	], 
	"keeper": [
		"keeper_gadget1", 
		"keeper_gadget2", 
	], 
	"keeper1": [
		"keeper1_pickup", 
		"keeper1_drop", 
	], 
	"keeper2": [
		"keeper2_gravityball", 
		"keeper2_gravitycollect", 
	], 
	"dome": [
		"dome_fire", 
		"dome_ability1", 
		"dome_upgrades", 
		"dome_battle", 
	], 
	}

const translations: = {
	"keeper": "options.keybindings.action.keeper", 
	"keeper_gadget1": "options.keybindings.action.keeper.gadget1", 
	"keeper_gadget2": "options.keybindings.action.keeper.gadget2", 
	"keeper1": "upgrades.keeper1.title", 
	"keeper1_pickup": "options.keybindings.action.keeper.pickup", 
	"keeper1_drop": "options.keybindings.action.keeper.drop", 
	"keeper2": "upgrades.keeper2.title", 
	"keeper2_gravityball": "options.keybindings.action.keeper.gravityball", 
	"keeper2_gravitycollect": "options.keybindings.action.keeper.gravitycollect", 
	
	"dome": "options.keybindings.action.dome", 
	"dome_fire": "options.keybindings.action.dome.fire", 
	"dome_upgrades": "options.keybindings.action.dome.upgrade", 
	"dome_battle": "options.keybindings.action.dome.battle", 
	"dome_ability1": "options.keybindings.action.dome.battleability1", 
	
	"ui": "options.keybindings.action.general", 
	"ui_cancel": "options.keybindings.action.general.back", 
	"ui_select": "options.keybindings.action.general.use", 
	"ui_left": "options.keybindings.action.general.left", 
	"ui_right": "options.keybindings.action.general.right", 
	"ui_up": "options.keybindings.action.general.up", 
	"ui_down": "options.keybindings.action.general.down", 
}


var lastFocusButton

func _ready():
	
	translations["keeper1"] = tr("upgrades.keeper1.title")
	translations["dome1"] = tr("upgrades.dome1.title")
	buildBindingUi()
	$ColorRect.visible = false
	InputSystem.grabFocus(find_node("ButtonApply"))
	Style.init(self)

func _on_ButtonApply_pressed():
	var config = ConfigFile.new()
	for binding in get_tree().get_nodes_in_group("key_bindings"):
		match binding.action_name:
			"ui_select":
				config.set_value(binding.group, "ui_accept", binding.inputEvents)
			"ui_left":
				binding.inputEvents.append("gamepadaxis:0:-1")
			"ui_right":
				binding.inputEvents.append("gamepadaxis:0:1")
			"ui_up":
				binding.inputEvents.append("gamepadaxis:1:-1")
			"ui_down":
				binding.inputEvents.append("gamepadaxis:1:1")
		config.set_value(binding.group, binding.action_name, binding.inputEvents)
	config.save(Options.KEY_BINDINGS)
	emit_signal("quit")
	
	Options.loadKeyBindings()

func _on_ResetButton_pressed():
	Audio.sound("gui_select")
	InputMap.load_from_globals()
	buildBindingUi()

func buildBindingUi():
	var KeyBindings = find_node("KeyBindings")
	for c in KeyBindings.get_children():
		c.queue_free()
	for groupName in INPUT_ACTIONS:
		var sep = HSeparator.new()
		KeyBindings.add_child(sep)
		var l = Label.new()
		l.text = translations[groupName]
		l.set("custom_fonts/font", preload("res://gui/fonts/FontLarge.tres"))

		KeyBindings.add_child(l)
		for action_name in INPUT_ACTIONS[groupName]:
			var bindingEntry = preload("res://systems/options/KeyBinding.tscn").instance()
			bindingEntry.init(action_name, translations[action_name], groupName)
			KeyBindings.add_child(bindingEntry)
			bindingEntry.connect("request_change", self, "showInputPopup", [bindingEntry])
	
	Style.init(KeyBindings)

var catchNewInputInputProcessor
func showInputPopup(actionName: String, buttonName: String, bindingEntry):
	Audio.sound("gui_select")
	find_node("RebindingTitleLabel").text = tr("options.keybindings.rebinding") + " \"" + tr(translations[actionName]) + "\""
	catchNewInputInputProcessor = preload("res://systems/options/BindKeyInputProcessor.gd").new()
	catchNewInputInputProcessor.buttonName = buttonName
	catchNewInputInputProcessor.bindingEntry = bindingEntry
	var newKeyLabel = find_node("NewKeyLabel")
	catchNewInputInputProcessor.inputLabel = newKeyLabel
	catchNewInputInputProcessor.connect("onStart", self, "showCatchInputPopup")
	catchNewInputInputProcessor.connect("onStop", self, "hideCatchInputPopup")
	catchNewInputInputProcessor.connect("captured", self, "setCaptured")
	catchNewInputInputProcessor.integrate(self)

func showCatchInputPopup():
	$ColorRect.visible = true
	lastFocusButton = get_focus_owner()
	lastFocusButton.release_focus()
	find_node("CaptureKeyControls").visible = false
	find_node("ErrorMessageLabel").visible = false

func hideCatchInputPopup():
	$ColorRect.visible = false
	InputSystem.grabFocus(lastFocusButton)

func _on_CancelInputButton_pressed():
	catchNewInputInputProcessor.desintegrate()
	catchNewInputInputProcessor = null

func _on_ApplyInputButton_pressed():
	Audio.sound("gui_select")
	if not catchNewInputInputProcessor:
		
		return 
	
	catchNewInputInputProcessor.apply()
	catchNewInputInputProcessor.desintegrate()
	catchNewInputInputProcessor = null

func clearCapture():
	find_node("CaptureKeyControls").visible = false
	find_node("ErrorMessageLabel").visible = false
	if catchNewInputInputProcessor:
		catchNewInputInputProcessor.startCapture()

func setCaptured():
	find_node("CaptureKeyControls").visible = true
	var mismatchKey = catchNewInputInputProcessor.capturedEvent is InputEventKey and catchNewInputInputProcessor.buttonName.find("Gamepad") != - 1
	var mismatchPad = catchNewInputInputProcessor.capturedEvent is InputEventJoypadButton and catchNewInputInputProcessor.buttonName.find("Keyboard") != - 1
	var mismatch = mismatchKey or mismatchPad
	find_node("ErrorMessageLabel").visible = mismatch
	if mismatchKey:
		find_node("ErrorMessageLabel").text = "options.keybindings.rebinding.error.keyboard"
	if mismatchPad:
		find_node("ErrorMessageLabel").text = "options.keybindings.rebinding.error.gamepad"
	find_node("ApplyInputButton").disabled = mismatch
	if mismatch:
		InputSystem.grabFocus(find_node("CaptureButton"))
	else:
		InputSystem.grabFocus(find_node("ApplyInputButton"))

func _on_CancelButton_pressed():
	Audio.sound("gui_select")
	emit_signal("quit")
