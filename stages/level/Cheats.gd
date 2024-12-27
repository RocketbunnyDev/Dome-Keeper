extends PanelContainer

func init():
	find_node("MonsterList").add_item("Walker")
	find_node("MonsterList").add_item("Walker")
	find_node("MonsterList").add_item("Flyer")
	find_node("MonsterList").add_item("Flyer")
	find_node("MonsterList").add_item("Driller")
	find_node("MonsterList").add_item("Driller")
	find_node("MonsterList").add_item("Diver")
	find_node("MonsterList").add_item("Diver")
	find_node("MonsterList").add_item("Tick")
	find_node("MonsterList").add_item("Tick")
	find_node("MonsterList").add_item("Worm")
	find_node("MonsterList").add_item("Worm")
	find_node("MonsterList").add_item("Bolter")
	find_node("MonsterList").add_item("Bolter")
	find_node("MonsterList").add_item("Mucker")
	find_node("MonsterList").add_item("Mucker")
	find_node("MonsterList").add_item("Shifter")
	find_node("MonsterList").add_item("Shifter")
	find_node("MonsterList").add_item("Big Tick")
	find_node("MonsterList").add_item("Big Tick")
	find_node("MonsterList").add_item("Butterfly")
	find_node("MonsterList").add_item("Butterfly")
	find_node("MonsterList").add_item("Beast")
	find_node("MonsterList").add_item("Beast")
	find_node("MonsterList").add_item("Rockman")
	find_node("MonsterList").add_item("Rockman")
	find_node("MonsterList").add_item("Stingray")
	find_node("MonsterList").add_item("Stingray")
	find_node("MonsterList").add_item("Stag")
	find_node("MonsterList").add_item("Stag")
	find_node("MonsterList").add_item("Scarab")
	
	var keys = Data.gadgets.keys()
	keys.sort()
	for g in keys:
		if not GameWorld.boughtUpgrades.has(g) and Data.gadgets[g].has("slot"):
			find_node("GadgetList").add_item(g)
	
	for c in find_node("PaletteContainer").get_children():
		c.connect("pressed", self, "setPalette", [int(c.name.substr("ButtonPalette".length()))])
	for c in find_node("WorldContainer").get_children():
		c.connect("pressed", self, "setWorld", [int(c.name.substr("ButtonWorld".length()))])
	
	Data.listen(self, "dome.health")
	Data.listen(self, "monsters.wavepresent")
	
	find_node("EnableCheatDetectionButton").pressed = GameWorld.runCheatDetection
	
	updatePaletteButtons()

func _process(delta):
	if not visible:
		return 
	
	find_node("WaveCountDown").text = "%.0fs" % Data.of("monsters.waveCooldown")
	find_node("WaveIndex").text = str(Data.of("monsters.cycle"))
	find_node("WaveModDeltaLabel").text = str(Level.monsters.lastWaveStrengthModChange)
	find_node("WaveDamageLabel").text = "%.0fs" % Level.monsters.waveDamageCounter
	find_node("WaveModLabel").text = str(GameWorld.waveStrengthModifier)
	if Level.monsters.currentWave:
		var w = Level.monsters.currentWave.getWeight()
		if w != - 1.0:
			find_node("LastWaveLabel").text = str(w)
	if Level.map:
		find_node("WaveIntervalLabel").text = "%.1f" % (100.0 * Level.map.getProgress()) + "%"
		find_node("WaveIntervalLabel").text = "%.1f" % (100 * Level.map.getProgress()) + "%"
	if Level.mode:
		find_node("RunWeightLabel").text = "%.0f" % Level.mode.getRunWeight()
	find_node("CycleLengthLabel").text = "%.0fs" % (GameWorld.getTimeBetweenWaves())
	find_node("FPSLabel").text = "%d" % Engine.get_frames_per_second()
	find_node("SpeedLabel").text = "%.0f" % Level.keeper.move.length()
	
	var coord = Level.map.getTileCoord(Level.keeper.global_position)
	find_node("DepthLabel").text = str(coord.x) + ":" + str(coord.y)
	find_node("LayerLabel").text = str(Level.map.getLayerOfCoord(coord))
	find_node("BiomeLabel").text = str(Level.map.getBiomeOfCoord(coord))
	
	if Level.world:
		var w = Level.world.find_node("WeatherSystem")
		if w:
			var enable = find_node("WeatherEnabledButton").pressed
			w.enabled = enable
			if not enable:
				w.clear_current_weather()

func propertyChanged(property: String, oldValue, newValue):
	match property:
		"dome.health":
			find_node("DomeHealthLabel").text = "%.0f" % newValue
		"monsters.wavepresent":
			if newValue:
				find_node("LastWaveGoal").text = str(Level.mode.getRunWeight() * GameWorld.waveStrengthModifier)

func _on_AddIronButton_pressed():
	Data.changeByInt("inventory." + CONST.IRON, 30)

func _on_AddWaterButton_pressed():
	Data.changeByInt("inventory." + CONST.WATER, 10)

func _on_AddSandButton_pressed():
	Data.changeByInt("inventory." + CONST.SAND, 10)

func buyUpgrade(s: String):
	var prev = Data.getInventory("iron")
	GameWorld.buyUpgrade(s)
	Data.changeByInt("inventory.iron", prev - Data.getInventory("iron"))

func _on_ButtonHud_pressed():
	buyUpgrade("DomeWaveMeter".to_lower())
	buyUpgrade("DomeWaveCount".to_lower())
	buyUpgrade("DomeResourceCounters".to_lower())
	buyUpgrade("domeHealthMeter".to_lower())

func _on_ButtonDrill_pressed():
	buyUpgrade("drill4".to_lower())

func _on_ButtonMove_pressed():
	buyUpgrade("jetpackSpeed4".to_lower())
	buyUpgrade("jetpackStrength4".to_lower())

func _on_ButtonDome_pressed():
	buyUpgrade("laserStrength2".to_lower())
	buyUpgrade("laserMove1".to_lower())

func _on_ButtonAll_pressed():
	_on_ButtonHud_pressed()
	_on_ButtonDrill_pressed()
	_on_ButtonMove_pressed()
	_on_ButtonDome_pressed()

func _on_CloseButton_pressed():
	visible = false

func _on_NextWaveButton_pressed():
	Level.monsters.disabled = false
	Data.apply("monsters.waveCooldown", 0)

func _on_ButtonGameSpeed_pressed(speed):
	Engine.time_scale = speed

func _on_SkipWaveButton_pressed():
	Data.changeByInt("monsters.cycle", 1)

func _on_KillWaveButton_pressed():
	for m in get_tree().get_nodes_in_group("monster"):
		m.emit_signal("died")
		m.queue_free()

func _on_WinButton_pressed():
	pass

func _on_LoseButton_pressed():
	pass

func _on_ButtonCam1x_pressed():
	Data.apply("keeper.zoominmine", 6)
	GameWorld.goalCameraZoom = 6

func _on_ButtonCam5px_pressed()->void :
	Data.apply("keeper.zoominmine", 5)
	GameWorld.goalCameraZoom = 5

func _on_ButtonCam4px_pressed()->void :
	Data.apply("keeper.zoominmine", 4)
	GameWorld.goalCameraZoom = 4

func _on_ButtonCam3x_pressed():
	Data.apply("keeper.zoominmine", 3)
	GameWorld.goalCameraZoom = 3

func _on_ButtonCam4x_pressed():
	Data.apply("keeper.zoominmine", 2)
	GameWorld.goalCameraZoom = 2

func _on_ButtonCam6x_pressed():
	Data.apply("keeper.zoominmine", 1.5)
	GameWorld.goalCameraZoom = 1

func _on_ButtonCam266x_pressed():
	GameWorld.goalCameraZoom = 1920.0 / 720.0

func _on_DisableWavesButton_pressed():
	Level.monsters.disabled = find_node("DisableWavesButton").pressed

func _on_0HealthButton_pressed():
	Data.changeDomeHealth( - Data.of("dome.health"))

func _on_1HealthButton_pressed():
	Data.changeDomeHealth(Data.of("dome.maxHealth") * 0.01 - Data.of("dome.health"))

func _on_50HealthButton_pressed():
	Data.changeDomeHealth(Data.of("dome.maxHealth") * 0.5 - Data.of("dome.health"))

func _on_100HealthButton_pressed():
	Data.changeDomeHealth(Data.of("dome.maxHealth") * 1.0 - Data.of("dome.health"))

func _on_GadgetList_item_selected(index):
	var il: ItemList = find_node("GadgetList")
	var text = il.get_item_text(index)
	Level.stage.applyGadget(text)
	find_node("GadgetList").remove_item(index)

func _on_MonsterList_item_selected(index):
	match index:
		0:
			Level.monsters.spawnMonster("walker", "left")
		1:
			Level.monsters.spawnMonster("walker", "right")
		2:
			Level.monsters.spawnMonster("flyer", "left")
		3:
			Level.monsters.spawnMonster("flyer", "right")
		4:
			Level.monsters.spawnMonster("driller", "left")
		5:
			Level.monsters.spawnMonster("driller", "right")
		6:
			Level.monsters.spawnMonster("diver", "left")
		7:
			Level.monsters.spawnMonster("diver", "right")
		8:
			Level.monsters.spawnMonster("tick", "left")
		9:
			Level.monsters.spawnMonster("tick", "right")
		10:
			Level.monsters.spawnMonster("worm", "left")
		11:
			Level.monsters.spawnMonster("worm", "right")
		12:
			Level.monsters.spawnMonster("bolter", "left")
		13:
			Level.monsters.spawnMonster("bolter", "right")
		14:
			Level.monsters.spawnMonster("mucker", "left")
		15:
			Level.monsters.spawnMonster("mucker", "right")
		16:
			Level.monsters.spawnMonster("shifter", "left")
		17:
			Level.monsters.spawnMonster("shifter", "right")
		18:
			Level.monsters.spawnMonster("bigtick", "left")
		19:
			Level.monsters.spawnMonster("bigtick", "right")
		20:
			Level.monsters.spawnMonster("butterfly", "left_high")
		21:
			Level.monsters.spawnMonster("butterfly", "right_high")
		22:
			Level.monsters.spawnMonster("beast", "left")
		23:
			Level.monsters.spawnMonster("beast", "right")
		24:
			Level.monsters.spawnMonster("rockman", "left")
		25:
			Level.monsters.spawnMonster("rockman", "right")
		26:
			Level.monsters.spawnMonster("stingray", "left")
		27:
			Level.monsters.spawnMonster("stingray", "right")
		28:
			Level.monsters.spawnMonster("stag", "left")
		29:
			Level.monsters.spawnMonster("stag", "right")
		30:
			Level.monsters.spawnMonster("scarab", "center")

func _on_AddArtifact1Button_pressed():
	Level.stage.startGadgetChoiceInput()

func _on_UnlockAllGadgetsButton_pressed()->void :
	for g in ["drillbot", "repellent", "stunLaser", "orchard", "probe", "blastMining", "shield", "condenser", "lift", "prospectionMeter"]:
		Level.stage.applyGadget(g.to_lower())

func _on_LockHealthButton_pressed()->void :
	GameWorld.domeHealthLocked = find_node("LockHealthButton").pressed

func _on_RevealAllTilesButton_pressed():
	var map = Level.map.get_node("TileData")
	for c in map.get_node("Biomes").get_used_cells():
		Level.map.revealTile(c)

func _on_Clear1TilesButton_pressed():
	var t: = []
	for x in range( - 100, 100):
		for y in range(0, 200):
			t.append(Vector2(x, y))
	Level.map.freeTiles(t)

func _on_Clear10TilesButton_pressed():
	var t: = []
	for x in range( - 5, 5):
		for y in range(0, 10):
			t.append(Vector2(x, y))
	while Level.map.freeTiles(t) > 0:
		yield (get_tree().create_timer(0.2), "timeout")
	
func _on_Clear20TilesButton_pressed():
	var t: = []
	for x in range( - 10, 10):
		for y in range(0, 20):
			t.append(Vector2(x, y))
	while Level.map.freeTiles(t) > 0:
		yield (get_tree().create_timer(0.2), "timeout")

func _on_Load0Button_pressed():
	
	GameWorld.loadGame(0)

func _on_Save1Button_pressed():
	GameWorld.saveGame(1)

func _on_Load1Button_pressed():
	GameWorld.loadGame(1)

func _on_Save2Button_pressed():
	GameWorld.saveGame(2)

func _on_Load2Button_pressed():
	GameWorld.loadGame(2)

func _on_Save3Button_pressed():
	GameWorld.saveGame(3)
func _on_Load3Button_pressed():
	GameWorld.loadGame(3)

var i
func _on_ButtonCameraController_pressed():
	var cam = InputSystem.getCamera()
	if find_node("ButtonCameraController").pressed:
		cam.set_script(preload("res://systems/camera/ManualCamera.gd"))
		i = preload("res://systems/camera/ManualCameraInputProcessor.gd").new()
		i.connect("onStop", self, "set", ["i", null])
		cam.init()
		i.cam = cam
		i.integrate(Level.stage)
	else:
		i.desintegrate()
		cam.set_script(preload("res://systems/camera/CameraSingleTarget.gd"))
		cam.init(Level.keeper)
	cam.set_process(true)

var oldVals: = {}
func _on_ButtonTempDigging_pressed():
	if find_node("ButtonTempDigging").pressed:
		match Level.keeperId():
			"keeper1":
				oldVals["keeper1.drillStrength"] = Data.of("keeper1.drillStrength")
				oldVals["keeper1.maxSpeed"] = Data.of("keeper1.maxSpeed")
				oldVals["keeper1.speedLossPerCarry"] = Data.of("keeper1.speedLossPerCarry")
				oldVals["keeper1.tileKnockback"] = Data.of("keeper1.tileKnockback")
				oldVals["keeper1.slowdownRecovery"] = Data.of("keeper1.slowdownRecovery")
				Data.apply("keeper1.drillStrength", 1000)
				Data.apply("keeper1.maxSpeed", 100)
				Data.apply("keeper1.speedLossPerCarry", 0.01)
				Data.apply("keeper1.tileKnockback", 2)
				Data.apply("keeper1.slowdownRecovery", 10)
			"keeper2":
				oldVals["keeper2.maxSpeed"] = Data.of("keeper2.maxSpeed")
				oldVals["keeper2.acceleration"] = Data.of("keeper2.acceleration")
				oldVals["keeper2.totalspheres"] = Data.of("keeper2.totalspheres")
				oldVals["keeper2.spherereload"] = Data.of("keeper2.spherereload")
				oldVals["keeper2.spherebasedamage"] = Data.of("keeper2.spherebasedamage")
				oldVals["keeper2.spherebaselifetime"] = Data.of("keeper2.spherebaselifetime")
				oldVals["keeper2.spherefractiondamage"] = Data.of("keeper2.spherefractiondamage")
				oldVals["keeper2.directminingdamage"] = Data.of("keeper2.directminingdamage")
				Data.apply("keeper2.maxSpeed", 200)
				Data.apply("keeper2.acceleration", 80)
				Data.apply("keeper2.totalspheres", 4)
				Data.apply("keeper2.spherereload", 4)
				Data.apply("keeper2.spherebasedamage", 10)
				Data.apply("keeper2.directminingdamage", 100)
				Data.apply("keeper2.spherebaselifetime", 10)
				Data.apply("keeper2.spherefractiondamage", 0.5)
	else:
		for k in oldVals:
			Data.apply(k, oldVals[k])
		oldVals.clear()

func _on_VegetateButton_pressed():
	Level.map.border_deco.runDecoration()

func _on_VegetationSlider_value_changed(value):
	for d in get_tree().get_nodes_in_group("decoration"):
		d.visible = randf() < value

func _on_RunWeightLowerButton_pressed():
	GameWorld.additionalRunWeight -= 50

func _on_RunWeightRaiseButton_pressed():
	GameWorld.additionalRunWeight += 50

func _on_StartFinaleButton_pressed():
	Data.changeByInt("inventory.relic", 1)

func _on_ButtonVignette_pressed():
	Level.stage.find_node("Vignette").visible = find_node("ButtonVignette").pressed

func _on_LightningButton_pressed():
	setWeather(0)

func _on_FogButton_pressed():
	setWeather(1)

func _on_RainButton_pressed():
	setWeather(2)

func _on_StormButton_pressed():
	setWeather(3)

func _on_SnowButton_pressed():
	setWeather(4)

func _on_MeteorButton_pressed():
	setWeather(5)

func _on_SporesButton_pressed():
	setWeather(6)

func setWeather(i):
	var w = Level.world.find_node("WeatherSystem")
	if w:
		w.enabled = true
		w.set_weather(i)

func _on_SpawnResourceSlider_value_changed(value):
	find_node("SpawnIronButton").text = "spawn " + str(value) + " iron"
	find_node("SpawnWaterButton").text = "spawn " + str(value) + " water"
	find_node("SpawnSandButton").text = "spawn " + str(value) + " cobalt"

func _on_SpawnIronButton_pressed():
	spawnResource(CONST.IRON)

func _on_SpawnWaterButton_pressed():
	spawnResource(CONST.WATER)

func _on_SpawnSandButton_pressed():
	spawnResource(CONST.SAND)

func spawnResource(type: String, amount: = - 1):
	if amount == - 1:
		amount = find_node("SpawnResourceSlider").value
	for _i in range(0, amount):
		var drop = Data.DROP_SCENES.get(type).instance()
		drop.position = Level.keeper.global_position
		drop.apply_central_impulse(Vector2(0, 40).rotated(randf() * TAU))
		Level.map.call_deferred("addDrop", drop)

func _on_SpawnGadget_pressed():
	spawnResource(CONST.GADGET, 1)

func _on_SpawnRelic_pressed():
	spawnResource(CONST.RELIC, 1)

func _on_SpawnSeed_pressed():
	spawnResource(CONST.SEED, 1)

func _on_SpawnDrone_pressed():
	var d = preload("res://content/gadgets/transportdrone/TransportDrone.tscn").instance()
	Level.map.add_child(d)

func _on_SpawnEgg_pressed():
	spawnResource(CONST.EGG, 1)

func _on_SpawnTreat_pressed():
	spawnResource(CONST.TREAT, 1)

func _on_PrestigeScoreButton_pressed():
	Data.changeByInt("prestige.score", 10000)

func setWorld(i: int):
	var w = load("res://content/worlds/world" + str(i) + "/World" + str(i) + ".tscn").instance()
	w.showSimpson = false
	Level.world.get_parent().add_child(w)
	Level.world.queue_free()
	Level.world = w
	w.worldIndex = i
	updatePaletteButtons()
	setPalette(1)

func setPalette(i: int):
	Style.setPalette(str(Level.world.worldIndex) + "_" + str(Level.world.allowedPalettes[i - 1]))

func updatePaletteButtons():
	for b in find_node("PaletteContainer").get_children():
		b.disabled = true
	var i: = 0
	for p in Level.world.allowedPalettes:
		find_node("PaletteContainer").get_child(i).disabled = false
		i += 1

func _on_WaveAmbienceButton_pressed():
	GameWorld.forceBattleAmbienceEnabled = find_node("WaveAmbienceButton").pressed

func _on_UnlockAllButton_pressed():
	for a in ["dome2", "keeper2", "orchard", "orchard-battle2", "repellent", "repellent-battle2", "repellent-battle3", "shield-battle2", "shield-battle3", "prestige", CONST.MODE_PRESTIGE_COBALT, CONST.MODE_PRESTIGE_COUNTDOWN, "world2", "world3", "world4", "world5", CONST.MAP_MEDIUM, CONST.MAP_LARGE, CONST.MAP_HUGE]:
		GameWorld.unlockElement(a)

func _on_DeleteLocalSave_pressed():
	GameWorld.deleteLocalSave()

func _on_ResetAchievementsButton_pressed():
	SteamGlobal.Steam.resetAllStats(true)

func _on_RelicBombButton_pressed():
	yield (get_tree().create_timer(2.0), "timeout")
	var bomb = load("res://content/gadgets/cobaltbomb/CobaltBomb.tscn").instance()
	Level.stage.add_child(bomb)

func _on_LeavePlanetButton_pressed():
	Level.stage.leavePlanet()

func _on_ShowTileData_pressed():
	Level.map.toggleTileDataVisibility()

func _on_OrphanButton_pressed():
	print_stray_nodes()


func _on_SwitchViewportModeButton_toggled(button_pressed):
	Level.map.switchMapViewportMode(button_pressed)
	find_node("SwitchViewportModeButton").text = "Full viewport" if button_pressed else "Perf. viewport"

func _on_SaveMapButton_pressed():
	ResourceSaver.save("res://content/map/data/TileDataLast.tscn", Level.map.tileData().pack())

func _on_SpawnEyesButton_pressed():
	Level.map.find_node("Critters").spawnEyes(true)

func _on_SpawnWormButton_pressed():
	Level.map.find_node("Critters").spawnWorm(true)

func _on_SpawnRatButton_pressed():
	Level.map.find_node("Critters").spawnRat(true)

func _on_SpawnRoachButton_pressed():
	Level.map.find_node("Critters").spawnRoach(true)

func _on_ButtonViewRange1_pressed():
	Data.apply("map.revealdistance", 1)

func _on_ButtonViewRange2_pressed():
	Data.apply("map.revealdistance", 2)

func _on_EnableCheatDetectionButton_pressed():
	GameWorld.runCheatDetection = find_node("EnableCheatDetectionButton").pressed
