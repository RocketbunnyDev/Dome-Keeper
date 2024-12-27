extends VBoxContainer

signal runsFiltered(filteredRuns, filter)

var filter: = {
	"versions": [], 
	"domes": [], 
	"keepers": [], 
	"worlds": [], 
	"modes": [], 
	"difficulties": [], 
	"mapSizes": [], 
	"gadgets": [], 
	"primaryGadgets": [], 
	"endingState": [], 
}

var versions: = []
var domes: = []
var keepers: = []
var worlds: = []
var modes: = []
var difficulties: = []
var mapSizes: = []
var gadgets: = []
var primaryGadgets: = []
var endingState: = []

var buttons: = {}

var allRuns: Array

func init(allRuns: Array):
	self.allRuns = allRuns
	for run in allRuns:
		var version = run.get("meta", {}).get("version", "")
		if not versions.has(version):
			versions.append(version)
		
		for gadgetEvent in run.get("gadgets", []):
			var id = gadgetEvent.get("data", "")
			if id != "" and not gadgets.has(id):
				gadgets.append(id)
		
		var levelData = run.get("level")
		
		var id = levelData.get("domeId", "")
		if id != "" and not domes.has(id):
			domes.append(id)
		
		id = levelData.get("gameMode", "")
		if id != "" and not modes.has(id):
			modes.append(id)
		
		id = levelData.get("keeperId", "")
		if id != "" and not keepers.has(id):
			keepers.append(id)
		
		id = levelData.get("worldId", "")
		if id != "" and not worlds.has(id):
			worlds.append(id)
		
		id = levelData.get("primaryGadgetId", "")
		if id != "" and not primaryGadgets.has(id):
			primaryGadgets.append(id)
		
		id = levelData.get("difficulty", - 99)
		if id != - 99 and not difficulties.has(id):
			difficulties.append(id)
		
		id = levelData.get("mapSize", "")
		if id != "" and not mapSizes.has(id):
			mapSizes.append(id)
		
		id = run.get("state", "")
		if id != "" and not endingState.has(id):
			endingState.append(id)
	
	domes.sort()
	modes.sort()
	keepers.sort()
	worlds.sort()
	primaryGadgets.sort()
	difficulties.sort()
	mapSizes.sort()
	endingState.sort()
	gadgets.sort()
	versions.sort()
	
	for i in range(0, versions.size()):
		var v = versions[i]
		var b = getButton(v)
		buttons["version-" + str(v)] = b
		b.connect("toggled", self, "setVersionFilter", [v])
		find_node("FilterVersionButtons").add_child(b)
		if i == versions.size() - 1:
			b.pressed = true
	
	for id in domes:
		var b = getButton(id)
		buttons["dome-" + str(id)] = b
		b.connect("toggled", self, "setDomeFilter", [id])
		find_node("FilterLoadoutButtons").add_child(b)
	
	for id in modes:
		var b = getButton(id)
		buttons["mode-" + str(id)] = b
		b.connect("toggled", self, "setModeFilter", [id])
		find_node("FilterModeButtons").add_child(b)
	
	for id in keepers:
		var b = getButton(id)
		buttons["keeper-" + str(id)] = b
		b.connect("toggled", self, "setKeeperFilter", [id])
		find_node("FilterLoadoutButtons").add_child(b)
	
	for id in worlds:
		var b = getButton(id)
		buttons["world-" + str(id)] = b
		b.connect("toggled", self, "setWorldFilter", [id])
		find_node("FilterWorldButtons").add_child(b)
	
	for id in primaryGadgets:
		var b = getButton(id)
		buttons["primarygadget-" + str(id)] = b
		b.connect("toggled", self, "setPrimaryGadgetFilter", [id])
		find_node("FilterLoadoutButtons").add_child(b)
	
	for id in difficulties:
		var b = getButton(str(id))
		buttons["difficulty-" + str(id)] = b
		b.connect("toggled", self, "setDifficultyFilter", [id])
		find_node("FilterRelicHuntButtons").add_child(b)
	
	for id in mapSizes:
		var b = getButton(id)
		buttons["mapsize-" + str(id)] = b
		b.connect("toggled", self, "setMapSizeFilter", [id])
		find_node("FilterRelicHuntButtons").add_child(b)
	
	for id in endingState:
		var b = getButton(id)
		buttons["endingstate-" + str(id)] = b
		b.connect("toggled", self, "setEndingStateFilter", [id])
		find_node("FilterModeButtons").add_child(b)
	
	for id in gadgets:
		var b = getButton(id)
		buttons["gadget-" + str(id)] = b
		b.connect("toggled", self, "setGadgetFilter", [id])
		find_node("FilterGadgetButtons").add_child(b)
	
	_on_FilterVersionsButton_pressed()
	_on_FilterModeButton_pressed()
	_on_FilterRelicHuntButton_pressed()
	_on_FilterLoadoutButton_pressed()
	_on_FilterWorldButton_pressed()
	_on_FilterGadgetButton_pressed()

func getButton(v: String)->Button:
	var b = Button.new()
	b.focus_mode = Button.FOCUS_NONE
	b.text = str(v)
	b.toggle_mode = true
	Style.init(b)
	return b

func updateButtons(filteredRuns: Array):
	var amounts: = {
		"version": {}, 
		"dome": {}, 
		"keeper": {}, 
		"world": {}, 
		"mode": {}, 
		"difficulty": {}, 
		"mapsize": {}, 
		"gadget": {}, 
		"primarygadget": {}, 
		"endingstate": {}, 
}
	
	for run in filteredRuns:
		var levelData = run.get("level")
		var id = levelData.get("domeId", "")
		if id != "":
			amounts["dome"][id] = 1 + amounts.get("dome", {}).get(id, 0)
		
		id = levelData.get("gameMode", "")
		if id != "":
			amounts["mode"][id] = 1 + amounts.get("mode", {}).get(id, 0)
		
		id = levelData.get("keeperId", "")
		if id != "":
			amounts["keeper"][id] = 1 + amounts.get("keeper", {}).get(id, 0)
		
		id = levelData.get("worldId", "")
		if id != "":
			amounts["world"][id] = 1 + amounts.get("world", {}).get(id, 0)
		
		id = levelData.get("primaryGadgetId", "")
		if id != "":
			amounts["primarygadget"][id] = 1 + amounts.get("primarygadget", {}).get(id, 0)
		
		id = levelData.get("difficulty", - 99)
		if id != - 99:
			amounts["difficulty"][id] = 1 + amounts.get("difficulty", {}).get(id, 0)
		
		id = levelData.get("mapSize", "")
		if id != "":
			amounts["mapsize"][id] = 1 + amounts.get("mapsize", {}).get(id, 0)
		
		id = run.get("meta", {}).get("version", "")
		if id != "":
			amounts["version"][id] = 1 + amounts.get("version", {}).get(id, 0)
		
		id = run.get("state", "")
		if id != "":
			amounts["endingstate"][id] = 1 + amounts.get("endingstate", {}).get(id, 0)
		
		for gadgetEvent in run.get("gadgets", []):
			id = gadgetEvent.get("data", "")
			if id != "":
				amounts["gadget"][id] = 1 + amounts.get("gadget", {}).get(id, 0)
	
	for buttonId in buttons:
		var type = buttonId.substr(0, buttonId.find("-"))
		var value = buttonId.substr(buttonId.find("-") + 1)
		var amount = amounts.get(type, {}).get(value, 0)
		buttons[buttonId].text = str(value) + " (" + str(amount) + ")"

func setVersionFilter(active: bool, id: String):
	if active:
		filter["versions"].append(id)
	else:
		filter["versions"].erase(id)
	filterChanged()

func setDomeFilter(active: bool, id: String):
	if active:
		filter["domes"].append(id)
	else:
		filter["domes"].erase(id)
	filterChanged()

func setModeFilter(active: bool, id: String):
	if active:
		filter["modes"].append(id)
	else:
		filter["modes"].erase(id)
	filterChanged()

func setKeeperFilter(active: bool, id: String):
	if active:
		filter["keepers"].append(id)
	else:
		filter["keepers"].erase(id)
	filterChanged()

func setWorldFilter(active: bool, id: String):
	if active:
		filter["worlds"].append(id)
	else:
		filter["worlds"].erase(id)
	filterChanged()

func setPrimaryGadgetFilter(active: bool, id: String):
	if active:
		filter["primaryGadgets"].append(id)
	else:
		filter["primaryGadgets"].erase(id)
	filterChanged()

func setDifficultyFilter(active: bool, id: String):
	if active:
		filter["difficulties"].append(id)
	else:
		filter["difficulties"].erase(id)
	filterChanged()

func setMapSizeFilter(active: bool, id: String):
	if active:
		filter["mapSizes"].append(id)
	else:
		filter["mapSizes"].erase(id)
	filterChanged()

func setEndingStateFilter(active: bool, id: String):
	if active:
		filter["endingState"].append(id)
	else:
		filter["endingState"].erase(id)
	filterChanged()

func setGadgetFilter(active: bool, id: String):
	if active:
		filter["gadgets"].append(id)
	else:
		filter["gadgets"].erase(id)
	filterChanged()

func filterChanged():
	var filteredRuns: = []
	
	for run in allRuns:
		if runPassedFilter(run):
			filteredRuns.append(run)
	
	updateButtons(filteredRuns)
	
	emit_signal("runsFiltered", filteredRuns, filter)

func runPassedFilter(run: Dictionary)->bool:
	for filterEntry in filter:
		var filters = filter[filterEntry]
		if filters.size() == 0:
			continue
		
		match filterEntry:
			"versions":
				var version = run.get("meta", {}).get("version", "")
				if not filters.has(version):
					return false
			"domes":
				var id = run.get("level", {}).get("domeId", "")
				if not filters.has(id):
					return false
			"keepers":
				var id = run.get("level", {}).get("keeperId", "")
				if not filters.has(id):
					return false
			"worlds":
				var id = run.get("level", {}).get("worldId", "")
				if not filters.has(id):
					return false
			"modes":
				var id = run.get("level", {}).get("gameMode", "")
				if not filters.has(id):
					return false
			"difficulties":
				var id = run.get("level", {}).get("difficulty", "")
				if not filters.has(id):
					return false
			"mapSizes":
				var id = run.get("level", {}).get("mapSize", "")
				if not filters.has(id):
					return false
			"gadgets":
				var gadgets: = []
				for gadgetEvent in run.get("gadgets", []):
					var id = gadgetEvent.get("data", "")
					if id != "":
						gadgets.append(id)
				for f in filters:
					if not gadgets.has(f):
						return false
			"primaryGadgets":
				var id = run.get("level", {}).get("primaryGadgetId", "")
				if not filters.has(id):
					return false
			"endingState":
				var id = run.get("state", "")
				if not filters.has(id):
					return false
	return true

func _on_FilterVersionsButton_pressed():
	find_node("FilterVersionButtons").visible = find_node("FilterVersionButton").pressed

func _on_FilterModeButton_pressed():
	find_node("FilterModeButtons").visible = find_node("FilterModeButton").pressed

func _on_FilterRelicHuntButton_pressed():
	find_node("FilterRelicHuntButtons").visible = find_node("FilterRelicHuntButton").pressed

func _on_FilterLoadoutButton_pressed():
	find_node("FilterLoadoutButtons").visible = find_node("FilterLoadoutButton").pressed

func _on_FilterWorldButton_pressed():
	find_node("FilterWorldButtons").visible = find_node("FilterWorldButton").pressed

func _on_FilterGadgetButton_pressed():
	find_node("FilterGadgetButtons").visible = find_node("FilterGadgetButton").pressed
