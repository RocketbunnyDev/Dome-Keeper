extends Node

export (bool) var devMode: = false
export (bool) var tracking: = true
export (bool) var demo: = true
export (bool) var resetBetweenRuns: = false
export (String) var version: = "."

var screenshotIndex = 0
var firing = false
var direction = 1
var timer = 3.0

func _ready():
	randomize()
	GameWorld.devMode = true
	GameWorld.resetBetweenRuns = resetBetweenRuns
	GameWorld.version = "v" + str(version)
	
	Options.init()
	
	StageManager.startStage("stages/level/level", ["dome1", "orchard", "keeper1", "migration"])

	GameWorld.buyUpgrade("laserMove2")
	GameWorld.buyUpgrade("laserStrength2")
	GameWorld.buyUpgrade("laserAimLine")
	Data.apply("laser.variant", 0)
	GameWorld.goalCameraZoom = 2
	
	
	var ev: InputEventKey
	ev = InputEventKey.new()
	ev.scancode = KEY_1
	InputMap.add_action("test_laser1")
	InputMap.action_add_event("test_laser1", ev)
	ev = InputEventKey.new()
	ev.scancode = KEY_2
	InputMap.add_action("test_laser2")
	InputMap.action_add_event("test_laser2", ev)
	ev = InputEventKey.new()
	ev.scancode = KEY_3
	InputMap.add_action("test_laser3")
	InputMap.action_add_event("test_laser3", ev)
	ev = InputEventKey.new()
	ev.scancode = KEY_4
	InputMap.add_action("test_laser4")
	InputMap.action_add_event("test_laser4", ev)


func _input(event):
	
	var weapon = get_tree().get_nodes_in_group("primaryWeapon")
	if event is InputEventKey:
		event = event as InputEventKey
		if event.is_action_pressed("test_laser1"):
			Data.apply("laser.variant", 0)
			weapon[0].firing = false
		if event.is_action_pressed("test_laser2"):
			Data.apply("laser.variant", 1)
			weapon[0].firing = false
		if event.is_action_pressed("test_laser3"):
			Data.apply("laser.variant", 2)
			weapon[0].firing = false
		if event.is_action_pressed("test_laser4"):
			Data.apply("laser.variant", 3)
			weapon[0].firing = false















func fire(variant):
	Data.apply("laser.variant", variant)
	firing = true
	
func stop():
	firing = false
	
