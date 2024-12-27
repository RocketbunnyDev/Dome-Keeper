extends Stage

func _ready():
	Style.setPalette("1_1")
	GameWorld.goalCameraZoom = 4
	GameWorld.prepareCleanData()
	Level.map = $Map
	Level.monsters = $Monsters
	Level.keeper = $Keeper
	Level.dome = $Dome
	Level.hud = find_node("Hud")
	Level.stage = self
	Level.initialized = true
	$Camera2D.init($Keeper)
	GameWorld.goalCameraZoom = 4
	
	Data.unlockGadget("keeper1")
	Data.unlockGadget("dome1")
	Data.apply("keeper1.maxSpeed", 100)
	Options.loadOptions()
	
	$Map.setTileData($TileData)
	$Map.init()
	GameWorld.isHalloween = true
	var caves: = [
		preload("res://content/caves/teleportcave/TeleportCave.tscn").instance(), 
		preload("res://content/caves/mushroomcave/MushroomCave.tscn").instance(), 
		preload("res://content/caves/bombcave/BombCave.tscn").instance(), 
		preload("res://content/caves/helmetextensioncave/HelmetCave.tscn").instance(), 
		preload("res://content/caves/seedcave/SeedCave.tscn").instance(), 
		preload("res://content/caves/dronecave/DroneCave.tscn").instance(), 
		preload("res://content/caves/scannercave/ScannerCave.tscn").instance(), 
		preload("res://content/caves/cobaltcave/CobaltCave.tscn").instance(), 
		preload("res://content/caves/halloweencave/HalloweenSkeletonCave.tscn").instance(), 
		preload("res://content/map/chamber/nest/NestCave.tscn").instance()
	]
	for layerIndex in 20:
		prints("layer", layerIndex)
		for cave in caves:
			var biomeFits = cave.biome == "" or $Map.biomes[layerIndex] == cave.biome
			var minLayerFits = cave.minLayer <= layerIndex
			var relativeDepth = layerIndex / float(20)
			var minDepthFits = round(relativeDepth * cave.minRelativeDepth) <= layerIndex
			var maxDepthFits = layerIndex <= round(cave.maxRelativeDepth * 20)
			prints(cave.name, biomeFits, minLayerFits, minDepthFits, maxDepthFits)
			if biomeFits and minLayerFits and minDepthFits and maxDepthFits:
				$Map.addCave(cave, layerIndex, 0)
				caves.erase(cave)
				break
	
	for c in $TileData.get_resource_cells_by_id(10):
		$TileData.set_resourcev(c, - 1)
	
	find_node("Hud").init()
	GameWorld.levelInitialized()
	$Map.revealInitialState()
	
	startKeeperInput()
	Data.apply("keeper.insidedome", false)

func startKeeperInput():
	var keeperInputProcessor = preload("res://content/keeper/Keeper1InputProcessor.gd").new()
	keeperInputProcessor.keeper = Level.keeper
	keeperInputProcessor.integrate(self)

func startEffect(s, t):
	pass

func openPauseMenu():
	GameWorld.setShowMouse(true)
	var i = preload("res://content/pause/PauseInputProcessor.gd").new()
	i.blockAllKeys = true
	i.popup = preload("res://content/pause/PauseMenu.tscn").instance()
	add_child(i.popup)
	i.integrate(self)
	i.connect("stopping", i.popup, "fadeOut", [0.3])
	i.connect("onStop", self, "pauseClosed")
	i.popup.connect("close", i, "desintegrate")
	pause()

func pauseClosed():
	GameWorld.setShowMouse(false)
	unpause()

func unpause():
	GameWorld.unpause()
	get_tree().call_group("monster", "unpause")
	
func pause():
	GameWorld.pause()
	get_tree().call_group("monster", "pause")

func toggleCheats():
	var c = find_node("Cheats")
	c.visible = not c.visible
	if c.visible:
		Audio.sound("gui_cheats")
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		GameWorld.setShowMouse(true)
	else:
		Audio.sound("gui_cheats")
		if not GameWorld.showMouse:
			Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
