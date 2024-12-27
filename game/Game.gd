extends Node


export (CONST.BUILD_TYPE) var build: int = 1

export (bool) var devMode: = true
export (bool) var tracking: = true
export (bool) var resetBetweenRuns: = false
export (bool) var qaOptions: = false
export (bool) var unlockAllButton: = false
export (bool) var lockToSteam: = false
export (String) var version: = "."

export (int) var fixedWorld: = 0
export (String) var fixedPalette: = ""
export (String) var fixedMap: String
export (Resource) var fixedArchetype: Resource

export (String) var fixedLocale: String

var screenshotIndex = 0

func _ready():
	randomize()
	
	var f = File.new()
	if f.file_exists("user://dev-mode"):
		devMode = true
	
	if OS.has_feature("gog"):
		lockToSteam = false
	
	SteamGlobal.init(lockToSteam)
	
	Options.fixedLocale = fixedLocale
	GameWorld.devMode = devMode
	GameWorld.resetBetweenRuns = resetBetweenRuns
	GameWorld.buildType = build
	GameWorld.qaOptions = qaOptions
	GameWorld.unlockAllButton = unlockAllButton
	GameWorld.version = "v" + str(version)
	match build:
		CONST.BUILD_TYPE.DEMO:
			GameWorld.version += "d"
		CONST.BUILD_TYPE.PLAYTEST:
			GameWorld.version += "p"
		CONST.BUILD_TYPE.EXHIBITION:
			GameWorld.version += "e"
	GameWorld.init()
	GameWorld.handleVersionChange()

	var dir = Directory.new()
	dir.open("../screenshots")
	dir.list_dir_begin()
	while true:
		var file = dir.get_next()
		if file == "":
			break
		if not file.begins_with("."):
			screenshotIndex += 1
	
	Backend.enableTracking = tracking
	Backend.init()
	if Backend.playerId == "qa-debug":
		GameWorld.qaOptions = true
	Options.init()
	
	if devMode:

		print("RUNNING IN DEV MODE")
		var loadout = Loadout.new("dome2", "orchard", "keeper1", "relichunt")
		if fixedWorld:
			loadout.fixedWorld("world" + str(fixedWorld))
		if fixedPalette:
			loadout.fixedPalette(fixedPalette)
		if fixedMap and ResourceLoader.exists("res://content/map/data/TileData" + fixedMap + ".tscn"):
			loadout.fixedMap(fixedMap)
		elif fixedArchetype:
			loadout.fixedArchetype(fixedArchetype)
		GameWorld.lastPetId = "pet4"




		StageManager.startStage("stages/landing/landing", [loadout])

	else:
		if build == CONST.BUILD_TYPE.EXHIBITION:
			StageManager.startStage("stages/title/title")
		else:
			StageManager.startStage("stages/intro/intro")
			StageManager.queueStage("stages/title/title")

func _process(delta):
	if Input.is_action_just_pressed("screenshot"):
		var image = get_viewport().get_texture().get_data()
		image.flip_y()
		image.save_png("../screenshots/s_" + str(screenshotIndex) + ".png")
		screenshotIndex += 1
		
	if Input.is_action_just_pressed("toggle_dev_mode") and GameWorld.qaOptions:
		Audio.sound("alarm")
		GameWorld.devMode = not GameWorld.devMode
		GameWorld.devModeActivated = true
	
	if Input.is_action_just_pressed("switch_resolution"):
		if get_viewport().size == Vector2(1920, 1080):
			OS.window_size = Vector2(960, 540)
		elif get_viewport().size == Vector2(960, 540):
			OS.window_size = Vector2(480, 270)
		elif get_viewport().size == Vector2(480, 270):
			OS.max_window_size = Vector2(960, 1707)
			OS.window_size = Vector2(960, 1707)
		else:
			OS.max_window_size = Vector2(1920, 1080)
			OS.window_size = Vector2(1920, 1080)
		print("Set viewport size to " + str(OS.window_size))
