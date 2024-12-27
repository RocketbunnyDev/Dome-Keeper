extends Container

signal request_change(actionName, buttonName)

var inputEvents: = [null, null, null, null]
var controls: = [null, null, null, null]

var group: String
var action_name: String


func init(action_name: String, title: String, group: String):
	self.group = group
	self.action_name = action_name
	var action_list = InputMap.get_action_list(action_name)
	var keyboardActions: = 0
	var gamepadActions: = 0
	find_node("ActionNameLabel").text = title
	for action in action_list:
		if action is InputEventKey:
			if keyboardActions <= 1:
				keyboardActions += 1
				var l = find_node("KeyboardButton" + str(keyboardActions))
				l.text = OS.get_scancode_string(action.scancode)
				inputEvents[keyboardActions - 1] = Options.eventToKeyConfig(action)
		elif action is InputEventJoypadButton:
			if gamepadActions <= 1:
				gamepadActions += 1
				var l = find_node("GamepadButton" + str(gamepadActions))
				l.text = Options.getGamepadTranslations(action.button_index)
				inputEvents[2 + gamepadActions - 1] = Options.eventToKeyConfig(action)
		elif action is InputEventJoypadMotion:
			if gamepadActions <= 1:
				gamepadActions += 1
				var l = find_node("GamepadButton" + str(gamepadActions))
				l.text = Options.getGamepadTranslations("axis" + str(action.axis))
				inputEvents[2 + gamepadActions - 1] = Options.eventToKeyConfig(action)
	if (action_name == "ui_left" or action_name == "ui_right" or action_name == "ui_up" or action_name == "ui_down"):
		var l = find_node("GamepadButton" + str(gamepadActions))
		l.disabled = true
	
	for i in range(0, 2):
		var nodeName = "KeyboardButton" + str(i + 1)
		var l = find_node(nodeName)
		l.connect("pressed", self, "emit_signal", ["request_change", action_name, nodeName])
		controls[i] = nodeName
	
	for i in range(0, 2):
		var nodeName = "GamepadButton" + str(i + 1)
		var l = find_node(nodeName)
		if not l.disabled:
			l.connect("pressed", self, "emit_signal", ["request_change", action_name, nodeName])
		controls[2 + i] = nodeName

func apply(buttonName, capturedEvent):
	var l = find_node(buttonName)
	
	var i = controls.find(buttonName)
	if capturedEvent is InputEventKey:
		l.text = OS.get_scancode_string(capturedEvent.scancode)
		inputEvents[i] = Options.eventToKeyConfig(capturedEvent)
	elif capturedEvent is InputEventJoypadButton:
		l.text = Options.getGamepadTranslations(capturedEvent.button_index)
		inputEvents[i] = Options.eventToKeyConfig(capturedEvent)
	elif capturedEvent is InputEventJoypadMotion:
		l.text = Options.getGamepadTranslations("axis" + str(capturedEvent.axis))
		inputEvents[i] = Options.eventToKeyConfig(capturedEvent)
