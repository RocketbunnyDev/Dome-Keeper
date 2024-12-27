extends InputProcessor

signal escape

var leftStickMove: = Vector2()

var leftKeyDown: = false
var rightKeyDown: = false
var upKeyDown: = false
var downKeyDown: = false

var useKeyDown: = false
var useHold: = false
var useKeyDownTime: = 0.0
var useKeyCooldown: = 0.0

var keeper

func _process(delta):
	if GameWorld.paused:
		return 
	
	if useKeyDown:
		useKeyDownTime += delta
		if useKeyDownTime > 0.3:
			keeper.useHold()
			useHold = true
			
			useKeyDownTime -= useKeyCooldown
			useKeyCooldown = max(0.05, useKeyCooldown * 0.6)
	else:
		useKeyCooldown = 0.25

func becameLeaf():
	notLeaf()
	GameWorld.setShowMouse(false)

	if Options.useGamepad:
		var hor: float = Input.get_axis("ui_left", "ui_right")
		var ver: float = Input.get_axis("ui_up", "ui_down")
		leftStickMove.x = hor
		leftStickMove.y = ver
		if leftStickMove.length() > 0.0:
			processStickMove()

func notLeaf():
	leftKeyDown = false
	rightKeyDown = false
	upKeyDown = false
	downKeyDown = false
	useKeyDown = false
	useHold = false
	useKeyDownTime = 0.0
	keeper.moveDirectionInput.x = 0
	keeper.moveDirectionInput.y = 0

func handleStop():
	notLeaf()

func keyEvent(event)->bool:
	var handled: = false
	if pressed(event, "ui_left"):
		leftKeyDown = true
	elif pressed(event, "ui_right"):
		rightKeyDown = true
	elif pressed(event, "ui_up"):
		upKeyDown = true
	elif pressed(event, "ui_down"):
		downKeyDown = true
	elif justPressed(event, "ui_select"):
		useKeyDownTime = 0.0
		useHold = false
		useKeyDown = true
	elif justPressed(event, "cheats"):
		Level.stage.toggleCheats()
	elif released(event, "ui_left"):
		leftKeyDown = false
	elif released(event, "ui_right"):
		rightKeyDown = false
	elif released(event, "ui_up"):
		upKeyDown = false
	elif released(event, "ui_down"):
		downKeyDown = false
	elif released(event, "ui_select"):
		if useKeyDown:
			useKeyDown = false
			if not useHold and not GameWorld.paused:
				handled = keeper.useHit()
				useKeyDownTime = 0.0
	elif justPressed(event, "escape"):
		Level.stage.openPauseMenu()
		return true
	elif justPressed(event, "pause"):
		if GameWorld.paused:
			Level.stage.unpause(true)
		else:
			Level.stage.pause(true)
		return true
	
	keeperKeyEvent(event, handled)
	
	if justPressed(event, "keeper_gadget1"):
		for s in get_tree().get_nodes_in_group("special1"):
			var consumed = s.executeSpecial1()
			if consumed:
				break
	elif justPressed(event, "keeper_gadget2"):
		for s in get_tree().get_nodes_in_group("special2"):
			var consumed = s.executeSpecial2()
			if consumed:
				break
	elif justPressed(event, "cheats"):
		
		return false
	elif justPressed(event, "escape"):
		return false
	
	var md: = Vector2()
	if leftKeyDown:
		md.x -= 1
	if rightKeyDown:
		md.x += 1
	if upKeyDown:
		md.y -= 1
	if downKeyDown:
		md.y += 1

	if md.length() == 0:
		md += leftStickMove
	elif md.length() > 1.0:
		md = md.normalized()
	keeper.moveDirectionInput = md
	return md.length() > 0

func keeperKeyEvent(event, handled: bool):
	pass

func stick_move(event: InputEventJoypadMotion)->bool:
	match event.axis:
		0:
			if abs(event.axis_value) <= Options.gamepadStickDeadZone:
				leftStickMove.x = 0
			else:
				leftStickMove.x = (event.axis_value - (sign(event.axis_value) * Options.gamepadStickDeadZone)) * (1.0 / (1.0 - Options.gamepadStickDeadZone))
		1:
			if abs(event.axis_value) <= Options.gamepadStickDeadZone:
				leftStickMove.y = 0
			else:
				leftStickMove.y = (event.axis_value - (sign(event.axis_value) * Options.gamepadStickDeadZone)) * (1.0 / (1.0 - Options.gamepadStickDeadZone))
		_:
			return false

	processStickMove()

	return true

func processStickMove():
	if not (rightKeyDown or leftKeyDown or upKeyDown or downKeyDown):
		var md = Vector2(leftStickMove.x, leftStickMove.y)
		if md.length() > 1.0:
			md = md.normalized()

		keeper.moveDirectionInput = md
