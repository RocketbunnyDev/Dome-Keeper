extends Node2D

var viability_large_noise: OpenSimplexNoise
var viability_small_noise: OpenSimplexNoise
var biome_noise: OpenSimplexNoise
var hardness_noise: OpenSimplexNoise

var a: MapArchetype

var doYields: = false
var finishedSuccessful: = false

func _ready():
	if get_parent() == get_tree().root:
		init(preload("res://content/map/generation/archetypes/regular-small.res"))
		generate()
		var cam = Camera2D.new()
		cam.zoom *= 5
		add_child(cam)
		cam.current = true

func init(archetype: MapArchetype):
	self.a = archetype
	viability_large_noise = a.viability_large_noise.duplicate()
	viability_small_noise = a.viability_small_noise.duplicate()
	hardness_noise = a.hardness_noise.duplicate()
	biome_noise = a.biome_noise.duplicate()
	
	viability_large_noise.seed = randi()
	viability_small_noise.seed = randi()
	hardness_noise.seed = randi()
	biome_noise.seed = randi()

func generateBiome(x, y)->int:
	var distance = Vector2(x, y).length() * 0.001
	var n1 = biome_noise.get_noise_2d(x, y)
	var biome: float = y * a.biome_depth_scale + distance * a.biome_distance_scale
	biome += n1 * a.biome_noise_strength
	biome -= a.biome_start
	return int(clamp(10 + round(biome), 10, 20))

func generate():
	if not viability_large_noise:
		return 
	$TileData / Biomes.clear()
	$TileData / Resources.clear()
	$TileData / Hardness.clear()
	
	
	var maxBiome: = 0
	var startDepthReductionAt = round(a.depth * float(a.stop_depth_at_fraction))
	var depthReductionLength = a.depth - startDepthReductionAt
	
	var startWidthReductionAt = round(float(a.width) * 0.5 * float(a.stop_width_at_fraction))
	var widthReductionLength = 0.5 * a.width - startWidthReductionAt
	
	var stopTighteningAt = round(float(a.depth) * float(a.entry_tightening_until))
	
	for x in range( - a.width, a.width):
		var absX = abs(x)
		var stopWidth: = pow(a.stop_width_factor * (max(0, (absX - startWidthReductionAt))) / widthReductionLength, a.stop_width_exponent)
		
		for y in range(0, a.depth * 1.4):
			var n1 = viability_large_noise.get_noise_2d(x, y)
			var n2 = viability_small_noise.get_noise_2d(x, y)
			
			var stopDepth: = pow(a.stop_depth_factor * (max(0, (y - startDepthReductionAt))) / depthReductionLength, a.stop_depth_exponent)
			
			
			var tighteningYFraction = max(0, (stopTighteningAt - y)) / stopTighteningAt
			var startTightening = pow(tighteningYFraction, a.entry_tightening_y_exp) * pow(absX, a.entry_tightening_x_exp)
			
			
			var thinTopFraction = max(0, pow(max(0, 10 - y), 3) - pow(max(0, a.thin_top_factor - absX), 2))
			
			
			var keepCore = max(0, max(0, a.keep_core_strength * (a.width - pow(absX, 2))) - pow(max(0, (y - a.depth * a.keep_core_falloff_y)), 2))
			
			var viability = a.viability_base + a.viability_large_noise_strength * n1 + a.viability_small_noise_strength * n2
			viability -= stopWidth
			viability -= stopDepth
			viability -= startTightening
			viability -= thinTopFraction
			viability += keepCore
			
			if viability < 0:
				continue
			
			var biome = generateBiome(x, y)
			$TileData / Biomes.set_cell(x, y, biome)
			maxBiome = max(maxBiome, biome)
	maxBiome -= 10
	
	var biomeDuplicate = $TileData / Biomes.duplicate()
	var openCells = [Vector2(0, 0)]
	var q = biomeDuplicate.get_used_cells().size() + 1
	while openCells.size() > 0:
		q -= 1
		if q < 0:
			break
		var cell = openCells.pop_front()
		for n in CONST.DIRECTIONS:
			var otherCell = n + cell
			if biomeDuplicate.get_cellv(otherCell) != - 1:
				biomeDuplicate.set_cellv(otherCell, - 1)
				openCells.append(otherCell)
	
	for cell in biomeDuplicate.get_used_cells():
		$TileData / Biomes.set_cellv(cell, - 1)
	
	
	
	var hardnessStabilizer: = 0.0
	for i in 10:
		var cells = $TileData / Biomes.get_used_cells()
		for cell in cells:
			var normalizedEntrance = min(1.0, pow(cell.length() * 0.16, 2))
			var hardnessNoise = hardness_noise.get_noise_2d(cell.x * 10, cell.y * 10) * normalizedEntrance
			var hardness = clamp(hardnessStabilizer + 15.5 + hardnessNoise * a.hardness_scale, 13, 17)
			$TileData / Hardness.set_cellv(cell, hardness)
		
		var softest = $TileData / Hardness.get_used_cells_by_id(13).size()
		var hardest = $TileData / Hardness.get_used_cells_by_id(17).size()
		if abs(softest - hardest) < cells.size() * 0.0025:
			break
		
		hardnessStabilizer += 2.0 * (softest - hardest) / float(cells.size())
	
	
	var cells = $TileData / Biomes.get_used_cells()
	for cell in cells:
		var normalizedEntrance = min(1.0, pow(cell.length() * 0.16, 2))
		var hardnessNoise = hardness_noise.get_noise_2d(cell.x * 10, cell.y * 10) * normalizedEntrance
		var hardness = clamp(hardnessStabilizer + a.hardness_offset + 15.5 + hardnessNoise * a.hardness_scale, a.hardness_min + 13, a.hardness_max + 13)
		$TileData / Hardness.set_cellv(cell, hardness)
		if hardness == 18:
			
			$TileData / Resources.set_cellv(cell, 21)
	
	
	var avg: = 0
	var lastI: = 0
	for i in range(10, 20):
		var cellCount = $TileData / Biomes.get_used_cells_by_id(i).size()
		if cellCount == 0:
			break
		lastI = i
		avg += cellCount
	
	avg /= (lastI - 9)
	var lastBiomeSize = $TileData / Biomes.get_used_cells_by_id(lastI).size()
	if lastBiomeSize <= avg * 0.33:
		for c in $TileData / Biomes.get_used_cells_by_id(lastI).duplicate():
			$TileData / Biomes.set_cell(c.x, c.y, lastI - 1)
		maxBiome -= 1
	
	var usedCells = $TileData / Biomes.get_used_cells()
	if a.generateResources:
		
		for cell in $TileData / Biomes.get_used_cells():
			for ox in range( - 1, 2):
				for oy in range( - 1, 2):
					var c = Vector2(cell.x + ox, cell.y + oy)
					if $TileData / Biomes.get_cellv(c) == - 1:
	
						$TileData / Resources.set_cell(cell.x + ox, cell.y + oy, 21)
		
		var borderCells = findOutsideBorderCells()
		
		var ironClusterAmount = round(a.iron_cluster_rate * 0.001 * usedCells.size())
		var waterAmount = round(a.water_rate * 0.001 * usedCells.size())
		var cobaltAmount = round(a.cobalt_rate * 0.001 * usedCells.size())
		
		if false:
			var remainingClusters = ironClusterAmount
			var mapCenter = Vector2(0, $TileData / Biomes.get_used_rect().size.y * 0.5)
			
			for cell in usedCells:
				if $TileData / Resources.get_cell(cell.x, cell.y) == - 1:
					$TileData / Resources.set_cell(cell.x, cell.y, 10)
		
				if remainingClusters > 0 and (cell - mapCenter).length() < 6:
		
					$TileData / Resources.set_cell(cell.x, cell.y, 0)
					remainingClusters -= 1
				else:
					$TileData / Resources.set_cell(cell.x, cell.y, 10)
		else:
			for cell in usedCells:
				if $TileData / Resources.get_cell(cell.x, cell.y) == - 1:
					$TileData / Resources.set_cell(cell.x, cell.y, 10)
			usedCells.shuffle()
			for i in ironClusterAmount:
				$TileData / Resources.set_cellv(usedCells[i], 0)
			
		
		
		var iterations: = 100
		var totalMove: = Vector2()
		var averagedLastTotalMoves: = Vector2()
		var zeroMoves: = 0
		for iteration in iterations:
			var ironTiles = $TileData / Resources.get_used_cells_by_id(0)
			ironTiles.shuffle()
			for tileCoord in ironTiles:
				var sum: = Vector2()
				for otherCoord in ironTiles:
					if otherCoord == tileCoord:
						continue
					var delta = tileCoord - otherCoord
					var strength = 25 + 5 * round(otherCoord.y * a.iron_cluster_size_per_y)
					var mod = strength / pow(delta.length(), 2)
					if mod < 0.0002:
						continue
					sum += (delta.normalized()) * mod
				for borderCell in borderCells:
					var strength = 400 + round(borderCell.y * 2.0)
					var delta = tileCoord - borderCell
					var mod = 0.005 * strength / pow(delta.length(), 2)
					if mod < 0.001:
						continue
					sum += (delta.normalized()) * mod
				if sum.length() > 0.2:
					sum = sum.normalized()
				sum.x = round(sum.x)
				sum.y = round(sum.y)
				if $TileData / Resources.get_cell(tileCoord.x + sum.x, tileCoord.y + sum.y) == 10:
					totalMove += sum
					moveResource(tileCoord, sum.x, sum.y, 0)
			averagedLastTotalMoves = averagedLastTotalMoves * 0.5 + totalMove * 0.5





		
		
		var minY = a.gadget_first_depth
		var x = sign(rand_range( - 1, 1)) * a.width * 0.1 + rand_range(a.width * - 0.03, a.width * 0.03)
		var remainingGadgets = a.gadgets
		var failsafe: = 1000
		while remainingGadgets > 0:
			failsafe -= 1
			if failsafe % 100 == 0:
				
				minY = minY + a.gadget_depth_step * 0.2
			elif failsafe == 100:
				minY = a.gadget_first_depth + (a.gadgets - remainingGadgets) * a.gadget_depth_step
			elif failsafe == 50:
				minY = a.gadget_first_depth
			elif failsafe <= 0:
				Logger.error("failed to generate gadgets")
				break
			
			var ironTiles = $TileData / Resources.get_used_cells_by_id(0)
			sortByDistanceReferencePoint = Vector2(round(x), minY)
			ironTiles.sort_custom(self, "sortByDistance")
			if ironTiles.size() < 4:
				break
			
			var averageCell: Vector2
			if failsafe > 100:
				averageCell = sortByDistanceReferencePoint * 0.4 + 0.6 * 0.25 * (ironTiles[0] + ironTiles[1] + ironTiles[2] + ironTiles[3])
			else:
				averageCell = ironTiles[0] + Vector2(round(rand_range( - 4, 4)), round(rand_range( - 4, 4)))
			if $TileData / Resources.get_cellv(averageCell) != 10:
				continue
			
			remainingGadgets -= 1
			$TileData / Resources.set_cellv(averageCell, 3)
			addCellToMap(averageCell + Vector2(1, 0))
			addCellToMap(averageCell + Vector2(0, 1))
			addCellToMap(averageCell + Vector2(1, 1))
			minY = minY + a.gadget_depth_step
			var relativeDepth = averageCell.y / float(a.depth)
			if averageCell.x == 0:
				averageCell.x = 1 if randf() > 0.5 else - 1
			var deltaWidth = sign(averageCell.x) * a.width * (0.1 + relativeDepth * 0.2) - averageCell.x
			x = - averageCell.x - deltaWidth
		
		
		x = rand_range(a.width * - 0.3, a.width * 0.3)
		x += sign(x) * a.width * 0.2
		var goal = Vector2(x, a.depth - a.relic_depth_step)
		for _i in a.relics:
			var ironTiles = $TileData / Resources.get_used_cells_by_id(0)
			var bestCell: Vector2
			var bestD: = 999999
			for cell in ironTiles:
				var v = (goal - cell)

				var d = v.length()
				if d < bestD:
					bestD = d
					bestCell = cell
			
			$TileData / Resources.set_cellv(bestCell, 4)
			addCellToMap(bestCell + Vector2( - 1, 0))
			addCellToMap(bestCell + Vector2( - 1, 1))
			addCellToMap(bestCell + Vector2(0, - 1))
			addCellToMap(bestCell + Vector2(1, - 1))
			addCellToMap(bestCell + Vector2(0, 1))
			addCellToMap(bestCell + Vector2(1, 0))
			addCellToMap(bestCell + Vector2(1, 1))
			addCellToMap(bestCell + Vector2(2, 0))
			addCellToMap(bestCell + Vector2(2, 1))
			addCellToMap(bestCell + Vector2(0, 2))
			addCellToMap(bestCell + Vector2(1, 2))
			minY = minY + a.gadget_depth_step
			var deltaWidth = sign(bestCell.x) * a.width * 0.2 - bestCell.x
			x = - bestCell.x - deltaWidth
			
			var remainingSwitches = a.relic_switches
			var switchDirections: Array
			var distanceNormalization: = 0.0
			failsafe = 50
			var averageDistance = 0.5 * (a.relic_switch_distance_range.x + a.relic_switch_distance_range.y)
			var minDistance = a.relic_switch_distance_range.x
			while remainingSwitches > 0:
				failsafe -= 1
				if failsafe < 0:
					Logger.error("failed to generate relic switch chambers")
					break
				if randf() < 0.2:
					if randf() > 0.5:
						switchDirections = [Vector2.UP, Vector2.LEFT, Vector2.RIGHT, Vector2.DOWN]
					else:
						switchDirections = [Vector2.UP, Vector2.RIGHT, Vector2.LEFT, Vector2.DOWN]
				else:
					if randf() > 0.5:
						switchDirections = [Vector2.LEFT, Vector2.RIGHT, Vector2.DOWN, Vector2.UP]
					else:
						switchDirections = [Vector2.RIGHT, Vector2.LEFT, Vector2.DOWN, Vector2.UP]
				
				var distance = rand_range(a.relic_switch_distance_range.x, a.relic_switch_distance_range.y) + distanceNormalization
				distance = clamp(distance, a.relic_switch_distance_range.x, a.relic_switch_distance_range.y)
				while switchDirections.size() > 0:
					var direction = switchDirections.pop_front()
					var result: Vector2 = tryPlaceRelicSwitch(bestCell, direction, distance, minDistance)
					if result != Vector2.ZERO:
						var distanceToSwitch = (result - bestCell).length()
						distanceNormalization += averageDistance - distanceToSwitch
						remainingSwitches -= 1
						if remainingSwitches == 0:
							break
				minDistance -= 1
		
		var ironTilesByBiome: = []
		var waterTilesByBiome: = []
		var sandTilesByBiome: = []
		for i in maxBiome + 1:
			ironTilesByBiome.append([])
			waterTilesByBiome.append([])
			sandTilesByBiome.append([])
		
		for cell in $TileData / Resources.get_used_cells_by_id(0):
			var index = $TileData / Biomes.get_cellv(cell) - 10
			ironTilesByBiome[index].append(cell)
		for cell in $TileData / Resources.get_used_cells_by_id(1):
			var index = $TileData / Biomes.get_cellv(cell) - 10
			waterTilesByBiome[index].append(cell)
		for cell in $TileData / Resources.get_used_cells_by_id(2):
			var index = $TileData / Biomes.get_cellv(cell) - 10
			sandTilesByBiome[index].append(cell)
		
		var removeCount: = 0.0
		for i in ironTilesByBiome.size():
			var tiles = ironTilesByBiome[i]
			tiles.shuffle()
			for tile in tiles:
				removeCount += float(a.iron_cluster_removal_rate)
				if removeCount > 1.0:
					removeCount -= 1.0
					$TileData / Resources.set_cellv(tile, 10)
		removeCount = 0.0
		for i in waterTilesByBiome.size():
			var tiles = waterTilesByBiome[i]
			tiles.shuffle()
			for tile in tiles:
				removeCount += float(a.water_removal_rate)
				if removeCount > 1.0:
					removeCount -= 1.0
					$TileData / Resources.set_cellv(tile, 10)
		removeCount = 0.0
		for i in sandTilesByBiome.size():
			var tiles = sandTilesByBiome[i]
			tiles.shuffle()
			for tile in tiles:
				removeCount += float(a.cobalt_removal_rate)
				if removeCount > 1.0:
					removeCount -= 1.0
					$TileData / Resources.set_cellv(tile, 10)
		
		
		var ironClusterCenters = $TileData / Resources.get_used_cells_by_id(0).duplicate(true)
		for cell in ironClusterCenters:
			var cluster: = [cell]
			var goalSize = round(a.iron_cluster_size_base + cell.y * (a.iron_cluster_size_per_y - a.iron_cluster_size_randomness * 0.5 + a.iron_cluster_size_randomness * randf()))
			for i in 50:
				if cluster.size() >= goalSize:
					break
				var randomCell = cluster[randi() % cluster.size()]
				CONST.DIRECTIONS.shuffle()
				for d in CONST.DIRECTIONS:
					var neighbor = randomCell + d
					if $TileData / Resources.get_cellv(neighbor) == 10:
						$TileData / Resources.set_cellv(neighbor, 0)
						cluster.append(neighbor)
						break
		
		
		var availableCells = $TileData / Resources.get_used_cells_by_id(10)
		availableCells.shuffle()
		var freeTileIndex: = 0
		for _j in waterAmount:
			$TileData / Resources.set_cellv(availableCells[freeTileIndex], 1)
			freeTileIndex += 1
		
		iterations = 100
		totalMove = Vector2()
		averagedLastTotalMoves = Vector2()
		zeroMoves = 0
		for iteration in iterations:
			var waterTiles = $TileData / Resources.get_used_cells_by_id(1)
			waterTiles.shuffle()
			for tileCoord in waterTiles:
				var sum: = Vector2()
				for otherCoord in waterTiles:
					if otherCoord == tileCoord:
						continue
					var strength = 30 + round(otherCoord.y * 0.1)
					var delta = tileCoord - otherCoord
					var mod = strength / pow(delta.length(), 2)
					if mod < 0.001:
						continue
					sum += (delta.normalized()) * mod
				for otherCoord in ironClusterCenters:
					var strength = 10
					var delta = tileCoord - otherCoord
					var mod = strength / pow(delta.length(), 3)
					if mod < 0.001:
						continue
					sum += (delta.normalized()) * mod
				for borderCell in borderCells:
					var strength = 15
					var delta = tileCoord - borderCell
					var mod = strength / pow(delta.length(), 3)
					if mod < 0.001:
						continue
					sum += (delta.normalized()) * mod
				if sum.length() > 0.2:
					sum = sum.normalized()
				sum.x = round(sum.x)
				sum.y = round(sum.y)
				if $TileData / Resources.get_cell(tileCoord.x + sum.x, tileCoord.y + sum.y) == 10:
					totalMove += sum
					moveResource(tileCoord, sum.x, sum.y, 1)
			averagedLastTotalMoves = averagedLastTotalMoves * 0.5 + totalMove * 0.5
			if (totalMove - averagedLastTotalMoves).length() < 1.0:
				zeroMoves += 1
				if zeroMoves >= 5:
					break
		
		
		availableCells = $TileData / Resources.get_used_cells_by_id(10)
		availableCells.shuffle()
		freeTileIndex = 0
		for _j in cobaltAmount:
			$TileData / Resources.set_cellv(availableCells[freeTileIndex], 2)
			freeTileIndex += 1
		iterations = 100
		totalMove = Vector2()
		averagedLastTotalMoves = Vector2()
		zeroMoves = 0
		for iteration in iterations:
			var cobaltTiles = $TileData / Resources.get_used_cells_by_id(2)
			ironClusterCenters.shuffle()
			for tileCoord in cobaltTiles:
				var sum: = Vector2()
				for otherCoord in cobaltTiles:
					if otherCoord == tileCoord:
						continue
					var strength = 100 + round(otherCoord.y * 0.1)
					var delta = tileCoord - otherCoord
					var mod = strength / pow(delta.length(), 2)
					if mod < 0.001:
						continue
					sum += (delta.normalized()) * mod
				for otherCoord in ironClusterCenters:
					var strength = 10
					var delta = tileCoord - otherCoord
					var mod = strength / pow(delta.length(), 2)
					if mod < 0.001:
						continue
					sum += (delta.normalized()) * mod
				for borderCell in borderCells:
					var strength = 5
					var delta = tileCoord - borderCell
					var mod = strength / pow(delta.length(), 3)
					if mod < 0.001:
						continue
					sum += (delta.normalized()) * mod
				if sum.length() > 0.2:
					sum = sum.normalized()
				sum.x = round(sum.x)
				sum.y = round(sum.y)
				if $TileData / Resources.get_cell(tileCoord.x + sum.x, tileCoord.y + sum.y) == 10:
					totalMove += sum
					moveResource(tileCoord, sum.x, sum.y, 2)
			
			averagedLastTotalMoves = averagedLastTotalMoves * 0.5 + totalMove * 0.5
			if (totalMove - averagedLastTotalMoves).length() < 1.0:
				zeroMoves += 1
				if zeroMoves >= 5:
					break
	
	
	$TileData / Biomes.set_cell(0, 0, 10)
	for cell in $TileData / Biomes.get_used_cells():
		for ox in range( - 1, 2):
			for oy in range( - 1, 2):
				if $TileData / Biomes.get_cell(cell.x + ox, cell.y + oy) == - 1:
					$TileData / Biomes.set_cell(cell.x + ox, cell.y + oy, min(10 + maxBiome, generateBiome(cell.x + ox, cell.y + oy)))
					$TileData / Resources.set_cell(cell.x + ox, cell.y + oy, 21)
					$TileData / Hardness.set_cell(cell.x + ox, cell.y + oy, 18)
	
	
	$TileData / Biomes.set_cell(0, - 1, 10)
	$TileData / Biomes.set_cell( - 1, - 2, 10)
	$TileData / Biomes.set_cell(0, - 2, 10)
	$TileData / Biomes.set_cell(1, - 2, 10)
	$TileData / Biomes.set_cell(0, 0, 10)
	
	$TileData / Resources.set_cell(0, - 1, - 1)
	$TileData / Resources.set_cell(0, 0, 10)


	



	$TileData / Hardness.set_cell(0, - 1, 15)
	$TileData / Hardness.set_cell(0, 0, 15)
	
	finishedSuccessful = true

func addCellToMap(cell: Vector2):
	$TileData / Resources.set_cellv(cell, 11)
	$TileData / Biomes.set_cellv(cell, generateBiome(cell.x, cell.y))

func findOutsideBorderCells()->Array:
	var allBorderCells = $TileData / Resources.get_used_cells_by_id(21)
	var borderGroups: = []
	var currentGroup = null
	var openCells: = []
	while allBorderCells.size() > 0:
		if currentGroup == null:
			var cell = allBorderCells.pop_back()
			openCells.append(cell)
			currentGroup = []
		
		if openCells.size() == 0:
			borderGroups.append(currentGroup)
			currentGroup = null
			continue
		
		var cell = openCells.pop_back()
		currentGroup.append(cell)
		
		for d in CONST.DIRECTIONS:
			var otherCell = cell + d
			if allBorderCells.has(otherCell):
				openCells.append(otherCell)
				allBorderCells.erase(cell)
	
	var largestGroup: = []
	var size: = 0
	for group in borderGroups:
		if group.size() > size:
			largestGroup = group
			size = group.size()
	return largestGroup

func tryPlaceRelicSwitch(baseCell: Vector2, direction: Vector2, distance: float, minDistance: int)->Vector2:
	for _d in round(distance) - minDistance:
		var delta = direction * distance
		for _r in 6:
			var angle = PI * rand_range(a.relic_switch_angle_range_pi.x, a.relic_switch_angle_range_pi.y)
			var goalCell = delta.rotated(angle) + baseCell
			goalCell.x = round(goalCell.x)
			goalCell.y = round(goalCell.y)
			if $TileData / Resources.get_cellv(goalCell) == 10:
				$TileData / Resources.set_cellv(goalCell, 6)
				return goalCell
		distance -= 1
	return Vector2.ZERO

func getRepellingForce(tileCoord: Vector2, relevantCoords: Array, border: Array, repellStrength: float, normalizeThreshold: float)->Vector2:
	var sum: = Vector2()
	for otherCoord in relevantCoords:
		if otherCoord == tileCoord:
			continue
		var strength = 5 + round(otherCoord.y * 0.4)
		var delta = tileCoord - otherCoord
		var mod = strength / pow(delta.length(), 2)
		sum += (delta.normalized()) * mod

	for borderCell in border:
		var strength = 1.0 + round(borderCell.y * 0.05)
		var delta = tileCoord - borderCell
		var mod = 0.05 * repellStrength * strength / pow(delta.length(), 3)
		sum += (delta.normalized()) * mod
	if sum.length() > normalizeThreshold:
		sum = sum.normalized()
	sum.x = round(sum.x)
	sum.y = round(sum.y)
	
	return sum

func moveResource(from: Vector2, byX, byY, newValue):
	$TileData / Resources.set_cell(from.x + byX, from.y + byY, newValue)
	$TileData / Resources.set_cell(from.x, from.y, 10)

func snapResource(tileCoord: Vector2):
	for d in CONST.DIRECTIONS:
		if $TileData / Resources.get_cellv(tileCoord + d) != 10:
			return 
	CONST.DIAGONALS.shuffle()
	for d in CONST.DIAGONALS:
		if $TileData / Resources.get_cellv(tileCoord + d) == 0:
			if randf() > 0.5:
				moveResource(tileCoord, d.x, 0, 0)
			else:
				moveResource(tileCoord, 0, d.y, 0)
			return 

func sortVectorByY(v1: Vector2, v2: Vector2):
	return v1.length() < v2.length()

func popTileData()->Node2D:
	var td = $TileData
	remove_child(td)
	return td

var sortByDistanceReferencePoint: Vector2
func sortByDistance(v1: Vector2, v2: Vector2):
	return (v1 - sortByDistanceReferencePoint).length() < (v2 - sortByDistanceReferencePoint).length()
