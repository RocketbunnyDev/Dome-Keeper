extends Node

signal onStart
signal onStop

class_name InputProcessor

var parent: InputProcessor
var child: InputProcessor

var stopNamed: String
var desiredParent: String
var attachedChildren: = true

var doTransitiveStop: = true
var desintegrating: = false
var dragging: = false
var rightDown: = false
var dragStart

func integrate(parentNode):
	var s = get_script()
	var start = s.resource_path.find_last("/") + 1
	name = s.resource_path.substr(start, s.resource_path.length() - start - 3)
	parentNode.add_child(self)
	InputSystem.addProcessor(self)
	
	if parentNode is Stage:
		parentNode.inputs.append(self)
	else:
		print("Warning: Input Processor " + self.name + " added to parent " + parentNode.name + " which is not a stage.")

func desintegrate():
	if name != "RootProcessor":
		InputSystem.removeProcessor(self)
		desintegrating = true

func handleStart():
	pass

func handleStop():
	pass

func becameLeaf():
	pass

func notLeaf():
	pass

func resume():
	pass

func canStop()->bool:
	return true

func handle(event)->bool:
	if desintegrating:
		return false
	
	if event is InputEventMouseButton:
		if Options.useGamepad:
			Options.setUseGamepad(false)
		if event.button_index == BUTTON_LEFT:
			if event.is_pressed():
				if left_click(event): return true
			else:
				if left_click_released(event): return true
		elif event.button_index == BUTTON_WHEEL_UP:
				if wheel_up(event): return true
		elif event.button_index == BUTTON_WHEEL_DOWN:
				if wheel_down(event): return true
		elif event.button_index == BUTTON_RIGHT:
			if event.is_pressed():
				rightDown = true
				
				return true
			else:
				rightDown = false
				if not dragging or event.position.distance_to(dragStart) < 5:
					return right_click(event)
				dragging = false
				return true
	elif event is InputEventMouseMotion:
		if rightDown and not dragging:
			dragging = true
			dragStart = event.position
			return drag_right(event)
		elif rightDown and dragging:
			return drag_right(event)
		else:
			return mouse_move(event)
	elif event is InputEventKey:
		if Options.useGamepad:
			Options.setUseGamepad(false)
		return keyEvent(event)
	elif event is InputEventJoypadButton:
		if not Options.useGamepad:
			Options.setUseGamepad(true, event.device)
		return keyEvent(event)
	elif event is InputEventJoypadMotion:
		if not Options.useGamepad and abs(event.axis_value) >= Options.gamepadStickDeadZone:
			Options.setUseGamepad(true, event.device)
		return stick_move(event)
		
	return false

func right_click(event: InputEventMouseButton)->bool:
	return false

func left_click(event: InputEventMouseButton)->bool:
	return false

func left_click_released(event: InputEventMouseButton)->bool:
	return false

func wheel_up(event: InputEventMouseButton)->bool:
	return false

func wheel_down(event: InputEventMouseButton)->bool:
	return false

func mouse_move(event: InputEventMouseMotion)->bool:
	return false

func stick_move(event: InputEventJoypadMotion)->bool:
	return false

func drag_right(event: InputEventMouseMotion)->bool:
	if parent:
		return parent.drag_right(event)
	return false

func keyEvent(event)->bool:
	return false

func pressed(event, actionName: String)->bool:
	return InputMap.event_is_action(event, actionName) and event.pressed

func released(event, actionName: String)->bool:
	return InputMap.event_is_action(event, actionName) and not event.pressed

func justPressed(event, actionName: String)->bool:
	var echoes: = false
	if event is InputEventKey:
		echoes = event.echo
	return not echoes and InputMap.event_is_action(event, actionName) and event.pressed
