extends TextureRect

export  var action = "" setget set_action, get_action


func _ready():
	updateGlyph()

func set_action(value: String):
	action = value
	updateGlyph()

func get_action():
	return action

func updateGlyph():
	match action:
		"pickup":
			match Level.keeperId():
				"keeper1": action = "keeper1_pickup"
				"keeper2": action = "keeper2_gravitycollect"
	
	
	if Options.useGamepad:
		var button = get_first_gamepad_button(action)
		if button[0]:
			texture = button[0]
			$Label.text = ""
		else:
			texture = preload("res://gui/icons/blank_button.png")
			$Label.text = button[1]

	
	if not Options.useGamepad:
		var key = get_first_key(action)
		if key[0]:
			texture = key[0]
			$Label.text = ""
		else:
			texture = preload("res://gui/icons/blank_key.png")
			$Label.text = key[1]
			
	rect_min_size = texture.get_size() * 4


func get_first_key(action: String)->Array:
	var key = null
	var key_name = ""
	
	var action_list = InputMap.get_action_list(action)
	
	for a in action_list:
		if a is InputEventKey:
			key_name = OS.get_scancode_string(a.scancode)
			var scancode = a.scancode
			match scancode:
				KEY_LEFT:
					key = preload("res://gui/icons/key_links.png")
				KEY_RIGHT:
					key = preload("res://gui/icons/key_rechts.png")
				KEY_UP:
					key = preload("res://gui/icons/key_oben.png")
				KEY_DOWN:
					key = preload("res://gui/icons/key_unten.png")
				KEY_SPACE:
					key = preload("res://gui/icons/key_leer.png")
				KEY_BACKSPACE:
					key = preload("res://gui/icons/key_back.png")
				KEY_ENTER:
					key = preload("res://gui/icons/key_enter.png")
				KEY_TAB:
					key = preload("res://gui/icons/key_tab.png")
				KEY_ESCAPE:
					key = preload("res://gui/icons/key_esc.png")
				KEY_SHIFT:
					key = preload("res://gui/icons/key_shift.png")
				KEY_CONTROL:
					key = preload("res://gui/icons/key_control.png")
				KEY_CAPSLOCK:
					key = preload("res://gui/icons/key_capslock.png")
					
			break
			
	return [key, key_name]
	

func get_first_gamepad_button(action: String)->Array:
	var button = null
	var button_name = ""
	
	var action_list = InputMap.get_action_list(action)
	var gamepad = Options.getGamepadName()
		
	for a in action_list:
		match action:
			"ui_left":
				button = preload("res://gui/icons/gamepad_stick_left.png")
			"ui_right":
				button = preload("res://gui/icons/gamepad_stick_right.png")
			"ui_left":
				button = preload("res://gui/icons/gamepad_stick_left.png")
			"ui_right":
				button = preload("res://gui/icons/gamepad_stick_right.png")
			
		if a is InputEventJoypadButton or a is InputEventJoypadMotion:
			var match_against = - 1
			if a is InputEventJoypadButton:
				button_name = Input.get_joy_button_string(a.button_index)
				match_against = a.button_index
			if a is InputEventJoypadMotion:
				button_name = Input.get_joy_button_string(a.get_axis())
				match_against = a.get_axis()
			if match_against == - 1:
				break
			match match_against:
				0:
					button = load("res://gui/icons/%s/gamepad_button_down.png" % gamepad)
				1:
					button = load("res://gui/icons/%s/gamepad_button_right.png" % gamepad)
				2:
					button = load("res://gui/icons/%s/gamepad_button_left.png" % gamepad)
				3:
					button = load("res://gui/icons/%s/gamepad_button_up.png" % gamepad)
				4:
					button = preload("res://gui/icons/gamepad_lb.png")
				5:
					button = preload("res://gui/icons/gamepad_rb.png")
				6:
					button = preload("res://gui/icons/gamepad_lt.png")
				7:
					button = preload("res://gui/icons/gamepad_rt.png")
				10:
					button = preload("res://gui/icons/gamepad_select.png")
				11:
					button = preload("res://gui/icons/gamepad_menu.png")
				12:
					button = preload("res://gui/icons/gamepad_cross_up.png")
				13:
					button = preload("res://gui/icons/gamepad_cross_down.png")
				14:
					button = preload("res://gui/icons/gamepad_cross_left.png")
				15:
					button = preload("res://gui/icons/gamepad_cross_right.png")
			break
			
	return [button, button_name]
