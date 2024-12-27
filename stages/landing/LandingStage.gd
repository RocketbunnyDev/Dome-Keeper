extends Stage

var cam_offset = Vector2.ZERO
var shake = false
var levelData

onready var sky = find_node("sky")
onready var streaks = find_node("streaks")
onready var falling = find_node("falling")
onready var cam = find_node("Camera2D")
onready var anim = find_node("AnimationPlayer")

var loadout: Loadout
var thread: Thread
var generationFinished: = false
var ending: = false
var timePassed: = 0.0

func build(data: Array):
	self.loadout = data[0]
	GameWorld.startLevel(loadout)
	
	if loadout.mapId:
		loadout.tileData = load("res://content/map/data/TileData" + loadout.mapId + ".tscn").instance()

func beforeStart():
	Style.setPalette(loadout.palette)
	Style.init(sky)
	Style.init(streaks)
	Style.init(falling)
	find_node("ContinueLabel").modulate.a = 0.0
	fadeOutTime = 0.1
	Audio.stopMusic(0.0)
	
	if loadout.savegame:
		loadout.tileData = preload("res://content/map/TileData.tscn").instance()
		generationFinished = true
		loadout.generatedMap = false
		end()
	else:
		
		GameWorld.goalCameraZoom = 2

func beforeEnd():
	find_node("FallingSound").stop()

func generateThreaded(a):
	var generator = preload("res://content/map/generation/TileDataGenerator.tscn").instance()
	generator.init(loadout.mapArchetype)
	generator.generate()
	return generator

func _physics_process(delta):
	if shake:
		streaks.region_rect.position.y += 3000 * delta
		
	if shake and Engine.get_frames_drawn() % 5 == 0:
		cam_offset = Vector2(rand_range( - 20, 20), rand_range( - 20, 20))
		streaks.region_rect.position.x = randi() % 1000
		streaks.scale.x = randi() % 3 + 1
		
	var lerp_offset = lerp(cam.offset, cam_offset, 0.1)
	cam.offset = lerp_offset

func _process(delta):
	timePassed += delta
	if loadout.tileData:
		if GameWorld.devMode:
			Data.apply("keeper.zoominmine", 4)
			end()
		if timePassed > 1.0 and not generationFinished:
			generationFinished = true
			$Tween.interpolate_property(find_node("ContinueLabel"), "modulate:a", 0.0, 1.0, 1.0, Tween.TRANS_QUAD, Tween.EASE_IN)
			$Tween.start()
	else:
		if timePassed > 0.1 and not thread:
			startGenerationThread()
	
	if thread and not thread.is_alive() and not generationFinished:
		var generator = thread.wait_to_finish()
		if not generator or not generator.finishedSuccessful:
			Logger.error("Map generation failed, map is empty. Trying again.")
			generator.queue_free()
			startGenerationThread()
			return 
		
		var tileData = generator.popTileData()
		if tileData.get_tile_count() < 300:
			Logger.error("Map generation failed, map is too small. Trying again.")
			generator.queue_free()
			startGenerationThread()
			return 
		
		loadout.tileData = tileData
		generationFinished = true
		Logger.info("procedural generation finished")
		$Tween.interpolate_property(find_node("ContinueLabel"), "modulate:a", 0.0, 1.0, 1.0, Tween.TRANS_QUAD, Tween.EASE_IN)
		$Tween.start()
		
		if GameWorld.devMode:
			end()
		
	if not anim.is_playing() and generationFinished:
		end()

func startGenerationThread():
	thread = Thread.new()
	
	var status: int = thread.start(self, "generateThreaded")
	if status != 0:
		Logger.error("Failed to start thread for generating map. Will do it synchroneously.", "LandingStage.beforeStart", status)
		var generator = preload("res://content/map/generation/TileDataGenerator.tscn").instance()
		generator.generate()

func _input(event):
	if event is InputEventMouseButton or event is InputEventKey or event is InputEventJoypadButton:
		end()
	
func start():
	find_node("FallingSound").play()
	
func start_shaking():
	shake = true

func end():
	if generationFinished and not ending:
		
		ending = true
		
		if loadout.generatedMap and GameWorld.devMode:
			ResourceSaver.save("res://content/map/data/TileDataLast.tscn", loadout.tileData.pack())
		StageManager.startStage("stages/level/level", [loadout])
		set_process(false)
