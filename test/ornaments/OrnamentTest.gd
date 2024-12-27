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
	
	Data.unlockGadget("keeper1")
	Data.unlockGadget("dome1")
	Data.apply("keeper1.maxSpeed", 100)
	Data.apply("keeper1.drillstrength", 100)
	Data.apply("keeper1.tileKnockback", 2)
	Data.apply("keeper1.slowdownRecovery", 10)
	Options.loadOptions()
	GameWorld.goalCameraZoom = 4
	
	$Map.setTileData($TileData)
	$Map.init()
	


	
	find_node("Hud").init()
	GameWorld.levelInitialized()
	$Map.revealInitialState()
	
	startKeeperInput()
	Data.apply("keeper.insidedome", false)
	
	for _i in range(20):
		var o = preload("res://content/map/decorations/ornaments/FollowEye.tscn")
		$Map.addChamber(Vector2( - 6 + randi() % 14, - 6 + randi() % 14), o)

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
