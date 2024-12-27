extends Node

const SAVE_SLOT_FILE_TEMPLATE: = "user://savegame_%d.json"
const SAVE_TILE_FILE_TEMPLATE: = "user://savegame_%d_map.scn"
const SAVE_META_FILE_TEMPLATE: = "user://savegame_%s.json"
const SAVE_FILE_PASSWORD = "yaph!o0keu5iTei&"
const VERSION_STATE_FILE: = "user://version.txt"
const TUTORIAL_STATE_FILE: = "user://tutorials.txt"


const TILE_SIZE: = 24
const HALF_TILE_SIZE: = 12


var buildType: int
var devMode: bool
var devModeActivated: bool = false
var qaOptions: bool
var unlockAllButton: bool
var resetBetweenRuns: bool
var forceBattleAmbienceEnabled: bool
var runCheatDetection: bool = true


var tutorialStages: = {}
var playerInputMap: = [0]
var version: String
var lastVersion: String = ""
var worldId: String
var keeperSkinId: String = ""
var gameMode: String
var modeVariation: String
var difficulty: int
var worldModifiers: Array
var runCount: int
var lastDomeId: String
var lastKeeperId: String
var lastGadgetId: String
var lastGameModeId: String
var lastGameModeVariation: String
var lastMapSize: String
var lastPetId: String
var lastSkinIds: Dictionary
var lastWorldModifiers: Array
var lastAdditionalUpgradeLimits: Array
var lastWorldIds: Array
var lastLoadout: Loadout
var lastLeaderboardSection: String
var showMouse: = true
var gadgetToKeep: String
var keptGadgetUsed: = false
var aspectRatioYOffset: = 0


var lastViewedOptionsCategory: String
var lastFocussedTechId: String
var runStats: = {}
var runTime: float
var wavePresentTime: float
var travelledDistance: float
var paused: = false
var softPauseCached: = 0
var cachedTimeBetweenWaves: = 0.0
var won: = false
var lost: = false
var gameover: = false
var runStarted: = false
var goalCameraZoom: float
var currentLoadingSavegame: = false
var allow_saving: = true
var isHalloween: = false
var newSkinsToUnlock: = []
var runId: String

var leaderboardHandles: = {}


var domeHealthLocked: = false


var waveDelay: = 0.0
var waveStrengthModifier: = 1.0


var additionalRunWeight: = 0.0


var musicCountdown: int
var currentMusicIndex: int


var upgrades: = {}
var levelTechs: = []
var upgradeLimits: = []
var boughtUpgrades: = []
var lockedUpgrades: = []


var unlockedElements: = []
var unlockableElements: = []
var unlockedPets: = []
var unlockablePets: = []
var unlockedSkins: = {}

signal savegame_loaded

func _init():
	TranslationServer.set_locale("en_US")

func init()->void :
	loadMetaState()
	loadTutorialStages()
	
	match buildType:
		CONST.BUILD_TYPE.PLAYTEST:
			unlockEverything()
		CONST.BUILD_TYPE.FULL:
			pass
		CONST.BUILD_TYPE.EXHIBITION:
			unlockableElements.clear()
			unlockedElements.clear()
			unlockedElements.append("repellent")
			unlockedElements.append("shield")
			unlockedElements.append("orchard")
			unlockedElements.append("dome1")
			unlockedElements.append("keeper1")
			unlockedElements.append("relichunt")
		_:
			if not unlockedElements.has("repellent"):
				unlockableElements.append("repellent")
			if not unlockedElements.has("shield"):
				unlockableElements.append("shield")
			if not unlockedElements.has("dome2"):
				unlockableElements.append("dome2")
			if not unlockedElements.has("dome3"):
				unlockableElements.append("dome3")
			if not unlockedElements.has("keeper2"):
				unlockableElements.append("keeper2")
	
	if not unlockedElements.has(lastDomeId):
		lastDomeId = "dome1"
	if not unlockedElements.has(lastGadgetId):
		lastGadgetId = "shield"
	if not unlockedElements.has(lastKeeperId):
		lastKeeperId = "keeper1"
	if not unlockedElements.has(lastGameModeId):
		lastGameModeId = CONST.MODE_RELICHUNT
	
	updateSeasonalEvents()

func isUnlocked(id: String)->bool:
	return unlockedElements.has(id)

func unlockElement(id: String)->String:
	if isUnlocked(id):
		return ""
	else:
		unlockedElements.append(id)
		if unlockableElements.has(id):
			unlockableElements.erase(id)
		return id

func addUnlockableElementIfOk(id: String):
	if isUnlocked(id):
		return 
	if not unlockableElements.has(id):
		unlockableElements.append(id)

func prepareUnlockables():
	unlockableElements.clear()
	
	if lastDomeId == "dome1":
		addUnlockableElementIfOk("dome2")
	
	if lastKeeperId == "keeper1":
		addUnlockableElementIfOk("keeper2")
	
	if lastGameModeId == CONST.MODE_RELICHUNT:
		addUnlockableElementIfOk(CONST.MODE_PRESTIGE)
	elif lastGameModeId == CONST.MODE_PRESTIGE:
		var openModes: = []
		for mode in [CONST.MODE_PRESTIGE_COBALT, CONST.MODE_PRESTIGE_COUNTDOWN, CONST.MODE_PRESTIGE_MINER]:
			if not isUnlocked(mode):
				openModes.append(mode)
		if openModes.size() > 0:
			unlockableElements.append(openModes[randi() % openModes.size()])
	
	if lastGadgetId == "repellent":
		addUnlockableElementIfOk("orchard")
		if isUnlocked("repellent-battle2"):
			addUnlockableElementIfOk("repellent-battle3")
		else:
			addUnlockableElementIfOk("repellent-battle2")
	
	if lastGadgetId == "shield":
		addUnlockableElementIfOk("repellent")
		if isUnlocked("shield-battle2"):
			addUnlockableElementIfOk("shield-battle3")
		else:
			addUnlockableElementIfOk("shield-battle2")
	
	if lastGadgetId == "orchard":
		addUnlockableElementIfOk("orchard-battle2")

func handleVersionChange():
	var save = File.new()
	var err = save.open(VERSION_STATE_FILE, File.READ)
	if err == OK:
		lastVersion = save.get_as_text()
	save.close()
	
	if lastVersion != version:
		migrateVersions()
	else:
		Logger.info("no new version detected")

func migrateVersions():
	Logger.info("trying migration from version '" + lastVersion + "' to '" + version + "'")
	
	var save = File.new()
	var err = save.open(VERSION_STATE_FILE, File.WRITE)
	if err == OK:
		save.store_string(version)
	save.close()
	



	Options.remapInputEvent("keeper_pickup", "keeper1_pickup")
	Options.remapInputEvent("keeper_drop", "keeper1_drop")


func deleteMetaState():
	var dir = Directory.new()
	var saveFile = SAVE_META_FILE_TEMPLATE % CONST.BUILD_TYPE.keys()[buildType].to_lower()
	var err = dir.remove(saveFile)
	if err == 0:
		Logger.info("deleted savegame")
	else:
		Logger.info("failed to delete savegame")

func prepareCleanData():
	Data.reset()
	Data.apply("dome.health", 0)
	Data.apply("dome.baserepair", 0)
	Data.apply("dome.healthfractionrepair", 0)
	Data.apply("dome.meleedamageReduction", 0.0)
	Data.apply("dome.autohealdamagethreshold", 0.0)
	Data.apply("dome.autohealamount", 0.0)
	Data.apply("dome.potentialrepair", 0)

	Data.apply("monsters.wavepresent", false)
	Data.apply("monsters.wavebattle", false)
	Data.apply("monsters.cycle", 0)
	Data.apply("monsters.waveintervalProgression", 0)
	Data.apply("monstermodifiers.timebetweenwavesmodifier", 1.0)
	Data.apply("monstermodifiers.cyclesrunweightmodifier", 1.0)

	Data.apply("map.remainingrelicswitches", 0)
	Data.apply("map.revealdistance", 1)

	Data.apply("game.over", "")
	
	Data.apply("inventory.iron", 0)
	Data.apply("inventory.water", 0)
	Data.apply("inventory.sand", 0)
	Data.apply("inventory.gadget", 0)
	Data.apply("inventory.relic", 0)
	Data.apply("inventory.rest", 0)
	Data.apply("inventory.floatingIron", 0)
	Data.apply("inventory.floatingWater", 0)
	Data.apply("inventory.floatingSand", 0)
	Data.apply("inventory.floatinggadget", 0)
	Data.apply("inventory.floatingrelic", 0)
	Data.apply("inventory.floatingegg", 0)
	Data.apply("inventory.floatingrest", 0)
	Data.apply("inventory.totalIron", 0)
	Data.apply("inventory.totalWater", 0)
	Data.apply("inventory.totalSand", 0)
	Data.apply("inventory.totalgadget", 0)
	Data.apply("inventory.totalrelic", 0)
	Data.apply("inventory.totalegg", 0)
	Data.apply("inventory.totalrest", 0)
	
	Data.apply("keeper.insidedome", true)
	Data.apply("keeper.insidestation", false)
	Data.apply("keeper.additionalmaxspeed", 0.0)
	Data.apply("keeper.additionalupwardsspeed", 0.0)
	Data.apply("keeper.speedbuff", 0.0)
	Data.apply("keeper.drillbuff", 0.0)
	Data.apply("keeper.zoominmine", 4)
	
	runStats.clear()
	worldModifiers.clear()
	
	boughtUpgrades.clear()
	levelTechs.clear()
	lockedUpgrades.clear()
	if resetBetweenRuns:
		resetTutorials()
	upgradeLimits.clear()
	upgrades.clear()
	newSkinsToUnlock.clear()
	
	won = false
	lost = false
	gameover = false
	runStarted = false
	paused = false
	domeHealthLocked = false
	allow_saving = true
	musicCountdown = 1
	goalCameraZoom = 4
	runTime = 0.0
	wavePresentTime = 0.0
	travelledDistance = 0.0
	waveStrengthModifier = 1.0
	waveDelay = 0.0
	modeVariation = ""
	
	unlockablePets = ["pet1", "pet2"]
	if isHalloween:
		unlockablePets.append("pet4")
	for p in unlockedPets:
		unlockablePets.erase(p)

func updateSeasonalEvents():
	if not Options.enableSeasonalContent:
		isHalloween = false
		return 
	
	var date = OS.get_date()
	isHalloween = (date["month"] == 10 and date["day"] >= 22) or (date["month"] == 11 and date["day"] <= 13)

func levelInitialized():
	Data.apply("dome.health", Data.of("dome.maxHealth"))
	
	setGameMode(gameMode)
	
	if GameWorld.devMode:
		Data.apply("inventory.iron", 90)
		Data.apply("inventory.water", 30)
		Data.apply("inventory.sand", 10)
	
	buildRunSpecificUpgrades()

func buildRunSpecificUpgrades():
	for u in unlockedElements:
		if u.find("-battle") != - 1 and not upgradeLimits.has(u):
			upgradeLimits.append(u)
	
	upgrades.clear()
	
	for uk in Data.upgrades:
		var upgrade = Data.upgrades[uk]
		if isUpgradeLimited(upgrade):
			
			continue
		
		if upgrade["tier"] == 0\
		 and Data.gadgets.has(uk)\
		 and not Data.gadgets[uk].has("distribution")\
		 and not (uk in GameWorld.boughtUpgrades or uk in GameWorld.levelTechs):
			
			continue
		
		
		var duplicatedUpgrade = upgrade.duplicate(true)
		if upgrade.has("repeatable"):
			var dup: = []
			for repeatable in upgrade.get("repeatable"):
				dup.append(repeatable.duplicate())
			duplicatedUpgrade["repeatable"] = dup
		if upgrade.has("propertychanges"):
			var dup: = []
			for propertychange in upgrade.get("propertychanges"):
				dup.append(propertychange.duplicate())
			duplicatedUpgrade["propertychanges"] = dup
		if upgrade.has("cost"):
			var dupCost: = {}
			var costs = upgrade.get("cost")
			for res in costs:
				dupCost[res] = costs[res] * Data.ofOr("upgrademodifiers.cost." + res, 1.0)
			duplicatedUpgrade["cost"] = dupCost
		upgrades[uk] = duplicatedUpgrade
	
	for uk in upgrades.duplicate():
		if upgrades[uk].has("predecessors"):
			var predecessors = upgrades[uk].get("predecessors")
			for p in predecessors.duplicate():
				if not upgrades.has(p):
					
					predecessors.erase(p)
			if predecessors.size() == 0 and upgrades[uk]["tier"] > 0:
				
				upgrades.erase(uk)
	
	prepareUnlockables()

func nextUnlock(id: String):
	match id:
		"world1":
			return "world2"
		"world2":
			return "world3"
		"world3":
			return "world4"
		"world4":
			return "world5"
		CONST.MAP_SMALL:
			return CONST.MAP_MEDIUM
		CONST.MAP_MEDIUM:
			return CONST.MAP_LARGE
		CONST.MAP_LARGE:
			return CONST.MAP_HUGE
		_:
			return null

func makeUpgradesAvailable(gadgetId: String):
	if upgrades.has(gadgetId):
		return 
	
	upgrades[gadgetId] = Data.upgrades[gadgetId].duplicate()
	
	var newUpgrades: = {}
	for uk in Data.upgrades:
		if upgrades.has(uk):
			continue
		
		var upgrade = Data.upgrades[uk]
		if isUpgradeLimited(upgrade):
			
			continue
		
		newUpgrades[uk] = upgrade.duplicate(true)
	
	for uk in newUpgrades:
		if newUpgrades[uk].has("predecessors"):
			var predecessors = newUpgrades[uk].get("predecessors")
			for p in predecessors.duplicate():
				if not upgrades.has(p) and not newUpgrades.has(p):
					
					print("erasing " + p + " from predecessors " + uk)
					predecessors.erase(p)
			if predecessors.size() == 0:
				
				newUpgrades.erase(uk)
	
	for uk in newUpgrades:
		upgrades[uk] = newUpgrades[uk]

func unlockEverything():
	GameWorld.unlockElement("keeper1")
	GameWorld.unlockElement("keeper2")
	GameWorld.unlockElement("dome1")
	GameWorld.unlockElement("dome2")
	GameWorld.unlockElement("repellent")
	GameWorld.unlockElement("repellent-battle2")
	GameWorld.unlockElement("repellent-battle3")
	GameWorld.unlockElement("orchard")
	GameWorld.unlockElement("orchard-battle2")
	GameWorld.unlockElement("shield")
	GameWorld.unlockElement("shield-battle2")
	GameWorld.unlockElement("shield-battle3")
	GameWorld.unlockElement("world1")
	GameWorld.unlockElement("world2")
	GameWorld.unlockElement("world3")
	GameWorld.unlockElement("world4")
	GameWorld.unlockElement("world5")
	GameWorld.unlockElement(CONST.MODE_RELICHUNT)
	GameWorld.unlockElement(CONST.MODE_PRESTIGE)
	GameWorld.unlockElement(CONST.MODE_PRESTIGE_COBALT)
	GameWorld.unlockElement(CONST.MODE_PRESTIGE_COUNTDOWN)
	GameWorld.unlockElement(CONST.MAP_MEDIUM)
	GameWorld.unlockElement(CONST.MAP_LARGE)
	GameWorld.unlockElement(CONST.MAP_HUGE)
	GameWorld.unlockElement(CONST.DIFFICULTY_YAFI)
	GameWorld.unlockElement("world-modifiers")
	
	GameWorld.unlockedSkins["keeper1"] = ["skin1", "skin2", "skin3"]
	GameWorld.unlockedPets = ["pet1", "pet2", "pet3", "pet4"]

func _process(delta: float)->void :
	if Level.stage and not paused:
		runTime += delta
		if Data.of("monsters.wavepresent"):
			wavePresentTime += delta
	softPauseCached = - 1
	cachedTimeBetweenWaves = - 1.0

func startLevel(loadout: Loadout):
	lastLoadout = loadout
	
	prepareCleanData()
	
	
	
	gameMode = loadout.gameMode
	loadout.modeVariant = GameWorld.lastGameModeVariation
	GameWorld.modeVariation = GameWorld.lastGameModeVariation
	
	match loadout.gameMode:
		CONST.MODE_RELICHUNT:
			setUpgradeLimitAvailable("hostile")
			setUpgradeLimitAvailable("cobaltgeneration")
			if not loadout.mapArchetype:
				match lastMapSize:
					CONST.MAP_SMALL:
						loadout.mapArchetype = preload("res://content/map/generation/archetypes/regular-small.res").duplicate()
					CONST.MAP_MEDIUM:
						loadout.mapArchetype = preload("res://content/map/generation/archetypes/regular-medium.res").duplicate()
					CONST.MAP_LARGE:
						loadout.mapArchetype = preload("res://content/map/generation/archetypes/regular-large.res").duplicate()
					CONST.MAP_HUGE:
						loadout.mapArchetype = preload("res://content/map/generation/archetypes/regular-huge.res").duplicate()
					_:
						loadout.mapArchetype = preload("res://content/map/generation/archetypes/regular-medium.res").duplicate()
			if not worldId or worldId == "none":
				worldId = "world1"
			else:
				var worlds: = ["world1", "world2", "world3", "world4", "world5"]
				for w in worlds.duplicate():
					if not GameWorld.isUnlocked(w):
						worlds.erase(w)
				if worlds.size() > 1:
					if worlds.size() > GameWorld.lastWorldIds.size():
						for w in GameWorld.lastWorldIds:
							worlds.erase(w)
					else:
						var lastWorld = GameWorld.lastWorldIds.back()
						GameWorld.lastWorldIds.clear()
						GameWorld.lastWorldIds.append(lastWorld)
						worlds.erase(lastWorld)
				worldId = worlds[randi() % worlds.size()]
				GameWorld.lastWorldIds.append(worldId)
		CONST.MODE_PRESTIGE:
			if GameWorld.modeVariation != CONST.MODE_PRESTIGE_MINER:
				setUpgradeLimitAvailable("hostile")
			
			if GameWorld.modeVariation == CONST.MODE_PRESTIGE_COBALT:
				Data.apply("inventory.sand", 10)
				setUpgradeLimitAvailable("nocobalt")
			else:
				setUpgradeLimitAvailable("cobaltgeneration")
			
			if not loadout.mapArchetype:
				loadout.mapArchetype = preload("res://content/map/generation/archetypes/prestige-10k.res").duplicate()
				if not isUpgradeLimitAvailable("cobaltgeneration"):
					loadout.mapArchetype.cobalt_rate = 0.0
			
			worldId = "world6"
		CONST.MODE_COLONIZATION:
			if not loadout.mapArchetype:
				loadout.mapArchetype = preload("res://content/map/generation/archetypes/regular-small.res").duplicate()
				loadout.mapArchetype.cobalt_rate = 0.0
	
	if loadout.worldId:
		worldId = loadout.worldId
	
	lastLoadout.worldId = worldId
	loadout.worldScene = Data.worldScene(worldId).instance()
	var worldIndex = int(worldId.substr(5))
	loadout.worldScene.worldIndex = worldIndex
	
	if loadout.palette == "":
		loadout.palette = str(worldIndex) + "_" + str(loadout.worldScene.allowedPalettes[randi() % loadout.worldScene.allowedPalettes.size()])
	
	
	for limit in lastAdditionalUpgradeLimits:
		setUpgradeLimitAvailable(limit)
	
	lastWorldModifiers = loadout.worldModifiers.duplicate()
	print("world modifiers: " + str(loadout.worldModifiers))
	worldModifiers = loadout.worldModifiers
	for modifierId in worldModifiers:
		var modifier = Data.worldModifiers[modifierId]
		for propertyChange in modifier.get("propertychanges", {}):
			if loadout.mapArchetype and propertyChange.keyClass == "archetype":
				var oldValue = loadout.mapArchetype.get(propertyChange.keyName)
				var newValue = propertyChange.applyValue(oldValue)
				loadout.mapArchetype.set(propertyChange.keyName, newValue)
			else:
				Data.apply(propertyChange.key, propertyChange.value)
	
	runCount += 1
	loadout.cleanStatePrepared = true
	
	persistMetaState()
	
	runId = UUID.v4()
	Backend.event("run_started", {
		"gameMode": loadout.gameMode, 
		"modeVariation": modeVariation, 
		"domeId": loadout.domeId, 
		"keeperId": loadout.keeperId, 
		"worldId": worldId, 
		"palette": loadout.palette, 
		"primaryGadgetId": loadout.primaryGadgetId, 
		"worldModifiers": loadout.worldModifiers, 
		"difficulty": difficulty, 
		"mapSize": lastMapSize, 
		"keeperSkinId": keeperSkinId, 
		"runCount": runCount, 
		"unlockedElements": unlockedElements, 
		"runId": runId, 
	})

func buyUpgrade(id: String):
	var upgrade = GameWorld.upgrades.get(id)
	Backend.event("upgrade", {"id": id})
	var cost = upgrade.get("cost", {})
	for costType in cost:
		Data.changeByInt("inventory." + costType, - cost[costType])
	unlockUpgrade(id)

func unlockUpgrade(id: String, applyRepeatable: = true):
	var upgrade = GameWorld.upgrades.get(id)
	
	for l in upgrade.get("locks", []):
		lockUpgrade(l)
	
	if upgrade.has("hud"):
		Level.hud.addHudElement(upgrade)
	
	if upgrade.has("special"):
		match id:
			"doublelaser":
				Level.dome.addWeapon()
	
	if applyRepeatable:
		for propertyChange in upgrade.get("propertychanges", []):
			Data.applyPropertyChange(propertyChange)
		
		if upgrade.has("repeatable"):
			for change in upgrade.get("repeatable"):
				match change.keyClass:
					"cost":
						var oldValue = upgrade["cost"].get(change.keyName, 0)
						var newValue = round(change.applyValue(oldValue))
						upgrade["cost"][change.keyName] = newValue
					"property":
						for p in upgrade["propertychanges"]:
							if change.keyName == p.key:
	
								var newValue = change.applyValue(p.value)
								if typeof(p.value) == TYPE_INT:
									p.value = round(newValue)
	
								else:
									p.value = newValue
	
	
	if not boughtUpgrades.has(id):
		boughtUpgrades.append(id)
	
	for uk in GameWorld.upgrades:
		upgrade = GameWorld.upgrades.get(uk)
		if not upgrade.has("repeatable"):
			continue
		if upgrade.get("predecessors", []).has(id):
			if not boughtUpgrades.has(uk):
				boughtUpgrades.append(uk)

func unlockLevelTech(id: String):
	levelTechs.append(id)
	boughtUpgrades.append(id)
	Data.unlockGadget(id)
	var upgrade = Data.gadgets.get(id, {})
	if upgrade.has("hud"):
		Level.hud.addHudElement(upgrade)
	setUpgradeLimitAvailable(id)

func lockUpgrade(uk):

	lockedUpgrades.append(uk)
	var lockedSomething: = true
	while lockedSomething:
		lockedSomething = false
		for u in GameWorld.upgrades:
			if u in boughtUpgrades or u in lockedUpgrades:
				continue
			
			if GameWorld.upgrades[u].has("predecessors"):
				var t = GameWorld.upgrades[u].get("predecessors")
				if lockedUpgrades.has(t):
					lockedUpgrades.append(u)
					lockedSomething = true


func generateGadgets()->Array:
	var offer: = []
	
	var weights: = []
	var availableGadgets = availableGadgets()
	
	var artifactsRecovered = Data.of("inventory.gadget") - 1
	for g in availableGadgets:
		var data = Data.gadgets[g]
		if Level.dome.availableSlots.has(data.get("slot")) and data.distribution.size() > artifactsRecovered:
			var probability = data.distribution[min(artifactsRecovered, data.distribution.size() - 1)]
			weights.append(probability)
		else:
			weights.append(0)
	
	var found: = true
	while offer.size() < Data.of("artifacts.gadgetChoicesPerArtifact") and found:
		found = false
		var sum: = 0.0
		for w in weights:
			sum += w
		
		if sum == 0.0:
			break
		
		var pick = randf() * sum
		var run: = 0.0
		for i in range(0, weights.size()):
			run += weights[i]
			if run >= pick:
				offer.append(Data.gadgets[availableGadgets[i]])
				found = true
				weights[i] = 0.0
				break
	
	var offeredGadgetIds: = []
	for o in offer:
		offeredGadgetIds.append(o.get("id"))
	Backend.event("gadgets", {"status": "offered", "gadgets": offeredGadgetIds})
	
	return offer

func unlockGadget(id: String):
	Backend.event("gadgets", {"status": "unlocked", "gadget": id})
	if not boughtUpgrades.has(id):
		boughtUpgrades.append(id)
	makeUpgradesAvailable(id)
	Data.changeByInt("inventory.gadget", 1)

func availableGadgets()->Array:
	var availableGadgets: = []
	for gk in Data.gadgets:
		var data = Data.gadgets[gk]
		if isUpgradeLimited(data):
			continue
		
		if data.has("distribution") and not boughtUpgrades.has(gk):
			availableGadgets.append(gk)
	return availableGadgets

func availableUpgrades()->Array:
	var up: = []
	for uk in GameWorld.upgrades:
		if boughtUpgrades.has(uk):
			continue
		if lockedUpgrades.has(uk):
			continue
		var upgrade = GameWorld.upgrades[uk]
		var req = upgrade.get("predecessors", [])
		var boughtPredecessors: = true
		for techId in upgrade.get("predecessors", []):
			if not boughtUpgrades.has(req):
				boughtPredecessors = false
				break
		if boughtPredecessors:
			up.append(upgrade)
	return up

func handleGameWon(backendData: Dictionary = {}):
	if gameover:
		return 
	
	delete_autosave()
	backendData["waveIndex"] = Data.of("monsters.cycle")
	backendData["runTime"] = runTime
	backendData["wavePresentTime"] = wavePresentTime
	backendData["runWeight"] = Level.mode.getRunWeight()
	backendData["status"] = "won"
	backendData["runId"] = runId
	Backend.event("run_finished", backendData)
	Backend.sendBufferedEvents()
	won = true
	gameover = true
	Data.apply("game.over", "won")
	Backend.enableMetrics = false
	
	Achievements.incrementStat("run_wins")

func handleGameLost(backendData: Dictionary = {}):
	if won:
		
		return 
	
	delete_autosave()
	backendData["waveIndex"] = Data.of("monsters.cycle")
	backendData["runTime"] = runTime
	backendData["wavePresentTime"] = wavePresentTime
	backendData["runWeight"] = Level.mode.getRunWeight()
	backendData["status"] = "lost"
	backendData["runId"] = runId
	Backend.event("run_finished", backendData)
	Backend.sendBufferedEvents()
	lost = true
	gameover = true
	Data.apply("game.over", "lost")
	get_tree().call_group("lostL", "onGameLost")
	
	Achievements.incrementStat("run_losses")

func unlockSkin(keeperId: String, skinId: String):
	var skins = unlockedSkins.get(keeperId, [])
	if not skins.has(skinId):
		skins.append(skinId)
	unlockedSkins[keeperId] = skins

func loadMetaState():
	var metastate: = {}
	if not resetBetweenRuns:
		var save = File.new()
		var saveFile = SAVE_META_FILE_TEMPLATE % CONST.BUILD_TYPE.keys()[buildType].to_lower()
		var err = save.open_encrypted_with_pass(saveFile, File.READ, SAVE_FILE_PASSWORD)
		if err != OK:
			
			err = save.open(saveFile, File.READ)
		if err == OK:
			var i = save.get_as_text()
			var parsed = JSON.parse(i)
			if parsed.result:
				metastate = parsed.result
		save.close()
	
	currentMusicIndex = metastate.get("currentMusicIndex", 0)
	difficulty = metastate.get("difficulty", - 2)
	lastDomeId = metastate.get("lastDomeId", "dome1")
	lastKeeperId = metastate.get("lastKeeperId", "keeper1")
	lastGadgetId = metastate.get("lastGadgetId", "orchard")
	lastWorldIds = metastate.get("lastWorldIds", [])
	lastGameModeId = metastate.get("lastGameModeId", CONST.MODE_RELICHUNT)
	lastGameModeVariation = metastate.get("lastGameModeVariation", "")
	modeVariation = metastate.get("modeVariation", "")
	lastMapSize = metastate.get("lastMapSize", CONST.MAP_SMALL)
	lastLeaderboardSection = metastate.get("lastLeaderboardSection", "friends")
	lastPetId = metastate.get("lastPetId", "pet0")
	lastSkinIds = metastate.get("lastSkinIds", {})
	lastWorldModifiers = metastate.get("lastWorldModifiers", [])
	lastAdditionalUpgradeLimits = metastate.get("lastAdditionalUpgradeLimits", [])
	runCount = metastate.get("runCount", 0)
	worldId = metastate.get("worldId", "none")
	unlockedElements = metastate.get("unlockedElements", ["dome1", "keeper1", "shield", CONST.MODE_RELICHUNT, "world1", "map-small"])
	gadgetToKeep = metastate.get("gadgetToKeep", "")
	keptGadgetUsed = metastate.get("keptGadgetUsed", false)
	unlockedPets = metastate.get("unlockedPets", [])
	unlockedSkins = metastate.get("unlockedSkins", {})
	
	




	
	var pioneerPack = SteamGlobal.Steam.isSubscribedApp(2152440)
	Logger.info("Pioneer pack subscription: " + str(pioneerPack))
	if pioneerPack:
		if not unlockedPets.has("pet3"):
			unlockedPets.append("pet3")
		unlockSkin("keeper1", "skin1")
	else:
		if unlockedPets.has("pet3"):
			unlockablePets.erase("pet3")
		var skins = unlockedSkins.get("keeper1", [])
		if skins.has("skin1"):
			skins.erase("skin1")


func persistMetaState():
	var save = File.new()
	var saveFile = SAVE_META_FILE_TEMPLATE % CONST.BUILD_TYPE.keys()[buildType].to_lower()
	var err = save.open_encrypted_with_pass(saveFile, File.WRITE, SAVE_FILE_PASSWORD)
	if err == 0:
		var metastate: = {}
		metastate["runCount"] = runCount
		metastate["worldId"] = worldId
		metastate["currentMusicIndex"] = currentMusicIndex
		metastate["lastWorldModifiers"] = lastWorldModifiers
		metastate["lastAdditionalUpgradeLimits"] = lastAdditionalUpgradeLimits
		metastate["unlockedElements"] = unlockedElements
		metastate["unlockedPets"] = unlockedPets
		metastate["unlockedSkins"] = unlockedSkins
		metastate["gadgetToKeep"] = gadgetToKeep
		metastate["modeVariation"] = modeVariation
		metastate["lastLeaderboardSection"] = lastLeaderboardSection
		if lastDomeId:
			metastate["difficulty"] = difficulty
			metastate["lastDomeId"] = lastDomeId
			metastate["lastGadgetId"] = lastGadgetId
			metastate["lastKeeperId"] = lastKeeperId
			metastate["lastGameModeId"] = lastGameModeId
			metastate["lastGameModeVariation"] = lastGameModeVariation
			metastate["lastMapSize"] = lastMapSize
			metastate["lastWorldIds"] = lastWorldIds
			metastate["lastPetId"] = lastPetId
			metastate["lastSkinIds"] = lastSkinIds
			metastate["keptGadgetUsed"] = keptGadgetUsed
		save.store_string(JSON.print(metastate))
		save.close()
	else:
		Logger.error("GameWorld.persistMetaState", "Failed to save meta state with error code " + str(err))

func loadTutorialStages()->void :
	var save: = File.new()
	var err: = save.open(TUTORIAL_STATE_FILE, File.READ)
	if err == OK:
		var i = save.get_as_text()
		var parsed = JSON.parse(i)
		if parsed.result:
			tutorialStages = parsed.result
	save.close()

func resetTutorials():
	tutorialStages.clear()
	persistTutorialStages()


func persistTutorialStages():
	var save = File.new()
	var err = save.open(TUTORIAL_STATE_FILE, File.WRITE)
	if err == 0:
		save.store_string(JSON.print(tutorialStages))
		save.close()
	else:
		Logger.error("GameWorld.persistTutorialStages", "Failed to save tutorials file with error code " + str(err))

func iconify(text: String)->String:
	var regex = RegEx.new()
	regex.compile("\\[(.*?)\\]")
	var result = regex.sub(text, "[img]res://content/icons/icon_$1.png[/img]", true)
	return result

func pause():
	if paused:
		return 
	paused = true
	get_tree().call_group("pauseL", "pauseChanged")


func unpause():
	if not paused:
		return 
	paused = false
	get_tree().call_group("pauseL", "pauseChanged")


func softPaused()->bool:
	if softPauseCached == - 1:
		softPauseCached = int(paused or gameover or Data.of("monsters.wavebattle"))
	return bool(softPauseCached)

func serialize_saveable(object):
	var data = {}
	if object.has_method("serialize"):
		data = object.serialize()
	data["meta.name"] = object.name
	data["meta.filename"] = object.filename
	data["meta.path"] = object.get_path()
	data["meta.parent"] = object.get_parent().name
	if data.get("meta.kind") != "station":
		data["meta.position"] = var2str(object.global_position)
		data["meta.rotation"] = object.global_rotation
	return data

func deserialize_saveable(object, data):
	if data.has("meta.position"):
		object.global_position = str2var(data["meta.position"])
	if data.has("meta.rotation"):
		object.global_rotation = data["meta.rotation"]
	if object.has_method("deserialize"):
		object.deserialize(data)


func saveGame(slot: int = 0):
	if not allow_saving:
		Logger.info("not saving game as saving is not allowed")
		return 
	
	var saveFile: = SAVE_SLOT_FILE_TEMPLATE % slot

	var f: = File.new()
	var err: = f.open_encrypted_with_pass(saveFile, File.WRITE, SAVE_FILE_PASSWORD)
	if err != OK:
		Logger.error("failed to open encrypted save file", "GameWorld.saveGame", {"error": err, "file": saveFile})
		return err

	
	var objects = {}
	for o in get_tree().get_nodes_in_group("saveable"):
		if o.has_method("serialize"):
			var data: Dictionary = serialize_saveable(o)
			var priority = data["meta.priority"]
			if not objects.has(priority):
				objects[priority] = []
			objects[priority].append(data)

	
	var saveData = {
		"version": 2, 
		"Loadout": GameWorld.lastLoadout.serialize(), 
		"Keeper": {"position": var2str(Level.keeper.global_position)}, 
		"Monsters": Level.monsters.serialize(), 
		"Objects": objects, 
		"Upgrades": var2str(upgrades.duplicate()), 
		"RunStats": runStats, 
		"LevelTechs": levelTechs, 
		"UpgradeLimits": upgradeLimits, 
		"BoughtUpgrades": boughtUpgrades, 
		"LockedUpgrades": lockedUpgrades, 
		"UnlockedElements": unlockedElements, 
		"UnlockableElements": unlockableElements, 
		"unlockablePets": unlockablePets, 
		"WaveDelay": waveDelay, 
		"WaveStrengthModifier": waveStrengthModifier, 
		"RunStarted": runStarted, 
		"RunTime": runTime, 
		"wavePresentTime": wavePresentTime, 
		"TravelledDistance": travelledDistance, 
		"devModeActivated": devModeActivated, 
		"newSkinsToUnlock": newSkinsToUnlock, 
		"keeperSkinId": keeperSkinId, 
		"goalCameraZoom": goalCameraZoom, 
		"Data": Data.serialize(), 
		"Map": Level.map.serialize(), 
		"runId": runId, 
	}

	var json_data = to_json(saveData)
	f.store_string(json_data)
	f.close()
	Logger.info("saved game state for save " + str(slot))

	
	var packedTileData = Level.map.tileData().pack()
	var tileDataFile = SAVE_TILE_FILE_TEMPLATE % slot
	err = ResourceSaver.save(tileDataFile, packedTileData)
	if err != OK:
		Logger.error("failed to save tiledata", "GameWorld.saveGame", {"error": err, "file": tileDataFile})
		return err
	Logger.info("saved map state for save " + str(slot))
	return OK


func loadGame(slot: int = 0):
	if currentLoadingSavegame:
		return 
	
	currentLoadingSavegame = true
	var saveData: = {}
	var saveFile: = SAVE_SLOT_FILE_TEMPLATE % slot
	
	var f: = File.new()
	if f.file_exists(saveFile):
		var err: = f.open_encrypted_with_pass(saveFile, File.READ, SAVE_FILE_PASSWORD)
		if err != OK:
			
			err = f.open(saveFile, File.READ)
			if err != OK:
				Logger.error("failed to load savegame", "GameWorld.loadGame", slot)
				currentLoadingSavegame = false
				return 
			
		saveData = parse_json(f.get_as_text())
		
		f.close()
		
	if not saveData.has("version"):
		Logger.error("savegame does not contain a version", "GameWorld.loadGame", saveData)
		currentLoadingSavegame = false
		return 
		
	var domeId = saveData["Loadout"]["domeId"]
	var gadgetId = saveData["Loadout"]["primaryGadgetId"]
	var keeperId = saveData["Loadout"]["keeperId"]
	var modeId = saveData["Loadout"]["gameMode"]
	keeperSkinId = saveData.get("keeperSkinId", lastSkinIds.get(keeperId, "skin0"))
	var loadout = Loadout.new(domeId, gadgetId, keeperId, modeId)
	if saveData["Loadout"]["worldId"]:
		loadout.fixedWorld(saveData["Loadout"]["worldId"])
	if saveData["Loadout"]["palette"]:
		loadout.fixedPalette(saveData["Loadout"]["palette"])
	if saveData["Loadout"]["mapId"]:
		loadout.fixedMap(saveData["Loadout"]["mapId"])
	loadout.modeVariant = saveData["Loadout"].get("modeVariant", "")
	GameWorld.modeVariation = loadout.modeVariant
	GameWorld.goalCameraZoom = saveData.get("goalCameraZoom", 4)
	
	loadout.mapId = saveData["Loadout"]["mapId"]
	loadout.savegame = true

	StageManager.startStage("stages/landing/landing", [loadout])
	yield (StageManager, "stage_started")
	yield (StageManager, "stage_started")

	newSkinsToUnlock = saveData.get("newSkinsToUnlock", [])
	if saveData.has("unlockablePets"):
		unlockablePets = saveData.get("unlockablePets")
	
	
	
	
	if saveData.has("Data"):
		Data.deserialize(saveData["Data"])
	
	if saveData.has("Map"):
		var filecheck = File.new()
		var tileDataFileName = SAVE_TILE_FILE_TEMPLATE % slot
		if filecheck.file_exists(tileDataFileName):
			var tileData = ResourceLoader.load(tileDataFileName)
			Level.map.setTileData(tileData.instance())
		else:
			Logger.error("cannot load tile data for save, file is missing", "GameWorld.loadGame", tileDataFileName)
			currentLoadingSavegame = false
			return 
		Level.map.deserialize(saveData["Map"])

	if saveData.has("Keeper"):
		Level.keeper.global_position = str2var(saveData["Keeper"]["position"])
		Level.stage.find_node("Camera2D").global_position = Level.keeper.global_position
	
	if saveData.has("Monsters"):
		Level.monsters.deserialize(saveData["Monsters"])

	if saveData.has("Upgrades"):
		upgrades = str2var(saveData["Upgrades"])



	
	if saveData.has("RunStats"):
		runStats = saveData["RunStats"]
	
	if saveData.has("LevelTechs"):
		levelTechs = saveData["LevelTechs"]

	if saveData.has("UpgradeLimits"):
		upgradeLimits = saveData["UpgradeLimits"]

	if saveData.has("UpgradeLimits"):
		upgradeLimits = saveData["UpgradeLimits"]

	if saveData.has("UnlockedElements"):
		unlockedElements = saveData["UnlockedElements"]

	if saveData.has("UnlockableElements"):
		unlockableElements = saveData["UnlockableElements"]
	
	devModeActivated = saveData.get("devModeActivated", false)

	if saveData.has("BoughtUpgrades"):
		for upgrade in saveData["BoughtUpgrades"]:
			if levelTechs.has(upgrade):
				continue
			if boughtUpgrades.has(upgrade):
				continue
			if Data.upgrades.get(upgrade):
				unlockUpgrade(upgrade, false)
			if Data.gadgets.get(upgrade):
				Level.stage.applyGadget(upgrade)

	waveDelay = saveData.get("WaveDelay", 0.0)
	waveStrengthModifier = saveData.get("WaveStrengthModifier", 0.0)
	runStarted = saveData.get("RunStarted", true)
	runTime = saveData.get("RunTime", 0.0)
	wavePresentTime = saveData.get("wavePresentTime", 0.0)
	travelledDistance = saveData.get("TravelledDistance", 0.0)

	
	if saveData.has("Objects"):
		var sorted_priority = saveData["Objects"].keys()
		sorted_priority.sort()
		for priority in sorted_priority:
			for d in saveData["Objects"][priority]:
				match d["meta.kind"]:
					"chamber":
						var chamberScene
						if d.has("meta.scenepath"):
							chamberScene = load(d["meta.scenepath"])
						else:
							chamberScene = Level.map.getSceneForTileType(d["meta.chamberType"])
						var chamber = Level.map.addChamber(str2var(d["coord"]), chamberScene)
						deserialize_saveable(chamber, d)
					"cave":
						var cave = load(d["meta.filename"]).instance()
						deserialize_saveable(cave, d)
					"station":
						var path: String = d["meta.path"]
						path = path.substr(0, path.find("LevelStage")) + "LevelStage"
						var parent = get_node_or_null(path)
						var o
						if parent:
							o = parent.find_node(d["meta.name"], true, false)
						if o:
							deserialize_saveable(o, d)
						else:
							print("WARNING: Station not loaded %s" % path)
			
					"generic":
						var o = load(d["meta.filename"]).instance()
						match d["meta.parent"]:
							"Map":
								Level.map.add_child(o)
							"Tiles":
								Level.map.find_node("Tiles").add_child(o)
							"Dome":
								Level.dome.add_child(o)
							_:
								print("WARNING: Generic not loaded %s" % d["meta.path"])
						deserialize_saveable(o, d)
					
					_:
						print("WARNING: Unknown kind of object %s" % d["meta.path"])
	
	runId = saveData.get("runId", UUID.v4())
	
	
	
	if saveData.has("Data"):
		Data.deserialize(saveData["Data"])
	
	
	
	yield (get_tree(), "idle_frame")
	emit_signal("savegame_loaded")
	
	
	Data.apply("keeper.insidestation", false)
	currentLoadingSavegame = false
	
	
	Data.apply("dome.potentialrepair", 0)
	
	CheatDetection.resetIfRunning()
	GameWorld.runStarted = true
	Backend.event("run_continued", {"runId": runId})


func has_autosave()->bool:
	var saveFile: = SAVE_SLOT_FILE_TEMPLATE % 0
	var d: = Directory.new()
	return d.file_exists(saveFile)


func delete_autosave()->void :
	var saveFile: = SAVE_SLOT_FILE_TEMPLATE % 0
	var d: = Directory.new()
	if d.file_exists(saveFile):
		d.remove(saveFile)
	saveFile = SAVE_TILE_FILE_TEMPLATE % 0
	if d.file_exists(saveFile):
		d.remove(saveFile)

func incrementRunStat(type: String):
	runStats[type] = 1 + runStats.get(type, 0)

func setUpgradeLimitAvailable(limit: String):
	if upgradeLimits.has(limit):
		Logger.error("trying to add a tech limit that's already available", "GameWorld.setUpgradeLimitAvailable", limit)
		return 
	upgradeLimits.append(limit)

func isUpgradeLimitAvailable(limit: String)->bool:
	return upgradeLimits.has(limit)

func isUpgradeLimited(upgrade: Dictionary)->bool:
	if upgrade.has("limit"):
		for limit in upgrade["limit"]:
			if not upgradeLimits.has(limit):
				return true
	return false

func setGameMode(mode: String):
	gameMode = mode
	
	
	for uk in Data.upgrades:
		for pd in Data.upgrades[uk].get("predecessors", []):
			if pd == mode:
				unlockLevelTech(mode)
				return 

func setShowMouse(should: bool):
	showMouse = should
	if showMouse and not Options.useGamepad:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)

func getTimeBetweenWaves()->float:
	if cachedTimeBetweenWaves == - 1.0:
		cachedTimeBetweenWaves = Data.of("monsters.waveinterval")\
		 + Data.of("monsters.waveintervalProgression") * Level.map.getProgress()\
		 - max(0, GameWorld.difficulty * 12)
		cachedTimeBetweenWaves *= Data.of("monstermodifiers.timebetweenwavesmodifier")
	
	return cachedTimeBetweenWaves

func isPetUnlockable()->bool:
	var mapOk = GameWorld.lastMapSize == CONST.MAP_MEDIUM or \
	GameWorld.lastMapSize == CONST.MAP_LARGE or \
	GameWorld.lastMapSize == CONST.MAP_HUGE
	var modeOK = GameWorld.gameMode == CONST.MODE_RELICHUNT
	var petUnlockable = unlockablePets.size() > 0
	
	return mapOk and modeOK and petUnlockable

func getVersionPrint():
	if qaOptions or buildType == CONST.BUILD_TYPE.PLAYTEST:
		return version
	else:
		
		var split = version.split(".")
		if split.size() == 3:
			return split[0] + "." + split[1]
		elif split.size() == 4:
			return split[0] + "." + split[1] + "." + split[2]
		else:
			return version
