extends InputProcessor

var stickMove: = Vector2()
var leftKeyDown: = false
var rightKeyDown: = false
var downKeyDown: = false
var upKeyDown: = false
var fireValue: = 0.0
var specialValue: = 0.0

var last_LT: = 0.0
var last_RT: = 0.0

var popup

var allowMove: = true
var allowShoot: = true

func notLeaf():
	if child and child is get_script():
		return 
	
	leftKeyDown = false
	rightKeyDown = false
	downKeyDown = false
	upKeyDown = false
	fireValue = 0.0
	specialValue = 0.0

func handleStart():
	popup.moveIn(true)
	Audio.sound("charge_on_" + Level.domeId())
	for cannon in get_tree().get_nodes_in_group("primaryWeapon"):
		cannon.start()

func handleStop():
	popup.moveOut( - 1)
	Audio.sound("charge_off_" + Level.domeId())
	for cannon in get_tree().get_nodes_in_group("primaryWeapon"):
		cannon.stop()
	for cannon in get_tree().get_nodes_in_group("primaryWeapon"):
		cannon.move(Vector2.ZERO, allowMove)
	for cannon in get_tree().get_nodes_in_group("primaryWeapon"):
		cannon.action(0.0, 0.0, allowShoot)

func keyEvent(event)->bool:
	if pressed(event, "ui_left"):
		leftKeyDown = true
	elif pressed(event, "ui_right"):
		rightKeyDown = true
	elif pressed(event, "dome_fire"):
		fireValue = 1.0
	elif pressed(event, "dome_special"):
		specialValue = 1.0
	elif pressed(event, "ui_down"):
		downKeyDown = true
	elif pressed(event, "ui_up"):
		upKeyDown = true
	elif justPressed(event, "ui_cancel"):
		desintegrate()
	elif released(event, "ui_left"):
		leftKeyDown = false
	elif released(event, "ui_right"):
		rightKeyDown = false
	elif released(event, "dome_fire"):
		fireValue = 0.0
	elif released(event, "dome_special"):
		specialValue = 0.0
	elif released(event, "ui_down"):
		downKeyDown = false
	elif released(event, "ui_up"):
		upKeyDown = false
	elif justPressed(event, "cheats"):
		
		return false
	elif justPressed(event, "escape"):
		return false
	elif justPressed(event, "dome_ability1"):
		for s in get_tree().get_nodes_in_group("battle1"):
			var consumed = s.executeBattle1()
			if consumed:
				break
	
	return true

func stick_move(event: InputEventJoypadMotion)->bool:
	if event.axis == 0:
		if abs(event.axis_value) <= Options.gamepadStickDeadZone:
			stickMove.x = 0
		else:
			stickMove.x = axisValueDeadzoned(event.axis_value, Options.gamepadStickDeadZone)
	elif event.axis == 1:
		if abs(event.axis_value) <= Options.gamepadStickDeadZone:
			stickMove.y = 0
		else:
			stickMove.y = axisValueDeadzoned(event.axis_value, Options.gamepadStickDeadZone)
	
	if InputMap.event_is_action(event, "dome_fire"):
		fireValue = event_value(event)
	if InputMap.event_is_action(event, "dome_special"):
		specialValue = event_value(event)
	return true























func axisValueDeadzoned(axis_value, deadzone)->float:
	var result = axis_value - (sign(axis_value) * deadzone)
	result *= 1.0 / (1.0 - deadzone)
	return result

func event_value(event):
	if event is InputEventJoypadMotion:
		if event.axis <= 3:
			if abs(event.axis_value) > Options.gamepadStickDeadZone:
				return axisValueDeadzoned(event.axis_value, Options.gamepadStickDeadZone)
		elif event.axis == 6 or event.axis == 7:
			if abs(event.axis_value) > Options.gamepadTriggerDeadZone:
				return axisValueDeadzoned(event.axis_value, Options.gamepadTriggerDeadZone)
	elif event is InputEventJoypadButton:
		
		return event.pressure
	return 0.0

func _process(delta):
	var move: = Vector2()
	if leftKeyDown:
		move.x -= 1
	if rightKeyDown:
		move.x += 1
	move.x = clamp(move.x + stickMove.x, - 1.0, 1.0)


	if upKeyDown:
		move.y -= 1
	if downKeyDown:
		move.y += 1
	move.y = clamp(move.y + stickMove.y, - 1.0, 1.0)


	for cannon in get_tree().get_nodes_in_group("primaryWeapon"):
		cannon.move(move, allowMove)
		cannon.action(fireValue, specialValue, allowShoot)

