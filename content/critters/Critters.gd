extends Node


const PROBABILITY_roach = 0.4
const MAXAMOUNT_roach = 20
const PROBABILITY_eyes = 0.5
const MAXAMOUNT_eyes = 8
const PROBABILITY_worm = 0.2
const MAXAMOUNT_worm = 3
const PROBABILITY_rat = 0.15
const MAXAMOUNT_rat = 2
const PROBABILITY_shroomer = 0.2
const MAXAMOUNT_shroomer = 4

const CRITTER_MIN_DISTANCE = 50
const EYE_MAX_DISTANCE_TO_RESOURCE = 30

var critterByBiome: = {
	"green": ["shroomer"], 
	"red": ["roach", "eyes"], 
	"yellow": ["rat", "eyes"], 
	"blue": ["worm"], 
}

const COORD_ABOVE = Vector2(0, - 1)

func _on_Timer_timeout():
	if Options.disableCritters:
		return 
	
	if Data.ofOr("keeper.insidedome", true):
		return 
	
	var keeperCoord = Level.map.getTileCoord(Level.keeper.global_position)
	var tilesByBiome: = {}
	for x in range( - 10, 10):
		for y in range( - 8, 8):
			if abs(x) <= 3 and abs(y) <= 3:
				continue
			var offset = Vector2(x, y)
			var coord = keeperCoord + offset
			if coord.y < 3:
				continue
			var t = Level.map.getTile(coord)
			if t and t.type:
				var tiles
				if tilesByBiome.has(t.biome):
					tiles = tilesByBiome.get(t.biome)
				else:
					tiles = []
					tilesByBiome[t.biome] = tiles
				tiles.append(t)
	var dropsNearKeeper = getDropsNearKeeper()
	
	var closeBiomes: = []
	for offsetY in [ - 4, 0, 4]:
		var biome = Level.map.getBiomeOfCoord(keeperCoord + Vector2(0, offsetY))
		if biome and not closeBiomes.has(biome):
			closeBiomes.append(biome)
	

	for biome in closeBiomes:
		for critter in critterByBiome.get(biome, []):
			if randf() <= get("PROBABILITY_" + critter):
				var critters = get_tree().get_nodes_in_group("critters_" + critter)
				if critters.size() < get("MAXAMOUNT_" + critter):

					call("spawn_" + critter, tilesByBiome.get(biome, []), critters, dropsNearKeeper)











func spawn_eyes(tiles: Array, critters: Array, dropsNearKeeper: Array):
	for drop in dropsNearKeeper:
		if randf() > 0.2:
			
			continue
		
		var skip = false
		for e in critters:
			if e.global_position.distance_to(drop.global_position) < CRITTER_MIN_DISTANCE:
				
				skip = true
		if skip:
			continue
		
		var Critter = preload("res://content/critters/eyes/CaveCritterEyes.tscn")
		var tileCoord = Level.map.getTileCoord(drop.global_position)
		CONST.DIRECTIONS.shuffle()
		for offset in CONST.DIRECTIONS:
			var tile = Level.map.getTile(tileCoord + offset)
			if tile and tiles.has(tile):
				var critter = Critter.instance()
				critter.tile = tile
				add_child(critter)
				critter.global_position = tile.global_position + Vector2(rand_range(0, 8), 0).rotated(randf() * TAU)
				break








func spawn_roach(tiles: Array, critters: Array, dropsNearKeeper: Array):
	for d in dropsNearKeeper:
		if randf() > 0.4:
			
			continue
		var tileCoord = Level.map.getTileCoord(d.global_position)
		var tile = null
		var offsets = [Vector2(0, - 1), Vector2(0, 1), Vector2( - 1, 0), Vector2(1, 0)]
		offsets.shuffle()
		for offset in offsets:
			tile = Level.map.getTile(tileCoord + offset)
			if tile and tiles.has(tile):
				var critter = preload("res://content/critters/roach/Roach.tscn").instance()
				add_child(critter)
				critter.global_position = tile.global_position + Vector2(rand_range(0, 8), 0).rotated(randf() * TAU)
				critter.goto(d)






func spawn_worm(tiles: Array, critters: Array, dropsNearKeeper: Array):
	tiles.shuffle()
	CONST.DIRECTIONS.shuffle()
	for offset in CONST.DIRECTIONS:
		var tile = getFreeTile(tiles, offset)
		if tile:
			var critter = preload("res://content/critters/worm/Worm.tscn").instance()
			critter.tile = tile
			add_child(critter)
			critter.global_position = tile.global_position + offset * GameWorld.TILE_SIZE * 0.93
			critter.global_position += Vector2(rand_range( - 8, 8), 0).rotated(offset.angle() + PI / 2)
			critter.global_rotation = offset.angle()
			return 





func spawn_rat(tiles: Array, critters: Array, dropsNearKeeper: Array):
	tiles.shuffle()
	var tile = getFreeTile(tiles, COORD_ABOVE)
	if tile:
		var critter = preload("res://content/critters/rat/Rat.tscn").instance()
		add_child(critter)
		critter.global_position = tile.global_position + COORD_ABOVE * GameWorld.TILE_SIZE

func spawn_shroomer(tiles: Array, critters: Array, dropsNearKeeper: Array):
	tiles.shuffle()
	var tile = getFreeTile(tiles, COORD_ABOVE)
	if tile:
		var critter = preload("res://content/critters/mushroomman/Shroomer.tscn").instance()
		add_child(critter)
		critter.start(tile)
		critter.global_position = tile.global_position + COORD_ABOVE * GameWorld.TILE_SIZE * 0.45


func getDropsNearKeeper():
	var drops = get_tree().get_nodes_in_group("drops")
	for i in range(drops.size() - 1, - 1, - 1):
		var d = drops[i]
		var distance_from_keeper = Level.keeper.global_position.distance_to(d.global_position)
		if distance_from_keeper < CRITTER_MIN_DISTANCE or distance_from_keeper > 250:
			drops.remove(i)
	drops.shuffle()
	return drops

func getFreeTile(tiles: Array, offset: Vector2):
	for tile in tiles:
		var biome = Level.map.getBiomeOfCoord(tile.coord + offset)
		var resource = Level.map.tileData.get_resourcev(tile.coord + offset)
		var hardness = Level.map.tileData.get_hardnessv(tile.coord + offset)
		if biome and resource == - 1 and hardness >= 0:
			return tile
	return null

func pauseChanged():
	if GameWorld.paused:
		$Timer.paused = true
	else:
		$Timer.paused = false
