extends Node2D

var stage5Tiles: = [Vector2(0, 0), Vector2(0, - 1)]
var stage10Tiles: = [Vector2(0, 0), Vector2(1, 0), Vector2( - 1, 0), Vector2(0, - 1), Vector2( - 1, - 1), Vector2(1, - 1)]
var stage15Tiles: = [Vector2(0, 0), Vector2(1, 0), Vector2( - 1, 0), Vector2(0, - 1), Vector2( - 1, - 1), Vector2(1, - 1), Vector2( - 1, - 2), Vector2(1, - 2), Vector2(0, - 2)]

var fruits: = {}

var currentGrowthStage: int = 0
var rootCoords: = []
var fruitStage: int = 0

func _ready():
	Data.listen(self, "monsters.cycle")
	$Stem.frame = 0
	
	fruits[1] = [$FruitPosition1_1]
	fruits[2] = [$FruitPosition2_1, $FruitPosition2_2]
	fruits[3] = [$FruitPosition3_1, $FruitPosition3_2, $FruitPosition3_3]
	
	$TreeAmbience.play()

func serialize()->Dictionary:
	var data = {
		"rootCoords": var2str(rootCoords), 
		"currentGrowthStage": currentGrowthStage, 
		"fruitStage": fruitStage, 
		"fruitsData": []
	}
	
	for fs in fruits.get(fruitStage, []):
		data["fruitsData"].append({
			"type": fs.type, 
			"remainingCycles": fs.remainingCycles
		})

	data["meta.priority"] = 100
	data["meta.kind"] = "generic"
	
	return data
	
func deserialize(data: Dictionary):
	currentGrowthStage = int(data.get("currentGrowthStage", 0))
	$Stem.frame = currentGrowthStage
	fruitStage = int(data.get("fruitStage", 0))
	if data.has("rootCoords"):
		rootCoords = str2var(data["rootCoords"])
	for coord in rootCoords:
		Level.map.addTileDestroyedListener(self, coord)
	if data.has("fruitsData") and fruits.has(fruitStage):
		var fruitsData = data["fruitsData"]
		for i in range(fruitsData.size()):
			if fruits[fruitStage].size() > i:
				var fs = fruits[fruitStage][i]
				fs.setType(fruitsData[i].get("type", "iron"))
				fs.remainingCycles = int(fruitsData[i].get("remainingCycles", 1))
				if fs.remainingCycles == 0:
					fs.show()
	
func propertyChanged(property: String, oldValue, newValue):
	if not oldValue or oldValue == newValue:
		return 
	
	match property:
		
		"monsters.cycle":
			tryRooting()
			tryGrowingStem()
			
			if currentGrowthStage >= 5:
				var newFruitStage = currentGrowthStage / 5
				var wasReset: = false
				if newFruitStage != fruitStage and fruitStage > 0:
					
					for fs in fruits[fruitStage]:
						fs.clear()
					wasReset = true
				fruitStage = newFruitStage
				growFruits()
				if wasReset:
					for fs in fruits[fruitStage]:
						fs.progressCycle()
						fs.progressCycle()

func growFruits():
	var rootedResources: = {CONST.IRON: 1}
	for rootCoord in rootCoords:
		var res = Level.map.tileData().get_resourcev(rootCoord)
		match int(res):
			0: rootedResources[CONST.IRON] = 1 + rootedResources.get(CONST.IRON, 0)
			1: rootedResources[CONST.WATER] = 1 + rootedResources.get(CONST.WATER, 0)
			2: rootedResources[CONST.SAND] = 1 + rootedResources.get(CONST.SAND, 0)
	for f in fruits[fruitStage]:
		match f.type:
			CONST.IRON: rootedResources[CONST.IRON] = rootedResources.get(CONST.IRON, 0) - 1
			CONST.WATER: rootedResources[CONST.WATER] = rootedResources.get(CONST.WATER, 0) - 1
			CONST.SAND: rootedResources[CONST.SAND] = rootedResources.get(CONST.SAND, 0) - 1
	
	for fs in fruits[fruitStage]:
		if not fs.type or fs.type == "":
			
			var type: String
			if rootedResources.get(CONST.SAND, 0) > 0:
				type = CONST.SAND
				rootedResources[CONST.SAND] = rootedResources.get(CONST.SAND, 0) - 1
			elif rootedResources.get(CONST.WATER, 0) > 0:
				type = CONST.WATER
				rootedResources[CONST.WATER] = rootedResources.get(CONST.WATER, 0) - 1
			elif rootedResources.get(CONST.IRON, 0) > 0:
				type = CONST.IRON
				rootedResources[CONST.IRON] = rootedResources.get(CONST.IRON, 0) - 1
			if type:
				fs.setType(type)
		
		fs.progressCycle()

func tryGrowingStem():
	var resourceTiles: = 0
	for rootCoord in rootCoords:
		var res = Level.map.tileData().get_resourcev(rootCoord)
		if res >= 0 and res <= 2:
			resourceTiles += 1
	
	var baseCoord = rootCoords.front()
	baseCoord.y -= 1
	
	var relevantTiles: Array
	if currentGrowthStage < 5:
		relevantTiles = stage5Tiles
	elif currentGrowthStage < 10:
		relevantTiles = stage10Tiles
	else:
		relevantTiles = stage15Tiles
	
	for d in relevantTiles:
		var tile = Level.map.getTile(baseCoord + d)
		if tile != null:
			tile.hit(Vector2.ZERO, tile.max_health)
	
	if currentGrowthStage < 5:
		currentGrowthStage += 1
	if currentGrowthStage == 5 and resourceTiles >= 2:
		currentGrowthStage = 10
	elif currentGrowthStage == 10 and resourceTiles >= 3:
		currentGrowthStage = 15
	$Stem.frame = currentGrowthStage

func tryRooting():
	CONST.DIRECTIONS.shuffle()
	var roots = rootCoords.duplicate()
	roots.shuffle()
	var freeTiles: = []
	for root in roots:
		for d in CONST.DIRECTIONS:
			var coord = root + d
			if rootCoords.has(coord):
				continue
			var res = Level.map.tileData().get_resourcev(root + d)
			if res >= 0 and res <= 2:
				growOnTile(coord)
				return 
			elif res == 10:
				freeTiles.append(coord)
	
	if freeTiles.size() > 0:
		var coord = freeTiles[randi() % freeTiles.size()]
		growOnTile(coord)

func growOnTile(coord):
	Level.map.growRootsOnTile(coord)
	rootCoords.append(coord)
	Level.map.addTileDestroyedListener(self, coord)

func tileDestroyed(tileCoord: Vector2):
	if rootCoords.has(tileCoord):
		if rootCoords.front() == tileCoord:
			collapse()
			return 
		else:
			rootCoords.erase(tileCoord)
	
	var unreachableRoots = rootCoords.duplicate()
	var open: = [unreachableRoots.pop_front()]
	while open.size() > 0:
		var rootCoord = open.pop_front()
		for d in CONST.DIRECTIONS:
			var coord = rootCoord + d
			if unreachableRoots.has(coord):
				unreachableRoots.erase(coord)
				open.append(coord)
	
	for unreachableRoot in unreachableRoots:
		rootCoords.erase(unreachableRoot)
		Level.map.removeTileDestroyedListener(self, unreachableRoot)

func collapse():
	var seedDrop = Data.DROP_SCENES.get(CONST.SEED).instance()
	seedDrop.position = global_position
	Level.map.addDrop(seedDrop)
	for root in rootCoords:
		Level.map.removeTileDestroyedListener(self, root)
	queue_free()
	
	for fs in fruits.get(fruitStage, []):
		if fs.canFocusUse():
			fs.spawnResource()
