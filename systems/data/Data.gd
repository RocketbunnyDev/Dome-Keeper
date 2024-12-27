extends Node

var gameProperties: Dictionary
var upgrades: Dictionary
var gadgets: Dictionary
var orderedUpgradeKeys: Array
var worldModifiers: Dictionary

var values: Dictionary
var templates: Dictionary
var listeners: = {}

var NOISE_TEXTURES: = [
	preload("res://content/map/tile/noise1.tres"), 
	preload("res://content/map/tile/noise2.tres"), 
	preload("res://content/map/tile/noise3.tres"), 
	preload("res://content/map/tile/noise4.tres"), 
	preload("res://content/map/tile/noise5.tres")
]

var DROP_SCENES: = {
	CONST.IRON: preload("res://content/drop/iron/IronDrop.tscn"), 
	CONST.WATER: preload("res://content/drop/water/WaterDrop.tscn"), 
	CONST.SAND: preload("res://content/drop/sand/SandDrop.tscn"), 
	CONST.GADGET: preload("res://content/drop/gadget/GadgetDrop.tscn"), 
	CONST.RELIC: preload("res://content/drop/relic/RelicDrop.tscn"), 
	CONST.SEED: preload("res://content/drop/seed/Seed.tscn"), 
	CONST.EGG: preload("res://content/drop/egg/Egg.tscn"), 
	CONST.TREAT: preload("res://content/drop/treat/Treat.tscn"), 
}

var DROP_ICONS: = {
	CONST.IRON: preload("res://content/icons/icon_iron.png"), 
	CONST.WATER: preload("res://content/icons/icon_water.png"), 
	CONST.SAND: preload("res://content/icons/icon_sand.png"), 
}

const TILE_EMPTY: = - 1
const TILE_BORDER: = 21
const TILE_IRON: = 0
const TILE_WATER: = 1
const TILE_SAND: = 2
const TILE_GADGET: = 3
const TILE_RELIC: = 4
const TILE_NEST: = 5
const TILE_RELIC_SWITCH: = 6
const TILE_CAVE: = 9
const TILE_DIRT_START: = 10
const TILE_DIRT_END: = 19

const PATH_PROBE: = preload("res://content/shared/PathProbe.tscn")
const TILE_BREAK_PARTICLES: = preload("res://content/map/tile/tile_break_particles.tscn")
const KEEPER_SPARK = preload("res://content/keeper/Spark.tscn")
const TILE_DIRT_PARTICLE = preload("res://content/map/tile/DirtParticle.tscn")
const CARRYLINE_BREAK = preload("res://content/keeper/carryline/CarrylineBreak.tscn")
const PROBE = preload("res://content/gadgets/probe/Probe.tscn")

const LanguageNamesByCode: = {
		"ar_SA": "Arabic", 
		"bg_BG": "Bulgarian", 
		"cs_CZ": "Czech", 
		"da_DK": "Danish", 
		"de_DE": "German", 
		"en_US": "English", 
		"es_ES": "Spanish", 
		"es_AR": "Latin Spanish", 
		"fi_FI": "Finnish", 
		"fr_FR": "French", 
		"he_IL": "Hebrew", 
		"hu_HU": "Hungarian", 
		"id_ID": "Indonesian", 
		"it_IT": "Italian", 
		"ja_JP": "Japanese", 
		"ko_KR": "Korean", 
		"nl_NL": "Dutch", 
		"nb_NO": "Norwegian", 
		"pl_PL": "Polish", 
		"pt_BR": "Brazilian Portuguese", 
		"pt_PT": "Portuguese", 
		"ro_RO": "Romanian", 
		"ru_RU": "Russian", 
		"sv_SE": "Swedish", 
		"th_TH": "Thai", 
		"tr_TR": "Turkish", 
		"uk_UA": "Ukrainian", 
		"vi_VN": "Vietnamese", 
		"zh_CN": "Simplified Chinese", 
		"zh_TW": "Traditional Chinese"
}

func _ready():
	var f = File.new()
	f.open("res://properties.yaml", File.READ)
	var currentId
	while not f.eof_reached():
		var line = f.get_line()
		var parts = line.split(":", false)
		match parts.size():
			0:
				currentId = null
			1:
				currentId = parts[0].strip_edges().to_lower()
			2:
				var key = currentId + "." + parts[0].strip_edges().to_lower()
				if parts[0].to_lower().find("template") != - 1:
					templates[key.substr(0, key.length() - 8)] = parts[1].strip_edges()
				elif parts[1].find(",") != - 1:
					var values: = []
					for v in parts[1].split(","):
						values.append(str2var(v.strip_edges()))
					gameProperties[key] = values
				else:
					gameProperties[key] = str2var(parts[1].strip_edges())
	f.close()
	
	
	upgrades = {}
	gadgets = {}
	f = File.new()
	var err = f.open("res://upgrades.yaml", File.READ)
	if err == OK:
		var currentKey
		var currentData
		var propertyChanges
		while not f.eof_reached():
			var line: String = f.get_line()
			if line.strip_edges().length() > 1:
				
				if line.begins_with(" "):
					
					if propertyChanges != null:
						line = line.strip_edges()
						if line.begins_with("-"):
							var value = line.substr(1, line.length() - 1)
							var change = PropertyChange.new(value)
							propertyChanges.append(change)
							continue
						else:
							
							propertyChanges = null
					
					var split = line.split(":")
					var key = split[0].strip_edges().to_lower()
					var value = split[1].strip_edges()
					if key == "propertychanges" or key == "repeatable":
						propertyChanges = []
						currentData[key] = propertyChanges
					elif value.begins_with("["):
						value = value.replace(" ", "")
						var a = []
						var values = value.substr(1, value.length() - 2).to_lower()
						for val in values.split(","):
							a.append(str2var(val))
						currentData[key] = a

					else:
						currentData[key] = str2var(value)
				else:
					
					var key = line.substr(0, line.find(":")).to_lower()
					if currentKey:
						storeUpgradeData(currentKey, currentData)
					currentKey = key
					currentData = {}
			else:
				if currentKey:
					storeUpgradeData(currentKey, currentData)
					currentKey = null
					currentData = null
	else:
		Logger.error("failed to open upgrades.yaml. Error: " + str(err))
		get_tree().quit()
	f.close()
	
	
	for gk in gadgets:
		gadgets[gk]["id"] = gk
		gadgets[gk]["tier"] = 0
		upgrades[gk] = gadgets[gk]
	
	
	for uk in upgrades.keys().duplicate():
		var unknownPredecessor: = ""
		var upgradeData = upgrades[uk]
		upgradeData["id"] = uk
		if upgradeData.has("predecessors"):
			for techId in upgradeData.get("predecessors"):
				if not upgrades.has(techId):
					unknownPredecessor = techId
		if unknownPredecessor != "":
			Logger.warn("Upgrade " + uk + " has an unknown predecessor " + unknownPredecessor + ". Removing it from upgrades.")
			upgrades.erase(uk)
			orderedUpgradeKeys.erase(uk)
	
	
	var openUpgrades: = upgrades.duplicate()
	for gk in gadgets:
		openUpgrades.erase(gk)
	var currentTier: = 1
	var tieredUpgrades = []
	while true:
		for uk in openUpgrades.keys():
			var maxTier: = 0
			for techId in upgrades[uk].get("predecessors", []):
				maxTier = upgrades[techId].get("tier", 9999)
			if maxTier < 9999:
				tieredUpgrades.append(uk)
		
		if tieredUpgrades.size() == 0:
			break
		else:
			for uk in tieredUpgrades:
				upgrades[uk]["tier"] = currentTier
				openUpgrades.erase(uk)
				
		currentTier += 1
		tieredUpgrades.clear()
	
	for uk in upgrades.keys():
		var u = upgrades[uk]
		var locks = upgrades.get(uk).get("locks", [])
		for l in locks:
			var uu = upgrades.get(l)
			u["tier"] = max(u["tier"], uu.get("tier", 0))
	
	for uk in upgrades.keys():
		if upgrades[uk].has("cost"):
			var costs: = {}
			var split1 = upgrades[uk].get("cost").split(",")
			for costString in split1:
				var split2 = costString.split("=")
				costs[str(split2[0]).strip_edges()] = int(split2[1])
			upgrades[uk]["cost"] = costs

func storeUpgradeData(key: String, currentData: Dictionary):
	if currentData.has("predecessors"):
		upgrades[key] = currentData
		orderedUpgradeKeys.append(key)
	elif currentData.has("rating"):
		worldModifiers[key] = currentData
	else:
		gadgets[key] = currentData
		orderedUpgradeKeys.append(key)

func reset():
	values.clear()
	for k in gameProperties:
		applyFromGamedata(k, 0)

func of(property: String):
	property = property.to_lower()
	if not values.has(property):
		Logger.error("Tried to access unknown data " + property)
		return - 1
	return values[property]

func ofOr(property: String, default):
	property = property.to_lower()
	return values.get(property, default)

func default(property: String):
	property = property.to_lower()
	if not gameProperties.has(property):
		Logger.error("data is missing", "Data.default", property)
		return null
	var v = gameProperties.get(property)
	if v.size() == 0:
		Logger.error("invalid gameProperties index", "Data.default", {"property": property})
		return null
	return v[0]

func unlockGadget(id: String):
	if not gadgets.has(id):
		Logger.error("unknown gadget to unlock", "Data.unlockGadget", id)
		return 
	
	for propertyChange in gadgets[id].get("propertychanges", []):
		applyPropertyChange(propertyChange)

func unlockUpgrade(id: String):
	if not upgrades.has(id):
		Logger.error("unknown upgrade to unlock", "Data.unlockUpgrade", id)
		return 
	
	for propertyChange in upgrades[id].get("propertychanges", []):
		applyPropertyChange(propertyChange)

func applyPropertyChange(propertyChange: PropertyChange):
	var oldValue = values.get(propertyChange.key, null)
	var newVal = propertyChange.applyValue(oldValue)
	values[propertyChange.key] = newVal
	var invalids: = []
	for l in listeners.get(propertyChange.key, []):
		if is_instance_valid(l):
			l.propertyChanged(propertyChange.key, oldValue, newVal)
		else:
			Logger.error("listener was freed without unlistening", "Data.apply", {"property": propertyChange.key})
			invalids.append(l)
	for i in invalids:
		listeners.erase(i)

func applyAdditionalFromGamedata(property: String, valueIndex: int):
	property = property.to_lower()
	if not gameProperties.has(property):
		Logger.error("data is missing", "Data.applyFromGamedata", property)
		return 
	var v = gameProperties.get(property)
	if v.size() <= valueIndex:
		Logger.error("invalid gameProperties index", "Data.applyFromGamedata", {"property": property, "valueIndex": valueIndex})
		return 
	
	var oldValue = values.get(property, null)
	var newValue = v[valueIndex] + oldValue
	values[property] = newValue
	for l in listeners.get(property, []):
		l.propertyChanged(property, oldValue, newValue)

func applyFromGamedata(property: String, valueIndex: int):
	property = property.to_lower()
	if not gameProperties.has(property):
		Logger.error("data is missing", "Data.applyFromGamedata", property)
		return 
	var v = gameProperties.get(property)
	var oldValue = values.get(property, null)
	var newValue
	if v is Array:
		if v.size() <= valueIndex:
			Logger.error("invalid gameProperties index", "Data.applyFromGamedata", {"property": property, "valueIndex": valueIndex})
			return 
		newValue = v[valueIndex]
	else:
		newValue = v
	
	values[property] = newValue
	for l in listeners.get(property, []):
		l.propertyChanged(property, oldValue, newValue)

func apply(property: String, newValue):
	property = property.to_lower()
	var oldValue = values.get(property, null)
	
	values[property] = newValue
	var invalids: = []
	for l in listeners.get(property, []):
		if is_instance_valid(l):
			l.propertyChanged(property, oldValue, newValue)
		else:
			Logger.error("listener was freed without unlistening", "Data.apply", {"property": property})
			invalids.append(l)
	for i in invalids:
		listeners.erase(i)

func applyInitial(propertyClass: String):
	for g in gameProperties:
		if g.begins_with(propertyClass):
			applyFromGamedata(g, 0)







func listen(listener, property: String, immediateCallback: = false):
	print(listener.name + " listen for " + property)
	property = property.to_lower()
	var list: Array
	if listeners.has(property):
		list = listeners[property]
	else:
		list = []
		listeners[property] = list
	
	if list.has(listener):
		Logger.error("adding listener who is already listening", "Data.listen", {"listener": listener, "property": property})
		return 
	list.append(listener)
	if immediateCallback and values.has(property):
		listener.propertyChanged(property, null, of(property))


	if not listener.is_connected("tree_exited", self, "unlistenAll"):
		listener.connect("tree_exited", self, "unlistenAll", [listener])

func unlistenAll(listener):
	for prop in listeners:
		call_deferred("removeListener", listeners[prop], listener)

func unlisten(listener, property: String):
	print(listener.name + " unlisten for " + property)
	property = property.to_lower()
	var list: Array = listeners.get(property, [])
	if not list.has(listener):
		Logger.error("removing listener who is not listening", "Data.unlisten", {"listener": listener, "property": property})
		return 
	
	call_deferred("removeListener", list, listener)

func removeListener(list, listener):
	list.erase(listener)

func clearListeners():
	listeners.clear()

func keeper(property: String):
	return of(Level.keeper.techId + "." + property)

func getInventory(type: String):
	return of("inventory." + type)

func changeByInt(property: String, change):
	var newVal = change + ofOr(property, 0)
	apply(property, newVal)
	return newVal

func changeDomeHealth(amount: float):
	if GameWorld.domeHealthLocked:
		return 
	
	apply("dome.health", float(clamp(Data.of("dome.health") + amount, 0, Data.of("dome.maxHealth"))))

func domeScene(domeId: String):
	return load("res://content/dome/" + domeId + "/" + startCaptialized(domeId) + ".tscn")

func keeperScene(keeperId: String):
	return load("res://content/keeper/" + keeperId + "/" + startCaptialized(keeperId) + ".tscn")

func worldScene(worldId: String):
	return load("res://content/worlds/" + worldId + "/" + startCaptialized(worldId) + ".tscn")

func startCaptialized(s: String):
	return s.substr(0, 1).to_upper() + s.substr(1, s.length() - 1)

func serialize()->Dictionary:
	return values.duplicate()

func deserialize(data: Dictionary):
	
	for d in data:
		values[d] = data[d]

	
	for d in data:
		if d != "dome.healthfractionrepair":
			apply(d, data[d])

