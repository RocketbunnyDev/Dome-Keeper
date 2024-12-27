extends Node2D






var viability_large_noise_strength = 60 + randf() * 60
var viability_small_noise_strength = 10 + randf() * 50
var biome_noise_strength = 0.05 + randf() * 0.9
var depth = 30 + randf() * 70
var viability_stop_width_factor = 0.2 - randf() * 0.15

var threads: = []
var generating: = false

var minI: = 99999999
var maxI: = 0
var allI: = 0
var minW: = 99999999
var maxW: = 0
var allW: = 0
var minC: = 99999999
var maxC: = 0
var allC: = 0
var minS: = 99999999
var maxS: = 0
var allS: = 0
var hardness: Array
var hardnessMin: Array
var hardnessMax: Array
var count: = 0
var boxIndex: = 0
var pastArchetypes: = []
var pastTileData: = []
var accumulatingTileData: Array

func _ready():
	find_node("MapCountLabel").text = str(find_node("MapCountSlider").value)
	find_node("DepthLabel").text = str(find_node("DepthSlider").value)
	find_node("ResourcesButton").pressed = find_node("Resources").visible
	find_node("BiomeButton").pressed = find_node("Biome").visible
	find_node("ViabilityButton").pressed = find_node("Viability").visible
	find_node("SelectArchetypePopup").visible = false
	find_node("SaveArchetypePopup").visible = false
	
	var i = preload("res://content/shared/MoveCameraInput.gd").new()
	i.camera = $Camera2D
	i.integrate(self)
	
	if ResourceLoader.exists("user://arch.res"):
		var r = ResourceLoader.load("user://arch.res", "", true)
		setArchetype(r)
	elif ResourceLoader.exists("res://arch.res"):
		var r = ResourceLoader.load("res://arch.res")
		setArchetype(r)
	
	Style.init($CanvasLayer)

func runGeneration():
	if find_node("RunGenerationButton").disabled:
		Audio.sound("gui_err")
		return 
	
	for generator in $Generators.get_children().duplicate():
		$Generators.remove_child(generator)
		generator.queue_free()
	for tileData in $TileData.get_children():
		$TileData.remove_child(tileData)
	
	minI = 99999999
	maxI = 0
	allI = 0
	minW = 99999999
	maxW = 0
	allW = 0
	minC = 99999999
	maxC = 0
	allC = 0
	minS = 99999999
	maxS = 0
	allS = 0
	hardness = [0, 0, 0, 0, 0, 0]
	hardnessMin = [999999, 999999, 999999, 999999, 999999, 999999]
	hardnessMax = [0, 0, 0, 0, 0, 0]
	count = 0
	accumulatingTileData = []
	
	Audio.sound("gui_select")
	find_node("RunGenerationButton").disabled = true
	generating = true
	
	for _i in find_node("MapCountSlider").value:
		var thread = Thread.new()
		var generator = preload("res://content/map/generation/TileDataGenerator.tscn").instance(1)
		
		generator.init(getArchetype())
		var status: int = thread.start(self, "generateThreaded", generator)
		threads.append(thread)

func generateThreaded(generator):
	generator.generate()
	return generator

func getArchetype()->MapArchetype:
	var archetype = MapArchetype.new()
	archetype.viabilityLargeRange = Vector3(float(find_node("FieldViabilityLargeBase").text), float(find_node("FieldViabilityLargeDelta").text), float(find_node("FieldViabilityLargeExponent").text))
	archetype.viabilitySmallRange = Vector3(float(find_node("FieldViabilitySmallBase").text), float(find_node("FieldViabilitySmallDelta").text), float(find_node("FieldViabilitySmallExponent").text))
	archetype.viability_base = float(find_node("ViabilityBase").text)
	
	archetype.stop_depth_at_fraction = float(find_node("FieldStopDepthStart").text)
	archetype.stop_depth_factor = float(find_node("FieldStopDepthFactor").text)
	archetype.stop_depth_exponent = float(find_node("FieldStopDepthExponent").text)
	archetype.stop_width_at_fraction = float(find_node("FieldStopWidthStart").text)
	archetype.stop_width_factor = float(find_node("FieldStopWidthFactor").text)
	archetype.stop_width_exponent = float(find_node("FieldStopWidthExponent").text)
	
	archetype.keep_core_strength = float(find_node("FieldKeepCoreStrength").text)
	archetype.keep_core_falloff_y = float(find_node("FieldKeepCoreFalloffY").text)
	
	archetype.entry_tightening_until = float(find_node("FieldTightEntryUntil").text)
	archetype.entry_tightening_y_exp = float(find_node("FieldTightEntryExpY").text)
	archetype.entry_tightening_x_exp = float(find_node("FieldTightEntryExpX").text)
	archetype.thin_top_factor = float(find_node("FieldThinTop").text)
	
	archetype.iron_cluster_size_base = float(find_node("FieldIronClusterSizeBase").text)
	archetype.iron_cluster_size_per_y = float(find_node("FieldIronClusterSizePerY").text)
	archetype.iron_cluster_size_randomness = float(find_node("FieldIronClusterSizeRandomness").text)
	
	archetype.biome_depth_scale = float(find_node("BiomeDepthScale").text)
	archetype.biome_distance_scale = float(find_node("BiomeDistScale").text)
	archetype.biome_start = float(find_node("BiomeStart").text)
	archetype.biomeNoiseRange = Vector3(float(find_node("FieldBiomeNoiseBase").text), float(find_node("FieldBiomeNoiseDelta").text), float(find_node("FieldBiomeNoiseExponent").text))
	
	archetype.depth = int(find_node("DepthSlider").value)
	archetype.width = int(find_node("WidthSlider").value)
	
	archetype.generateResources = find_node("GenerateResourcesCheckBox").pressed
	archetype.iron_cluster_rate = float(find_node("IronRate").text)
	archetype.water_rate = float(find_node("WaterRate").text)
	archetype.cobalt_rate = float(find_node("CobaltRate").text)
	archetype.iron_cluster_removal_rate = float(find_node("IronRemoval").text)
	archetype.water_removal_rate = float(find_node("WaterRemoval").text)
	archetype.cobalt_removal_rate = float(find_node("CobaltRemoval").text)
	
	archetype.relics = int(find_node("FieldRelicAmount").text)
	archetype.relic_depth_step = float(find_node("FieldRelicStepY").text)
	
	archetype.relic_switches = int(find_node("FieldRelicSwitchAmount").text)
	archetype.relic_switch_distance_range = Vector2(float(find_node("FieldRelicSwitchMinD").text), float(find_node("FieldRelicSwitchMaxD").text))
	
	archetype.gadgets = int(find_node("FieldGadgetAmount").text)
	archetype.gadget_first_depth = float(find_node("FieldGadgetStartY").text)
	archetype.gadget_depth_step = float(find_node("FieldGadgetStepY").text)
	
	archetype.hardness_offset = float(find_node("FieldHardnessOffset").text)
	archetype.hardness_min = int(find_node("FieldHardnessMin").text)
	archetype.hardness_max = int(find_node("FieldHardnessMax").text)
	archetype.hardness_scale = float(find_node("FieldHardnessScale").text)
	
	archetype.setNoise()
	archetype.init()
	
	return archetype

func setArchetype(archetype: MapArchetype):
	find_node("ViabilityBase").text = str(archetype.viability_base)
	
	find_node("FieldStopDepthStart").text = str(archetype.stop_depth_at_fraction)
	find_node("FieldStopDepthFactor").text = str(archetype.stop_depth_factor)
	find_node("FieldStopDepthExponent").text = str(archetype.stop_depth_exponent)
	find_node("FieldStopWidthStart").text = str(archetype.stop_width_at_fraction)
	find_node("FieldStopWidthFactor").text = str(archetype.stop_width_factor)
	find_node("FieldStopWidthExponent").text = str(archetype.stop_width_exponent)

	find_node("FieldTightEntryUntil").text = str(archetype.entry_tightening_until)
	find_node("FieldTightEntryExpY").text = str(archetype.entry_tightening_y_exp)
	find_node("FieldTightEntryExpX").text = str(archetype.entry_tightening_x_exp)
	find_node("FieldThinTop").text = str(archetype.thin_top_factor)
	
	find_node("FieldKeepCoreStrength").text = str(archetype.keep_core_strength)
	find_node("FieldKeepCoreFalloffY").text = str(archetype.keep_core_falloff_y)
	
	find_node("FieldIronClusterSizeBase").text = str(archetype.iron_cluster_size_base)
	find_node("FieldIronClusterSizePerY").text = str(archetype.iron_cluster_size_per_y)
	find_node("FieldIronClusterSizeRandomness").text = str(archetype.iron_cluster_size_randomness)

	find_node("BiomeDepthScale").text = str(archetype.biome_depth_scale)
	find_node("BiomeDistScale").text = str(archetype.biome_distance_scale)
	find_node("BiomeStart").text = str(archetype.biome_start)

	find_node("DepthSlider").value = archetype.depth
	find_node("WidthSlider").value = archetype.width

	find_node("GenerateResourcesCheckBox").pressed = archetype.generateResources
	find_node("IronRate").text = str(archetype.iron_cluster_rate)
	find_node("WaterRate").text = str(archetype.water_rate)
	find_node("CobaltRate").text = str(archetype.cobalt_rate)
	find_node("IronRemoval").text = str(archetype.iron_cluster_removal_rate)
	find_node("WaterRemoval").text = str(archetype.water_removal_rate)
	find_node("CobaltRemoval").text = str(archetype.cobalt_removal_rate)

	find_node("FieldRelicAmount").text = str(archetype.relics)
	find_node("FieldRelicStepY").text = str(archetype.relic_depth_step)
	
	find_node("FieldRelicSwitchAmount").text = str(archetype.relic_switches)
	find_node("FieldRelicSwitchMinD").text = str(archetype.relic_switch_distance_range.x)
	find_node("FieldRelicSwitchMaxD").text = str(archetype.relic_switch_distance_range.y)
	
	find_node("FieldGadgetAmount").text = str(archetype.gadgets)
	find_node("FieldGadgetStartY").text = str(archetype.gadget_first_depth)
	find_node("FieldGadgetStepY").text = str(archetype.gadget_depth_step)
	
	find_node("FieldViabilityLargeBase").text = str(archetype.viabilityLargeRange.x)
	find_node("FieldViabilityLargeDelta").text = str(archetype.viabilityLargeRange.y)
	find_node("FieldViabilityLargeExponent").text = str(archetype.viabilityLargeRange.z)
	
	find_node("FieldViabilitySmallBase").text = str(archetype.viabilitySmallRange.x)
	find_node("FieldViabilitySmallDelta").text = str(archetype.viabilitySmallRange.y)
	find_node("FieldViabilitySmallExponent").text = str(archetype.viabilitySmallRange.z)
	
	find_node("FieldBiomeNoiseBase").text = str(archetype.biomeNoiseRange.x)
	find_node("FieldBiomeNoiseDelta").text = str(archetype.biomeNoiseRange.y)
	find_node("FieldBiomeNoiseExponent").text = str(archetype.biomeNoiseRange.z)
	
	find_node("FieldHardnessOffset").text = str(archetype.hardness_offset)
	find_node("FieldHardnessMin").text = str(archetype.hardness_min)
	find_node("FieldHardnessMax").text = str(archetype.hardness_max)
	find_node("FieldHardnessScale").text = str(archetype.hardness_scale)

func _process(delta):
	if Input.is_action_just_pressed("cheats"):
		Audio.sound("gui_hover")
		find_node("Controls").visible = not find_node("Controls").visible
	
	if Input.is_action_just_pressed("f2"):
		runGeneration()
	
	if generating:
		for thread in threads.duplicate():
			if not thread.is_alive():
				var generator = thread.wait_to_finish()
				var children = $TileData.get_children()
				var tileData = generator.popTileData()
				$TileData.add_child(tileData)
				accumulatingTileData.append(tileData)
				count += 1
				if children.size() > 0:
					var lastMap = children.back()
					tileData.position = lastMap.position
					var x = lastMap.getMapSizePx().x + 100
					tileData.position.x += x
					if tileData.position.x > sqrt(find_node("MapCountSlider").value) * x:
						tileData.position.x = 0
						tileData.position.y += lastMap.getMapSizePx().y + 600
				
				var box = VBoxContainer.new()
				box.mouse_filter = Control.MOUSE_FILTER_IGNORE
				box.theme = preload("res://gui/theme.tres")
				box.rect_scale *= 2
				var l = Label.new()
				var size = tileData.get_tile_count()
				minS = min(minS, size)
				maxS = max(maxS, size)
				allS += size
				l.text = "Size: " + str(tileData.getSize().x) + " x " + str(tileData.getSize().y) + " = " + str(size) + " cells"
				box.add_child(l)
				l = Label.new()
				var iron = tileData.get_resource_cells_by_id(0).size()
				minI = min(minI, iron)
				maxI = max(maxI, iron)
				allI += iron
				l.text = "Iron: " + str(iron)
				box.add_child(l)
				l = Label.new()
				var water = tileData.get_resource_cells_by_id(1).size()
				minW = min(minW, water)
				maxW = max(maxW, water)
				allW += water
				l.text = "Water: " + str(water)
				box.add_child(l)
				l = Label.new()
				var cobalt = tileData.get_resource_cells_by_id(2).size()
				minC = min(minC, cobalt)
				maxC = max(maxC, cobalt)
				allC += cobalt
				l.text = "Cobalt: " + str(cobalt)
				box.add_child(l)
				l = Label.new()
				var h0 = tileData.get_hardness_cells_by_grade(0).size()
				var h1 = tileData.get_hardness_cells_by_grade(1).size()
				var h2 = tileData.get_hardness_cells_by_grade(2).size()
				var h3 = tileData.get_hardness_cells_by_grade(3).size()
				var h4 = tileData.get_hardness_cells_by_grade(4).size()
				var h5 = tileData.get_hardness_cells_by_grade(5).size()
				hardness[0] += h0
				hardness[1] += h1
				hardness[2] += h2
				hardness[3] += h3
				hardness[4] += h4
				hardness[5] += h5
				hardnessMin[0] = min(h0, hardnessMin[0])
				hardnessMin[1] = min(h1, hardnessMin[1])
				hardnessMin[2] = min(h2, hardnessMin[2])
				hardnessMin[3] = min(h3, hardnessMin[3])
				hardnessMin[4] = min(h4, hardnessMin[4])
				hardnessMin[5] = min(h5, hardnessMin[5])
				hardnessMax[0] = max(h0, hardnessMax[0])
				hardnessMax[1] = max(h1, hardnessMax[1])
				hardnessMax[2] = max(h2, hardnessMax[2])
				hardnessMax[3] = max(h3, hardnessMax[3])
				hardnessMax[4] = max(h4, hardnessMax[4])
				hardnessMax[5] = max(h5, hardnessMax[5])
				l.text = "Hardness: " + str(h0) + " - " + str(h1) + " - " + str(h2) + " - " + str(h3) + " - " + str(h4) + " - " + str(h5)
				box.add_child(l)
				
				box.rect_position.y = tileData.getMapSizePx().y
				box.rect_position.x = - 200
				tileData.add_child(box)

				threads.erase(thread)
		if threads.size() == 0:
			generating = false
			find_node("RunGenerationButton").disabled = false
			Audio.sound("gui_title_credits")
			
			var totalBox = VBoxContainer.new()
			totalBox.mouse_filter = Control.MOUSE_FILTER_IGNORE
			totalBox.theme = preload("res://gui/theme.tres")
			totalBox.rect_scale *= 2
			var l = Label.new()
			l.text = "Size: " + str(minS) + " ~ " + ("%.0f" % (allS / float(count))) + " ~ " + str(maxS)
			totalBox.add_child(l)
			l = Label.new()
			l.text = "Iron: " + str(minI) + " ~ " + ("%.0f" % (allI / float(count))) + " ~ " + str(maxI)
			totalBox.add_child(l)
			l = Label.new()
			l.text = "Water: " + str(minW) + " ~ " + ("%.0f" % (allW / float(count))) + " ~ " + str(maxW)
			totalBox.add_child(l)
			l = Label.new()
			l.text = "Cobalt: " + str(minC) + " ~ " + ("%.0f" % (allC / float(count))) + " ~ " + str(maxC)
			totalBox.add_child(l)
			var grid: = GridContainer.new()
			grid.columns = 2
			l = Label.new()
			l.text = "Hardness 1: "
			grid.add_child(l)
			l = Label.new()
			l.text = "%5.0f" % hardnessMin[0] + " ~ " + "%5.0f" % (hardness[0] / float(count)) + " ~ " + "%5.0f" % hardnessMax[0]
			grid.add_child(l)
			l = Label.new()
			l.text = "Hardness 2: "
			grid.add_child(l)
			l = Label.new()
			l.text = "%5.0f" % hardnessMin[1] + " ~ " + "%5.0f" % (hardness[1] / float(count)) + " ~ " + "%5.0f" % hardnessMax[1]
			grid.add_child(l)
			l = Label.new()
			l.text = "Hardness 3: "
			grid.add_child(l)
			l = Label.new()
			l.text = "%5.0f" % hardnessMin[2] + " ~ " + "%5.0f" % (hardness[2] / float(count)) + " ~ " + "%5.0f" % hardnessMax[2]
			grid.add_child(l)
			l = Label.new()
			l.text = "Hardness 4: "
			grid.add_child(l)
			l = Label.new()
			l.text = "%5.0f" % hardnessMin[3] + " ~ " + "%5.0f" % (hardness[3] / float(count)) + " ~ " + "%5.0f" % hardnessMax[3]
			grid.add_child(l)
			l = Label.new()
			l.text = "Hardness 5: "
			grid.add_child(l)
			l = Label.new()
			l.text = "%5.0f" % hardnessMin[4] + " ~ " + "%5.0f" % (hardness[4] / float(count)) + " ~ " + "%5.0f" % hardnessMax[4]
			grid.add_child(l)
			l = Label.new()
			l.text = "Border Tiles: "
			grid.add_child(l)
			l = Label.new()
			l.text = "%5.0f" % hardnessMin[5] + " ~ " + "%5.0f" % (hardness[5] / float(count)) + " ~ " + "%5.0f" % hardnessMax[5]
			grid.add_child(l)
			totalBox.add_child(grid)
			totalBox.rect_position.y = - 1100
			totalBox.rect_position.x = boxIndex * 1000
			
			var button = Button.new()
			button.text = "load"
			pastArchetypes.append(getArchetype())
			pastTileData.append(accumulatingTileData)
			button.focus_mode = Control.FOCUS_NONE
			button.connect("pressed", self, "loadRun", [boxIndex])
			boxIndex += 1
			Style.init(button)
			totalBox.add_child(button)
			add_child(totalBox)

func loadRun(i: int):
	setArchetype(pastArchetypes[i])
	for tileData in $TileData.get_children():
		$TileData.remove_child(tileData)
	for tileData in pastTileData[i]:
		$TileData.add_child(tileData)
	
func _on_RunGenerationButton_pressed():
	runGeneration()

func _on_MapCountSlider_value_changed(value):
	find_node("MapCountLabel").text = str(value)

func _on_DepthSlider_value_changed(value):
	find_node("DepthLabel").text = str(value)

func _on_WidthSlider_value_changed(value):
	find_node("WidthLabel").text = str(value)

func _on_BiomesButton_pressed():
	for c in $TileData.get_children():
		var hd = c.find_node("Hardness", false, false)
		if hd:
			hd.visible = false

func _on_HardnessButton_pressed():
	for c in $TileData.get_children():
		var hd = c.find_node("Hardness", false, false)
		if hd:
			hd.visible = true

func _on_SaveButton_pressed():
	find_node("SaveArchetypePopup").visible = true
	find_node("SelectArchetypePopup").visible = false
	for c in find_node("SaveArchetypeList").get_children():
		if c is Button:
			c.queue_free()
	var dir = Directory.new()
	dir.open("res://content/map/generation/archetypes")
	dir.list_dir_begin()
	var fileNames: = []
	while true:
		var fileName = dir.get_next()
		if fileName == "":
			break
		if fileName.ends_with(".res"):
			fileNames.append(fileName)
	if not fileNames.has("arch.res"):
		fileNames.append("arch.res")
	for fileName in fileNames:
		var b: = Button.new()
		b.text = fileName.substr(0, fileName.find("."))
		b.connect("pressed", self, "saveArchetype", ["res://content/map/generation/archetypes/" + fileName])
		find_node("SaveArchetypeList").add_child(b)
		Style.init(b)

func saveArchetype(path: String):
	var result = ResourceSaver.save(path, getArchetype())
	find_node("CurrentArchetypeLabel").text = path.substr(path.find_last("/") + 1)
	find_node("SaveArchetypePopup").visible = false

func _on_LoadButton_pressed():
	find_node("SelectArchetypePopup").visible = true
	find_node("SaveArchetypePopup").visible = false
	for c in find_node("ArchetypeList").get_children():
		if c is Button:
			c.queue_free()
	var dir = Directory.new()
	dir.open("res://content/map/generation/archetypes")
	dir.list_dir_begin()
	while true:
		var fileName = dir.get_next()
		if fileName == "":
			break
		if fileName.ends_with(".res"):
			var b: = Button.new()
			b.text = fileName.substr(0, fileName.find("."))
			b.connect("pressed", self, "loadArchetype", ["res://content/map/generation/archetypes/" + fileName])
			find_node("ArchetypeList").add_child(b)
			Style.init(b)

func loadArchetype(path: String):
	if ResourceLoader.exists(path):
		var r = ResourceLoader.load(path, "", true)
		setArchetype(r)
		find_node("SelectArchetypePopup").visible = false
		find_node("CurrentArchetypeLabel").text = path.substr(path.find_last("/") + 1)

func _on_ResourcesButton_toggled(button_pressed):
	Audio.sound("gui_move")
	find_node("Resources").visible = button_pressed

func _on_BiomeButton_toggled(button_pressed):
	Audio.sound("gui_move")
	find_node("Biome").visible = button_pressed

func _on_ViabilityButton_toggled(button_pressed):
	Audio.sound("gui_move")
	find_node("Viability").visible = button_pressed

func _on_CloseArchetypeButton_pressed():
	find_node("SelectArchetypePopup").visible = false

func _on_CloseSaveArchetypeButton_pressed():
	find_node("SaveArchetypePopup").visible = false


func _on_ClearRunsButton_pressed():
	pastArchetypes.clear()
	for i in pastTileData:
		for j in i:
			j.queue_free()
	pastTileData.clear()
	
	for c in get_children():
		if c is VBoxContainer:
			c.queue_free()
	
	boxIndex = 0
