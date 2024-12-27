extends "res://systems/input/InputProcessor.gd"

signal stopping
signal confirmed

var popup
var blockAllKeys: = false
var blockAllKeysIfGamepad: = false
var animated: = false
var animationTime: = 0.3
var blockStickMove: = false

var stopping: = false
var explicitName: = false
var canClose: = true
var tween: Tween
var focusControlOnLeaf

func _ready():
	if not explicitName:
		name = "PopupInput"
	if animated:
		tween = Tween.new()
		add_child(tween)
		popup.initAnimation()

func setName(n: String):
	explicitName = true
	name = n

func handleStart():
	if animated:
		popup.fadeIn(animationTime)
	var cb = popup.find_node("CancelButton")
	if cb:
		cb.connect("pressed", self, "cancel")

func becameLeaf():
	if focusControlOnLeaf:
		InputSystem.grabFocus(focusControlOnLeaf)

func cancel():
	desintegrate()

func handleStop():
	emit_signal("stopping")

func right_click(event)->bool:
	close()
	return true

func left_click(event)->bool:
	close()
	return false

func keyEvent(event)->bool:
	if canClose and (justPressed(event, "ui_cancel") or justPressed(event, "escape")):
		close()
		return true
	elif justPressed(event, "ui_select"):
		emit_signal("confirmed")
		return true
	return blockAllKeys or (blockAllKeysIfGamepad and GameWorld.useGamepad)

func close():
	if animated:
		if not stopping:
			stopping = true
			popup.fadeOut(animationTime)
			tween.interpolate_callback(self, animationTime, "desintegrate")
			tween.start()
	else:
		desintegrate()

func stick_move(event: InputEventJoypadMotion)->bool:
	return blockStickMove
