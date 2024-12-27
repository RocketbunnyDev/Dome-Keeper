extends Node

class_name Stage

signal request_end
signal ended


var camera setget set_camera, get_camera
var initData: Array

var fadeInTime: = 0.2
var fadeOutTime: = 0.2
var stageId: = ""


var resuming: bool
var paused: bool = false

var inputs = []

func build(data: Array):
	pass

func beforeReady():
	pass

func beforeStart():
	pass

func start():
	pass

func beforeEnd():
	pass

func end():
	pass

func set_camera(value):
	camera = value

func get_camera():
	return camera

func getPauseScreenInfo():
	return null

func pause():
	_pauseNode(self, false)

func _pauseNode(node, process):
	if paused == process:
		paused = not process
		node.set_process(process)
		node.set_physics_process(process)
		node.set_process_input(process)
		node.set_process_unhandled_input(process)
		node.set_process_unhandled_key_input(process)
	
	for child in node.get_children():
		_pauseNode(child, process)

func unpause():
	_pauseNode(self, true)

func getContext()->String:
	return name
