extends Node

export (bool) var useCachedAggregateRunsFile: bool
export (Array) var majorVersions: Array

var filteredRuns: Array
var filter: Dictionary
var currentView: = 0

func _ready():
	GameWorld.prepareCleanData()
	
	Style.init(self)
	
	OS.window_maximized = true
	get_tree().set_screen_stretch(SceneTree.STRETCH_MODE_2D, SceneTree.STRETCH_ASPECT_EXPAND, Vector2(1920, 1080), 1)
	
	var cachedAggregateSessionFile = File.new()
	var err = cachedAggregateSessionFile.open("user://cache_aggregate.json", File.READ if useCachedAggregateRunsFile else File.WRITE)
	if err != 0:
		print("error when opening cachedAggregateSessionFile: " + str(err))
		get_tree().quit()
	
	var allRuns: Array
	if useCachedAggregateRunsFile:
		var parsed = JSON.parse(cachedAggregateSessionFile.get_as_text())
		allRuns = parsed.result
		cachedAggregateSessionFile.close()
	else:
		allRuns = []
		var allSessions: = []
		var dir = Directory.new()
		if not dir.dir_exists("user://cache/"):
			dir.make_dir("user://cache/")
		if dir.open("user://cache/") == OK:
			dir.list_dir_begin()
			var file_name = dir.get_next()
			while file_name != "":
				if not dir.current_is_dir():
					var f = File.new()
					err = f.open("user://cache/" + file_name, File.READ)
					if err == 0:
						var r = JSON.parse(f.get_as_text()).result
						allSessions.append(r)
					else:
						print("error when opening " + file_name + ": " + str(err))
					f.close()
				file_name = dir.get_next()
			
			for s in allSessions:
				var runs: = Backend.parseRunsFromSession(s)
				if majorVersions.size() == 0:
					allRuns.append_array(runs)
				else:
					for run in runs:
						var version = run.get("meta", {}).get("version", "v0.")
						version = version.substr(1, 2)
						if majorVersions.has(version):
							allRuns.append(run)
			
			cachedAggregateSessionFile.store_string(JSON.print(allRuns))
			cachedAggregateSessionFile.close()
		else:
			print("An error occurred when trying to access the session cache path.")
			get_tree().quit()
	
	GameWorld.upgrades = Data.upgrades
	for id in ["dome1", "dome2", "shield-battle2", "shield-battle3", "repellent-battle2", "repellent-battle3", "orchard-battle2", "orchard-battle3", "cobaltgeneration"]:
		GameWorld.setUpgradeLimitAvailable(id)
	
	for id in ["dome1", "dome2", "keeper1", "shield", "repellent", "orchard", "probe", "condenser", "converter", "drillbot", "lift", "stunlaser", "teleporter"]:
		Data.unlockGadget(id)
		GameWorld.unlockGadget(id)
	
	find_node("TechTree").build()
	find_node("RunFilter").init(allRuns)

func updateView():
	for v in get_tree().get_nodes_in_group("gi_view"):
		v.visible = false
	
	match currentView:
		0:
			find_node("StatsView").updateStats(filteredRuns, filter)
		1: updateTechTree()
		2: find_node("DamagePerWaveView").updateView(filteredRuns)
		3: find_node("DamagePerWaveView").updateView(filteredRuns)

func updateTechTree():
	find_node("TechTreeView").visible = true
	
	var counts: = {}
	for run in filteredRuns:
		for entry in run.get("gadgets"):
			var id = entry.get("data")
			counts[id] = counts.get(id, 0) + 1
		for entry in run.get("upgrades"):
			var id = entry.get("data")
			counts[id] = counts.get(id, 0) + 1
		var levelData = run.get("level")
		var keeperId = levelData.get("keeperId", "_")
		var domeId = levelData.get("domeId", "_")
		var weaponId = levelData.get("weaponId", "_")
		var primaryGadgetId = levelData.get("primaryGadgetId", "_")
		counts[keeperId] = counts.get(keeperId, 0) + 1
		counts[domeId] = counts.get(domeId, 0) + 1
		counts[weaponId] = counts.get(weaponId, 0) + 1
		counts[primaryGadgetId] = counts.get(primaryGadgetId, 0) + 1
	
	var tracks = find_node("TechTree").find_node("Tracks").get_children()
	for track in tracks:
		for techId in track.techPanels:
			var count = counts.get(techId, 0)
			var panel = track.techPanels[techId]
			panel.setAnalytics(count)
	Style.init(find_node("TechTree"))

func updateWaves():
	find_node("WavesView").visible = true
	
	var wavesView = find_node("WavesView")
	for c in find_node("WavesView").get_children():
		c.queue_free()
	
	var counts: = {}
	for run in filteredRuns:
		for entry in run.get("waves"):
			var waveId = entry.get("data")
			if waveId:
				counts[waveId] = counts.get(waveId, 0) + 1
	
	var line = Line2D.new()
	line.width = 3
	line.default_color = Style.LIVE
	
	var maxEntry: = 0.0
	for c in counts.values():
		maxEntry = max(c, maxEntry)
	
	var keys = counts.keys()
	keys.sort()
	var i: = 0
	var stepX = (wavesView.rect_size.x - 20) / counts.size()
	var size = wavesView.rect_size.y - 20
	for c in keys:
		var count = counts.get(c)
		var x = i * stepX + 10
		var y = size - (count / maxEntry) * size + 20
		line.add_point(Vector2(x, y))
		var l = Label.new()
		l.set("custom_fonts/font", preload("res://gui/fonts/FontSmall.tres"))

		l.text = str(c)
		l.rect_position.x = x + 5
		l.rect_position.y = y - 15
		line.add_child(l)
		i += 1
	wavesView.add_child(line)
	var lastX = i * 10 + 100
	wavesView.rect_min_size.x = lastX

	find_node("MonsterList").add_item("Walker 1")
	find_node("MonsterList").add_item("Walker 2")
	find_node("MonsterList").add_item("Flyer 1")
	find_node("MonsterList").add_item("Flyer 2")
	find_node("MonsterList").add_item("Driller 1")
	find_node("MonsterList").add_item("Driller 2")
	find_node("MonsterList").add_item("Diver 1")
	find_node("MonsterList").add_item("Diver 2")
	find_node("MonsterList").add_item("Tick 1")
	find_node("MonsterList").add_item("Tick 2")
	find_node("MonsterList").add_item("Worm 1")
	find_node("MonsterList").add_item("Worm 2")
	find_node("MonsterList").add_item("Bolter 1")
	find_node("MonsterList").add_item("Bolter 2")
	find_node("MonsterList").add_item("Mucker 1")
	find_node("MonsterList").add_item("Mucker 2")
	find_node("MonsterList").add_item("Shifter 1")
	find_node("MonsterList").add_item("Shifter 2")
	find_node("MonsterList").add_item("Big Tick 1")
	find_node("MonsterList").add_item("Big Tick 2")
	find_node("MonsterList").add_item("Butterfly 1")
	find_node("MonsterList").add_item("Butterfly 2")
	find_node("MonsterList").add_item("Beast 1")
	find_node("MonsterList").add_item("Beast 2")
	find_node("MonsterList").add_item("Rockman 1")
	find_node("MonsterList").add_item("Rockman 2")
	


func updateIron():
	find_node("IronView").visible = true
	
	var ironPlotContainer = find_node("IronPlotContainer")
	for c in ironPlotContainer.get_children():
		c.queue_free()
	
	var maxX = 0
	var height = 3000
	for run in filteredRuns:
		var ironCount: = 0
		var line = Line2D.new()
		line.width = 1
		line.default_color = Style.LIVE
		line.add_point(Vector2(10, height - 10))
		for entry in run.get("mining"):
			if entry.get("type") != "mine_iron":
				continue
			
			ironCount += entry.get("data")
			var time = entry.get("time")
			var x = time / 500.0
			maxX = max(x, maxX)
			var y = height - (ironCount * 5 + 10)
			line.add_point(Vector2(x, y))
		
		ironPlotContainer.add_child(line)
	ironPlotContainer.rect_min_size.x = maxX
	ironPlotContainer.rect_min_size.y = height

func updateRunWeight():
	pass

func _on_StatsButton_pressed():
	currentView = 0
	updateView()

func _on_TechTreeButton_pressed()->void :
	currentView = 1
	updateView()

func _on_MonsterDamageButton_pressed():
	currentView = 2
	updateView()

func _on_RunWeight_pressed():
	currentView = 3
	updateView()

func _on_RunFilter_runsFiltered(filteredRuns, filter):
	self.filteredRuns = filteredRuns
	self.filter = filter
	updateView()

