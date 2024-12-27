extends Node2D

var world
var dome
var keeper
var lastModifiedPalette: = 0.0
var paletteIndex

func _ready():
	Style.FOCUS_MODULATE.r = 1.0
	Style.FOCUS_MODULATE.g = 1.0
	Style.FOCUS_MODULATE.b = 1.0
	
	var dir = Directory.new()
	dir.open("res://content/worlds/")
	dir.list_dir_begin()
	while true:
		var file = dir.get_next()
		if file == "":
			break
		if not file.begins_with(".") and dir.current_is_dir() and file.to_lower().begins_with("world"):
			find_node("WorldsList").add_item(file)
	
	dir.open("res://content/dome/")
	dir.list_dir_begin()
	while true:
		var file = dir.get_next()
		if file == "":
			break
		if not file.begins_with(".") and dir.current_is_dir() and file.to_lower().begins_with("dome"):
			find_node("DomesList").add_item(file)
	
	dir.open("res://content/gadgets/")
	dir.list_dir_begin()
	while true:
		var file = dir.get_next()
		if file == "":
			break
		if not file.begins_with(".") and dir.current_is_dir():
			find_node("GadgetsList").add_item(file)
	
	dir.open("res://content/keeper/")
	dir.list_dir_begin()
	while true:
		var file = dir.get_next()
		if file == "":
			break
		if not file.begins_with(".") and dir.current_is_dir() and file.to_lower().begins_with("keeper"):
			find_node("KeepersList").add_item(file)
	
	dir.open("res://systems/style/palettes/")
	dir.list_dir_begin()
	while true:
		var file = dir.get_next()
		if file == "":
			break
		if file.to_lower().begins_with("palette_") and file.to_lower().ends_with(".png"):
			find_node("PaletteList").add_item(file.substr(0, file.find(".")))
	
	GameWorld.prepareCleanData()
	Level.map = $Map
	Style.init($CanvasLayer)
	Style.init($Monsters)
	Style.init($Underground)
	Style.setPalette("1_1")
	
	var tileData = load("res://tool/PaletteMaker/TileDataPalette.tscn").instance()
	$Map.setTileData(tileData)
	$Map.init()
	$Map.revealInitialState()
	
	$Map.find_node("BorderDecorations").runDecoration()
	$Map.find_node("BorderDecorations").runDecoration()
	$Map.find_node("BorderDecorations").runDecoration()
	

	
	find_node("PaletteList").select(0)
	_on_PaletteList_item_selected(0)
	find_node("WorldsList").select(0)
	_on_WorldsList_item_selected(0)
	find_node("DomesList").select(0)
	_on_DomesList_item_selected(0)
	find_node("KeepersList").select(0)
	_on_KeepersList_item_selected(0)

	$CanvasLayer / ReloadLabel.visible = false
	
	var i = preload("res://content/shared/MoveCameraInput.gd").new()
	i.camera = $Camera2D
	i.integrate(self)
	
	Data.apply("monsters.wavepresent", true)
	Data.apply("stunLaser.autonomy", true)
	var d = preload("res://content/monster/driller/Driller.tscn").instance()
	d.path = $Monsters / Path2D
	d.position = Vector2(520, - 80)
	$Monsters.add_child(d)
	d.phase = - 1

func _process(delta):
	if Input.is_action_just_pressed("f2"):
		find_node("GuiExample").visible = not find_node("GuiExample").visible
		
	if Input.is_action_just_pressed("cheats"):
		find_node("Controls").visible = not find_node("Controls").visible
	
	if paletteIndex:
		var paletteFile: = File.new()
		var mod = paletteFile.get_modified_time("res://systems/style/palettes/palette_" + str(paletteIndex) + ".png")
		if lastModifiedPalette == 0.0:
			lastModifiedPalette = mod
		
		if mod != lastModifiedPalette:
			Style.setPalette(paletteIndex, true)
			lastModifiedPalette = mod
			$CanvasLayer / ReloadLabel.visible = true
			$CanvasLayer / ReloadLabel / Timer.start()

func _on_WorldsList_item_selected(index):
	if world:
		world.queue_free()
		world = null
	
	var worldName = find_node("WorldsList").get_item_text(index)
	var scene = load("res://content/worlds/" + worldName + "/" + worldName.capitalize().replace(" ", "") + ".tscn")
	if not scene:
		return 
	world = scene.instance()
	add_child(world)
	world.addBackgroundHub(preload("res://content/gamemode/prestige/rocket/RocketHub.tscn").instance())
	Style.init(world)

func _on_DomesList_item_selected(index):
	updateDome(index)

func updateDome(index: = - 1):
	if dome:
		dome.free()
		Data.apply("shield.stage", 0)
		dome = null
	
	if index == - 1:
		if find_node("DomesList").get_selected_items().size() == 0:
			return 
		else:
			index = find_node("DomesList").get_selected_items()[0]
	
	var domeName = find_node("DomesList").get_item_text(index)
	var scene = load("res://content/dome/" + domeName + "/" + domeName.capitalize().replace(" ", "") + ".tscn")
	if not scene:
		return 
	dome = scene.instance()
	dome.position = $DomePosition.position
	Level.dome = dome
	Data.unlockGadget(dome.techId)
	add_child(dome)
	dome.init()
	Data.unlockGadget(dome.primaryWeapon)
	dome.addWeapon()
	var weapon = dome.get_node("WeaponContainer").get_children().front()
	if weapon:
		weapon.start()
	dome.get_node("CracksOverlay").visible = false
	Style.init(dome)
	unlockGadgets()
	Data.apply("dome.health", Data.of("dome.maxhealth"))
	
	Audio.set_bus_volume(Audio.BUS_MASTER, - 60)
	_on_CellarOnButton_pressed()

func _on_KeepersList_item_selected(index):
	if keeper:
		keeper.queue_free()
		keeper = null
	
	var keeperName = find_node("KeepersList").get_item_text(index)
	var scene = load("res://content/keeper/" + keeperName + "/" + keeperName.capitalize().replace(" ", "") + ".tscn")
	if not scene:
		return 
	keeper = scene.instance()
	keeper.position = $KeeperPosition.position
	Data.unlockGadget(keeper.techId)
	Level.keeper = keeper
	add_child(keeper)
	Style.init(keeper)
	
	var keeper2 = scene.instance()
	keeper2.animationSuffix = "_buffed"
	keeper2.position = Vector2( - 24, 0)
	keeper.add_child(keeper2)
	Style.init(keeper2)
	
	var keeper3 = scene.instance()
	keeper3.animationSuffix = "_buffed"
	keeper3.position = Vector2( - 2, 204)
	keeper.add_child(keeper3)
	Style.init(keeper3)
	
	Style.init($KeeperMinePosition)

func _on_GadgetsList_multi_selected(index, selected):
	updateDome()

func unlockGadgets():
	for i in find_node("GadgetsList").get_selected_items():
		var gadgetName = find_node("GadgetsList").get_item_text(i)
		unlockGadget(gadgetName.to_lower())

func unlockGadget(id: String):
	Data.unlockGadget(id)
	if dome:
		dome.unlockGadget(Data.gadgets.get(id, {}))
	$Map.unlockGadget(Data.gadgets.get(id, {}))

func _on_PaletteList_item_selected(index):
	var n = find_node("PaletteList").get_item_text(index)
	paletteIndex = n.substr(n.find("_") + 1)
	Style.setPalette(paletteIndex)

func _on_Timer_timeout():
	find_node("ReloadLabel").visible = false

func _on_ShowMonstersButton_pressed():
	$Monsters.visible = find_node("ShowMonstersButton").pressed

func _on_UseWeaponButton_pressed():
	if find_node("UseWeaponButton").pressed:
		setWeaponFire()
	else:
		$WeaponTween.remove_all()

func setWeaponFire(dir: Vector2 = Vector2.DOWN):
	var weapon = dome.get_node("WeaponContainer").get_children().front()
	if weapon:
		weapon.move(dir, true, true)
		$WeaponTween.interpolate_callback(self, 1.2, "setWeaponFire", dir * Vector2.UP)
		$WeaponTween.start()

func _on_CellarOnButton_pressed():
	if dome:
		if find_node("CellarOnButton").pressed:
			dome.find_node("RelicActivation").play("activate")
		else:
			dome.find_node("RelicActivation").play("none")
			dome.find_node("SpinningRelic").play("none")

func _on_FireRocketButton_pressed():
	Data.changeByInt("prestige.sentiron", 1)
