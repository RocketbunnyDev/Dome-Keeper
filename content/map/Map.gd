extends Node2D

class_name Map

const BORDER_TILE_OFFSETS1 = [Vector2(0, 0), Vector2(1, 0), Vector2(0, 1), Vector2(1, 1)]
const BORDER_TILE_OFFSETS2 = [Vector2(0, 0), Vector2(1, 0), Vector2(0, 1), Vector2(1, 1), 
Vector2( - 1, 0), Vector2( - 1, 1), Vector2(0, - 1), Vector2(1, - 1), 
Vector2(2, 0), Vector2(2, 1), Vector2(0, 2), Vector2(1, 2)
]
const NEIGHBOR_TILE_OFFSETS1 = [Vector2(1, 0), Vector2( - 1, 0), Vector2(0, 1), Vector2(0, - 1)]
const NEIGHBOR_TILE_OFFSETS2 = [Vector2(1, 0), Vector2( - 1, 0), Vector2(0, 1), Vector2(0, - 1), 
Vector2(2, 0), Vector2( - 2, 0), Vector2(0, 2), Vector2(0, - 2), 
Vector2(1, 1), Vector2( - 1, 1), Vector2(1, - 1), Vector2( - 1, - 1)]
const NEIGHBOR_TILE_OFFSETS_DIAG = [Vector2(1, 0), Vector2( - 1, 0), Vector2(0, 1), Vector2(0, - 1), Vector2(1, 1), Vector2( - 1, 1), Vector2(1, - 1), Vector2( - 1, - 1)]

const MAP_TO_TEXTURE_OFFSET_COORD: = Vector2(0, 2)

const TYPE_MAP: = {
	- 1: "", 
	21: CONST.BORDER, 
	0: CONST.IRON, 
	1: CONST.WATER, 
	2: CONST.SAND, 
	3: CONST.GADGET, 
	4: CONST.RELIC, 
	5: CONST.NEST, 









	10: "dirt", 
	11: "dirt", 
	12: "dirt", 
	13: "dirt", 
	14: "dirt", 
	15: "dirt", 
	16: "dirt", 
	17: "dirt", 
	18: "dirt", 
	19: "dirt", 
}

const TILE_SCENE = preload("res://content/map/tile/Tile.tscn")
const BORDER_SPRITE = preload("res://content/map/border/TileBorder.tscn")
const QUADRANT_BIOME_AND_HARDNESS_MATERIAL = preload("res://content/map/border/QuadrantBiomeAndHardnessMaterial.tres")
const QUADRANT_BIOME_MATERIAL = preload("res://content/map/border/QuadrantBiomeMaterial.tres")
const RESOURCE_BORDER_OVERLAY = preload("res://content/map/border/ResourceBorderOverlay.tscn")

const BIOME_LIST: = {
	"grey": Color("232532"), 
	"red": Color("3c2436"), 
	"yellow": Color("35221e"), 
	"blue": Color("142137"), 
	"green": Color("19383e")
}
var biomes: = []

const layouts: = {
	1: Vector2(0, 0), 
	2: Vector2(1, 0), 
	3: Vector2(2, 0), 
	4: Vector2(3, 0), 
	5: Vector2(0, 1), 
	6: Vector2(1, 1), 
	7: Vector2(2, 1), 
	8: Vector2(3, 1), 
	9: Vector2(0, 2), 
	10: Vector2(1, 2), 
	11: Vector2(2, 2), 
	12: Vector2(3, 2), 
	13: Vector2(0, 3), 
	14: Vector2(1, 3), 
	15: Vector2(3, 3), 
}

const hardnessOffsets: = {
	0: Vector2(0, 0), 
	1: Vector2(0, 4), 
	2: Vector2(0, 8), 
	3: Vector2(0, 12), 
	4: Vector2(0, 16), 
	5: Vector2(0, 20), 
}

const borderSpriteOffset = Vector2(12, 12)
const mapToWorldOffset = Vector2(12, - 72)

var tileData: TileData

var borderSprites: = {}
var tiles: = {}

var visibleTileCoords: = {}
var tileCoordsToReveal: = []
var tileDestroyedListeners: = {}
var tileRevealedListeners: = {}
var futureRoots: = []


var startingIronCountByLayer: = {}
var currentIronCountByLayer: = {}

var tilesByType: = {CONST.WATER: [], CONST.SAND: [], CONST.IRON: []}

var dropDeltas: = {}
var isFirstDrop: = true

var lift

var pathfinder: AStar2D
var pointIdsByCoord: = {}

onready var lights = $ViewportLights
onready var tiles_node = $Tiles
onready var tile_borders_node = $TileBorders
onready var border_deco = $ViewportRender / MapAnchor / BorderDecorations

func setTileData(tileDataInstance):
	if tileData:
		tileData.free()
	tileData = tileDataInstance
	if not tileData.get_parent():
		add_child(tileData)
		tileData().position = - mapToWorldOffset

func init(fromDeserialize: = false):
	border_deco.borderSprites = borderSprites
	border_deco.init()
	Style.init($Background)
	Style.init($ViewportRenderBackground / MapAnchor / BackgroundEdges)
	Style.init($ViewportRender / MapAnchor / MainStones)
	tilesByType = {CONST.WATER: [], CONST.SAND: [], CONST.IRON: []}
	Data.apply("map.tilesDestroyed", 0)
	
	tileData.visible = false
	
	for ironCell in tileData.get_resource_cells_by_id(Data.TILE_IRON):
		var layer = tileData.get_biome(ironCell.x, ironCell.y)
		startingIronCountByLayer[layer] = 1 + startingIronCountByLayer.get(layer, 0)
	for l in startingIronCountByLayer:
		currentIronCountByLayer[l] = startingIronCountByLayer[l]
	
	if not fromDeserialize:
		
		for c in tileData.get_resource_cells_by_id(Data.TILE_GADGET):
			addChamber(c, getSceneForTileType(Data.TILE_GADGET))
		
		var relicCells = tileData.get_resource_cells_by_id(Data.TILE_RELIC)
		for c in relicCells:
			tileData.set_resourcev(c, Data.TILE_DIRT_START)
			addChamber(c, getSceneForTileType(Data.TILE_RELIC))
		
		var relicSwitchCells = tileData.get_resource_cells_by_id(Data.TILE_RELIC_SWITCH)
		for c in relicSwitchCells:
			addChamber(c, getSceneForTileType(Data.TILE_RELIC_SWITCH))
		
		if GameWorld.isHalloween:
			for c in tileData.get_resource_cells_by_id(Data.TILE_SAND):
				addChamber(c, preload("res://content/map/decorations/ornaments/FollowEye.tscn"))
	
		
		biomes.clear()
		biomes.append("grey")
		var availableBiomes: = BIOME_LIST.keys().duplicate()
		if randf() > 0.4:
			biomes.append("green")
			if randf() > 0.5:
				biomes.append("yellow")
				biomes.append("red")
			else:
				biomes.append("red")
				biomes.append("yellow")
		else:
			if randf() > 0.5:
				biomes.append("yellow")
				if randf() > 0.2:
					biomes.append("green")
					biomes.append("red")
				else:
					biomes.append("red")
					biomes.append("green")
			else:
				biomes.append("red")
				if randf() > 0.2:
					biomes.append("green")
					biomes.append("yellow")
				else:
					biomes.append("yellow")
					biomes.append("green")
		if randf() > 0.25:
			biomes.append("blue")
		else:
			biomes.insert(biomes.size() - 2, "blue")
		
		availableBiomes = BIOME_LIST.keys().duplicate()
		for _i in range(1, 100):
			var biomeId = availableBiomes[randi() % availableBiomes.size()]
			if biomeId == biomes[biomes.size() - 1] or biomeId == biomes[biomes.size() - 2]:
				continue
			biomes.append(biomeId)
			availableBiomes.erase(biomeId)
			if availableBiomes.size() == 0:
				availableBiomes = BIOME_LIST.keys().duplicate()
				availableBiomes.erase(biomeId)
		if biomes.size() < 30:
			for _i in 4:
				availableBiomes = BIOME_LIST.keys().duplicate()
				availableBiomes.shuffle()
				biomes.append_array(availableBiomes)
	
	pathfinder = AStar2D.new()
	Achievements.addIfOpen(self, "MINE_ALL")
	prepareTilemapAndProcgen()
	dig(Vector2(0, - 1))
	dig(Vector2(0, - 2))


func generateCaves(minDistanceToCenter: = 10):
	var caves: = [
		preload("res://content/caves/teleportcave/TeleportCave.tscn").instance(), 
		preload("res://content/caves/mushroomcave/MushroomCave.tscn").instance(), 
		preload("res://content/caves/bombcave/BombCave.tscn").instance(), 
		preload("res://content/caves/helmetextensioncave/HelmetCave.tscn").instance(), 
		preload("res://content/caves/seedcave/SeedCave.tscn").instance(), 
		preload("res://content/caves/dronecave/DroneCave.tscn").instance(), 
		preload("res://content/caves/scannercave/ScannerCave.tscn").instance()
	]
	if GameWorld.isUpgradeLimitAvailable("cobaltgeneration"):
		caves.append(preload("res://content/caves/cobaltcave/CobaltCave.tscn").instance())
	if GameWorld.isHalloween and GameWorld.lastKeeperId == "keeper1" and GameWorld.lastGameModeId == CONST.MODE_RELICHUNT:
		caves.append(preload("res://content/caves/halloweencave/HalloweenSkeletonCave.tscn").instance())
	if GameWorld.isPetUnlockable():
		caves.append(preload("res://content/map/chamber/nest/NestCave.tscn").instance())
	
	caves.shuffle()
	
	var maxLayer = startingIronCountByLayer.size()
	for layerIndex in maxLayer:
		for cave in caves:
			var biomeFits = cave.biome == "" or biomes[layerIndex] == cave.biome
			var minLayerFits = cave.minLayer <= layerIndex
			var relativeDepth = layerIndex / float(maxLayer)
			var minDepthFits = round(relativeDepth * cave.minRelativeDepth) <= layerIndex
			var maxDepthFits = layerIndex <= round(maxLayer * cave.maxRelativeDepth)
			if biomeFits and minLayerFits and minDepthFits and maxDepthFits:
				addCave(cave, layerIndex, minDistanceToCenter)
				caves.erase(cave)
				break
	
	for cave in caves:
		cave.queue_free()


var holeTexture: ImageTexture = ImageTexture.new()
var holeImage: Image = Image.new()

var rockFalloffTexture: ImageTexture = ImageTexture.new()
var rockFalloffImage: Image = Image.new()

var damageTexture: ImageTexture = ImageTexture.new()
var damageImage: Image = Image.new()

var damageMaskTexture: ImageTexture = ImageTexture.new()
var damageMaskImage: Image = Image.new()

var bgCaveTexture: ImageTexture = ImageTexture.new()
var bgCaveImage: Image = Image.new()

var biomeColorTexture: ImageTexture = ImageTexture.new()
var biomeColorImage: Image = Image.new()

var noiseFactorTexture: ImageTexture = ImageTexture.new()
var noiseFactorImage: Image = Image.new()

var edge_scaling = 4


var tilemap_size = Vector2.ONE

onready var mask_mat = $ViewportRender / MapAnchor / MainStones.material
onready var bg_edge_mat = $ViewportRenderBackground / MapAnchor / BackgroundEdges.material
onready var rock_tiles = $ViewportRocks / Rocks


func prepareTilemapAndProcgen():
	tilemap_size = tileData.getMaxSize()

	
	var viewport_size = tilemap_size * GameWorld.TILE_SIZE
	$ViewportRocks.size = viewport_size
	$ViewportCrackImpact.size = viewport_size
	$ViewportRender / Shockwave.rect_size = viewport_size
	$ViewportRender / Shockwave.material.set_shader_param("screen_size", viewport_size)
	$ViewportLights.set_size(viewport_size)
	$ViewportBackgroundAlpha.size = viewport_size
	$ViewportLights.map_to_world_offset = mapToWorldOffset
	
	rock_tiles.position.x = tilemap_size.x / 2 * GameWorld.TILE_SIZE
	$LightSprite.position.x = ( - tilemap_size.x / 2 * GameWorld.TILE_SIZE) - mapToWorldOffset.x
	border_deco.position.x = (tilemap_size.x / 2 * GameWorld.TILE_SIZE) + GameWorld.TILE_SIZE

	prepareTextureAndImage(holeImage, holeTexture, edge_scaling, Image.FORMAT_RGB8, 4, false, Color.black)
	prepareTextureAndImage(bgCaveImage, bgCaveTexture, 1, Image.FORMAT_RGB8, 4, true, Color.black)
	prepareTextureAndImage(rockFalloffImage, rockFalloffTexture, 1, Image.FORMAT_RGB8, 4, false, Color.black)
	prepareTextureAndImage(damageImage, damageTexture, 2, Image.FORMAT_RGBA8, 4, false, Color(0.0, 0.0, 0.0, 1.0))
	prepareTextureAndImage(damageMaskImage, damageMaskTexture, 2, Image.FORMAT_RGBA8, 0, false, Color(0.0, 0.0, 0.0, 1.0))
	prepareTextureAndImage(noiseFactorImage, noiseFactorTexture, 1, Image.FORMAT_RGB8, 4, false, Color.white)
	prepareTextureAndImage(biomeColorImage, biomeColorTexture, 1, Image.FORMAT_RGB8, 0, false, Color.black)

	var map_scale: Vector2 = viewport_size / Vector2(3768.0, 3768.0)

	mask_mat.set_shader_param("mask_map", holeTexture)
	mask_mat.set_shader_param("damage_map", damageTexture)
	mask_mat.set_shader_param("damage_mask_map", damageMaskTexture)
	mask_mat.set_shader_param("rock_falloff_map", rockFalloffTexture)
	mask_mat.set_shader_param("mask_noise_factor_map", noiseFactorTexture)
	mask_mat.set_shader_param("base_scale", map_scale)
	bg_edge_mat.set_shader_param("mask_map", holeTexture)
	bg_edge_mat.set_shader_param("cave_map", bgCaveTexture)
	bg_edge_mat.set_shader_param("base_scale", map_scale)
	$ViewportRender / Shockwave.material.set_shader_param("size", 0.006 / map_scale.y)
	setRockTiles()

func prepareTextureAndImage(image: Image, texture: ImageTexture, scaling: float, image_format: int, flags: int, create_mipmaps: bool, fill_color: Color):
	image.create(tilemap_size.x * scaling, tilemap_size.y * scaling, create_mipmaps, image_format)
	image.fill(fill_color)
	texture.create_from_image(image)
	texture.flags = flags

func setRockTiles():
	var max_size = tilemap_size
	noiseFactorImage.lock()
	biomeColorImage.lock()
	bgCaveImage.lock()

	var bg_cave_spread = [
		Vector2.LEFT, Vector2.RIGHT, 
		Vector2.UP, Vector2.DOWN, 
		Vector2( - 1, - 1), Vector2(1, 1), 
		Vector2( - 1, 1), Vector2(1, - 1), 
		]
	
	for m_x_e in max_size.x:
		rock_tiles.set_cell(m_x_e - max_size.x / 2, - 2, 5)
	
	for m_x in max_size.x:
		for m_y in max_size.y:
			
			var adj_m_y = min(m_y + 1, max_size.y - 1)
			
			
			
			
			
			var x_coord = m_x - max_size.x / 2
			var y_coord = m_y - 1

			var bg_cave_col = bgCaveImage.get_pixel(m_x, adj_m_y)
			var bg_cave_img_size = bgCaveImage.get_size()
			var resource = tileData.get_resource(x_coord, y_coord)
			if resource < 10 and resource != - 1:
				bg_cave_col.r = 1.0

			var hardness = tileData.get_hardness(x_coord, y_coord)
			if hardness != - 1:
				rock_tiles.set_cell(x_coord, y_coord, hardness)
				var noise_factor_color = Color.black
				if hardness == 5:
					noise_factor_color.r = 1.0
					bg_cave_col.r = 1.0

				
				hardness = 10 if hardness == 5 else hardness * 0.5
				noise_factor_color.g = float(hardness) / 5.0
				noiseFactorImage.set_pixel(m_x, adj_m_y, noise_factor_color)
			else:
				rock_tiles.set_cell(x_coord, y_coord, 5)
				bg_cave_col.g = 1.0
			
			
			if bg_cave_col.r == 1.0:
				for bcs in bg_cave_spread:
					var spread_coord = Vector2(m_x, m_y) + bcs
					
					if (spread_coord.x < 0 or spread_coord.y < 0
					 or spread_coord.x > bg_cave_img_size.x
					 or spread_coord.y > bg_cave_img_size.y):
						continue

					var bg_cave_col_s = bgCaveImage.get_pixelv(spread_coord)
					bg_cave_col_s.b = 1.0
					bg_cave_col.b = 1.0
					bgCaveImage.set_pixelv(spread_coord, bg_cave_col_s)

			bgCaveImage.set_pixel(m_x, adj_m_y, bg_cave_col)
			
			var biome = tileData.get_biome(x_coord, y_coord - 1)
			if biome >= 0:
				biomeColorImage.set_pixel(m_x, m_y, BIOME_LIST[biomes[biome]])

	noiseFactorImage.unlock()
	biomeColorImage.unlock()
	bgCaveImage.unlock()

	bgCaveImage.generate_mipmaps()

	noiseFactorTexture.set_data(noiseFactorImage)
	biomeColorTexture.set_data(biomeColorImage)
	bgCaveTexture.create_from_image(bgCaveImage)
	mask_mat.set_shader_param("mask_noise_factor_map", noiseFactorTexture)
	mask_mat.set_shader_param("biome_color_map", biomeColorTexture)
	bg_edge_mat.set_shader_param("biome_color_map", biomeColorTexture)
	bg_edge_mat.set_shader_param("cave_map", bgCaveTexture)

func getBiomeColorByCoord(_coord: Vector2):
	var biome = tileData.get_biomev(_coord)
	var coord_biome_color = BIOME_LIST[biomes[biome]]
	return coord_biome_color

onready var shockwave_mat = $ViewportRender / Shockwave.material
onready var shockwave_tween = $ViewportRender / ShockwaveTween
func addTileDamage(hit_power, health, _direction, _position):
	flashCracks(_position)
	

	setTileDamage(health, _direction, _position)


func setTileDamage(health, direction, _position):
	
	_position += Vector2(0, 24)
	
	if health != 0:
		health = ease(min((health * 0.8) + 0.2, 1.0), 1.2)
	
	if abs(direction.x) > abs(direction.y):
		direction.y = 0
	else:
		direction.x = 0
	
	var from_dir = direction.normalized().round()
	var modded_pos = (_position / GameWorld.TILE_SIZE) + Vector2(tilemap_size.x / 2, 0.0) + Vector2.DOWN
	
	modded_pos *= 2
	
	damageImage.lock()
	damageMaskImage.lock()
	for x in 2:
		for y in 2:
			var current_pos = modded_pos + Vector2(x, y)
			var current_color_center = damageImage.get_pixelv(current_pos)
			current_color_center.b = health
			damageImage.set_pixelv(current_pos, current_color_center)
			
			if from_dir.x == - 1:
				
				var current_color = damageImage.get_pixelv(current_pos)
				current_color.r = health
				damageImage.set_pixelv(current_pos, current_color)

			elif from_dir.x == 1:
				
				var current_color = damageImage.get_pixelv(current_pos + (Vector2.RIGHT * 2))
				current_color.r = health
				damageImage.set_pixelv(current_pos + (Vector2.RIGHT * 2), current_color)

			elif from_dir.y == - 1:
				
				var current_color = damageImage.get_pixelv(current_pos)
				current_color.g = health
				damageImage.set_pixelv(current_pos, current_color)

			elif from_dir.y == 1:
				
				var current_color = damageImage.get_pixelv(current_pos + (Vector2.DOWN * 2))
				current_color.g = health
				damageImage.set_pixelv(current_pos + (Vector2.DOWN * 2), current_color)

	damageImage.unlock()
	damageTexture.set_data(damageImage)
	damageMaskImage.unlock()
	damageMaskTexture.set_data(damageMaskImage)
	mask_mat.set_shader_param("damage_map", damageTexture)
	mask_mat.set_shader_param("damage_mask_map", damageMaskTexture)

const CrackImpact = preload("res://content/map/tile/CrackImpact.tscn")
func flashCracks(_pos: Vector2):
	
	var tile_pos = _pos + (Vector2(tilemap_size.x / 2, 0.0) * GameWorld.TILE_SIZE)
	tile_pos += Vector2(12, 58)
	var new_impact = CrackImpact.instance()
	new_impact.position = tile_pos
	$ViewportCrackImpact.add_child(new_impact)

func wiggleWalls(_hit_power, direction, _position):
	
	_position += Vector2(0, 24)
	var max_impact_power = range_lerp(ease(min(_hit_power, 1.0), 0.5), 0, 1, 0.4, 0.04)
	var impact_pos = _position + direction * 0.5 + (Vector2(tilemap_size.x / 2, 0.0) * GameWorld.TILE_SIZE) + Vector2(12, 82)
	shockwave_mat.set_shader_param("global_position", impact_pos)
	shockwave_tween.interpolate_property(shockwave_mat, "shader_param/force", max_impact_power, 0.0, 0.4, Tween.TRANS_ELASTIC, Tween.EASE_OUT)
	shockwave_tween.start()

func dig(tileCoord: Vector2):
	
	tileCoord += MAP_TO_TEXTURE_OFFSET_COORD
	
	var draw_pos_es = (Vector2(tileCoord.x, tileCoord.y) + Vector2(tilemap_size.x / 2, 0)) * edge_scaling
	var draw_pos = (Vector2(tileCoord.x, tileCoord.y) + Vector2(tilemap_size.x / 2, 0))
	
	holeImage.lock()
	rockFalloffImage.lock()
	
	for x in edge_scaling:
		for y in edge_scaling:
			holeImage.set_pixelv(draw_pos_es + Vector2(x, y), Color.white)

	var rock_falloff_color = rockFalloffImage.get_pixelv(draw_pos)
	rock_falloff_color.r = 1.0
	rockFalloffImage.set_pixelv(draw_pos, rock_falloff_color)
	
	var offsets = get("BORDER_TILE_OFFSETS" + str(Data.of("map.revealdistance")))
	for offset in offsets:
		var drawpos_offset = draw_pos + offset
		if drawpos_offset.y < 0:
			continue
		var rock_falloff_color_offset = rockFalloffImage.get_pixelv(drawpos_offset)
		rock_falloff_color_offset.g = 1.0
		rockFalloffImage.set_pixelv(drawpos_offset, rock_falloff_color_offset)
	
	
	damageImage.lock()
	var rock_falloff_image_size: Vector2 = rockFalloffImage.get_size()
	
	if not ((draw_pos.x < 0 or draw_pos.x > rock_falloff_image_size.x)
		 or (draw_pos.y < 0 or draw_pos.y > rock_falloff_image_size.y)):
		
		var cell_color: float = rockFalloffImage.get_pixelv(draw_pos).r
		if cell_color == 1:
			for x in 2:
				for y in 2:
					
					var red_coord = ((draw_pos) * 2) + Vector2(x + 2, y)
					var oc_r: Color = damageImage.get_pixelv(red_coord)
					oc_r.r = 0
					damageImage.set_pixelv(red_coord, oc_r)
			
					
					var green_coord = ((draw_pos) * 2) + Vector2(x, y + 2)
					var oc_g: Color = damageImage.get_pixelv(green_coord)
					oc_g.g = 0
					damageImage.set_pixelv(green_coord, oc_g)
			
					
					var final_coord = ((draw_pos) * 2) + Vector2(x, y)
					damageImage.set_pixelv(final_coord, Color.black)
	
	damageImage.unlock()
	holeImage.unlock()
	rockFalloffImage.unlock()
	
	damageTexture.set_data(damageImage)
	holeTexture.set_data(holeImage)
	rockFalloffTexture.set_data(rockFalloffImage)
	
	mask_mat.set_shader_param("damage_map", damageTexture)
	mask_mat.set_shader_param("mask_map", holeTexture)
	mask_mat.set_shader_param("rock_falloff_map", rockFalloffTexture)
	bg_edge_mat.set_shader_param("mask_map", holeTexture)


func fill(_pos: Vector2):
	
	_pos += Vector2.DOWN
	
	var tile_pos = _pos * GameWorld.TILE_SIZE + Vector2(0, - 24)
	setTileDamage(0.0, Vector2.RIGHT, tile_pos)
	setTileDamage(0.0, Vector2.DOWN, tile_pos)
	setTileDamage(0.0, Vector2.LEFT, tile_pos)
	setTileDamage(0.0, Vector2.UP, tile_pos)
	
	var draw_pos_es = (Vector2(floor(_pos.x), floor(_pos.y + 1)) + Vector2(tilemap_size.x / 2, 0)) * edge_scaling
	var draw_pos = (Vector2(floor(_pos.x), floor(_pos.y + 1)) + Vector2(tilemap_size.x / 2, 0))

	holeImage.lock()
	rockFalloffImage.lock()
	for x in edge_scaling:
		for y in edge_scaling:
			holeImage.set_pixelv(draw_pos_es + Vector2(x, y), Color.black)

	var rock_falloff_color = rockFalloffImage.get_pixelv(draw_pos)
	rock_falloff_color.r = 0.0
	rockFalloffImage.set_pixelv(draw_pos, rock_falloff_color)

	for x in 2:
		for y in 2:
			var drawpos_offset = draw_pos + Vector2(x, y) + Vector2( - 1, 1)
			var rock_falloff_color_offset = rockFalloffImage.get_pixelv(drawpos_offset)
			rock_falloff_color_offset.g = 0.0
			rockFalloffImage.set_pixelv(drawpos_offset, rock_falloff_color_offset)

	holeImage.unlock()
	rockFalloffImage.unlock()

	holeTexture.set_data(holeImage)
	rockFalloffTexture.set_data(rockFalloffImage)
	mask_mat.set_shader_param("mask_map", holeTexture)
	mask_mat.set_shader_param("rock_falloff_map", rockFalloffTexture)
	bg_edge_mat.set_shader_param("mask_map", holeTexture)

func revealInitialState():
	for cell in tileData.getRevealedCells():
		onTileRemoved(cell)
		dig(cell)



onready var fg_map_anchor = $ViewportRender / MapAnchor
onready var bg_map_anchor = $ViewportRenderBackground / MapAnchor
onready var viewport_render = $ViewportRender
onready var fg_sprite = $MainTileRender
onready var bg_sprite = $BackgroundTileRender
func offsetViewportSprite():
	if not InputSystem.getCamera() or viewportMapFullDisplay:
		return 
	
	var viewport_size = viewport_render.size
	var new_pos = Vector2(( - (tilemap_size.x) * GameWorld.TILE_SIZE) / 2 + viewport_size.x / 2, viewport_size.y / 2) - Vector2(12, 24)
	new_pos += - InputSystem.getCamera().global_position
	fg_map_anchor.global_position = new_pos
	bg_map_anchor.global_position = new_pos
	
	var sub_pixel = InputSystem.getCamera().global_position - InputSystem.getCamera().global_position.round()
	var new_sprite_pos = InputSystem.getCamera().global_position - sub_pixel
	fg_sprite.global_position = new_sprite_pos
	bg_sprite.global_position = new_sprite_pos

var viewportMapFullDisplay: bool = false
func switchMapViewportMode(mode: bool):
	viewportMapFullDisplay = mode
	
	fg_sprite.centered = not viewportMapFullDisplay
	bg_sprite.centered = not viewportMapFullDisplay
	
	if viewportMapFullDisplay:
		var viewport_size = tilemap_size * GameWorld.TILE_SIZE
		$ViewportRender.size = viewport_size
		$ViewportRenderBackground.size = viewport_size
		
		fg_sprite.texture = $ViewportRender.get_texture()
		bg_sprite.texture = $ViewportRenderBackground.get_texture()
		yield (get_tree(), "idle_frame")
		
		fg_sprite.position.x = ( - tilemap_size.x / 2 * GameWorld.TILE_SIZE) - mapToWorldOffset.x
		bg_sprite.position.x = ( - tilemap_size.x / 2 * GameWorld.TILE_SIZE) - mapToWorldOffset.x
		fg_sprite.position.y = - 23
		bg_sprite.position.y = - 23
		fg_map_anchor.global_position = Vector2.ZERO
		bg_map_anchor.global_position = Vector2.ZERO
	else:
		$ViewportRender.size = Vector2(960, 540)
		$ViewportRenderBackground.size = Vector2(960, 540)
		yield (get_tree(), "idle_frame")
		fg_sprite.texture = $ViewportRender.get_texture()
		bg_sprite.texture = $ViewportRenderBackground.get_texture()

func _process(delta):
	offsetViewportSprite()
	for t in tileCoordsToReveal:
		revealTile(t)
	tileCoordsToReveal.clear()
	if GameWorld.devMode and Input.is_action_just_pressed("num6"):
		var i = randi()
		holeImage.save_png("../" + str(i) + "holeImage.png")
		rockFalloffImage.save_png("../" + str(i) + "rockFalloffImage.png")
		damageImage.save_png("../" + str(i) + "damageImage.png")
		bgCaveImage.save_png("../" + str(i) + "bgCaveImage.png")
		biomeColorImage.save_png("../" + str(i) + "biomeColorImage.png")
		noiseFactorImage.save_png("../" + str(i) + "noiseFactorImage.png")

func growTile(coord: Vector2, type: int):
	tileData.set_resource(coord.x, coord.y, type)
	revealTile(coord)




func revealTile(coord: Vector2):
	var typeId: int = tileData.get_resource(coord.x, coord.y)
	if typeId == Data.TILE_EMPTY:
		return 
	
	if tiles.has(coord):
		return 
	
	if typeId == Data.TILE_CAVE:
		tileData.set_resource(coord.x, coord.y, - 1)
	else:
		var tile = TILE_SCENE.instance()
		var biomeId: int = tileData.get_biome(coord.x, coord.y)
		if biomeId == 11:
			typeId = Data.TILE_BORDER
		else:
			tile.layer = biomeId
			tile.biome = biomes[tile.layer]
		tile.position = coord * GameWorld.TILE_SIZE
		tile.coord = coord
		if coord.y == - 1 and coord.x != 0:
			tile.visible = false
		tile.hardness = tileData.get_hardness(coord.x, coord.y)
		
		tile.type = TYPE_MAP.get(typeId)
		match tile.type:
			CONST.IRON:
				tile.richness = 2
			CONST.SAND:
				tile.richness = 2.0
			CONST.WATER:
				tile.richness = 2.5
		tiles[coord] = tile
		
		if tilesByType.has(tile.type):
			tilesByType[tile.type].append(tile)
		tile.connect("destroyed", self, "destroyTile", [tile])
		
		if futureRoots.has(coord):
			futureRoots.erase(coord)
			tile.root()
		
		tiles_node.add_child(tile)

	
	visibleTileCoords[coord] = null
	
	var invalids: = []
	if tileRevealedListeners.has(coord):
		for listener in tileRevealedListeners[coord]:
			if is_instance_valid(listener):
				listener.tileRevealed(coord)
			else:
				invalids.append(listener)
		for invalid in invalids:
			tileRevealedListeners.erase(invalid)

func destroyTile(tile):
	var sound
	match tile.type:
		CONST.BORDER:
			return 
		CONST.IRON:
			sound = $TileDestroyedIron.duplicate(DUPLICATE_USE_INSTANCING)
		CONST.WATER:
			sound = $TileDestroyedWater.duplicate(DUPLICATE_USE_INSTANCING)
		CONST.SAND:
			sound = $TileDestroyedSand.duplicate(DUPLICATE_USE_INSTANCING)
		CONST.SAND:
			sound = $TileDestroyedChamber.duplicate(DUPLICATE_USE_INSTANCING)
		_:
			sound = $TileDestroyed.duplicate(DUPLICATE_USE_INSTANCING)
	sound.setSimulatedPosition(tile.global_position)
	add_child(sound)
	sound.play()
	
	dig(tile.coord)
	
	if tile.type == CONST.IRON:
		currentIronCountByLayer[tile.layer] = currentIronCountByLayer[tile.layer] - 1
	
	if tile.type == CONST.IRON or tile.type == CONST.SAND or tile.type == CONST.WATER:
		var goalRichness = tile.richness * Data.ofOr("resourcemodifiers.richness." + tile.type, 1.0)
		var drops = floor(goalRichness - 1 + (randi() % 3))
		if tile.type == CONST.IRON:
			if isFirstDrop:
				
				isFirstDrop = false
				drops = 2
		var newDelta = dropDeltas.get(tile.type, 0) + drops - goalRichness
		if newDelta >= 3:
			drops -= 1
			newDelta -= 1
		elif newDelta <= - 3:
			drops += 1
			newDelta += 1
		dropDeltas[tile.type] = newDelta
		
		if tile.type == CONST.SAND and drops < 3 and GameWorld.gameMode == CONST.MODE_RELICHUNT and GameWorld.difficulty <= 0:
			
			var sandWithFloating = Data.of("inventory.sand") + Data.of("inventory.floatingsand")
			if Data.of("dome.health") < 350 - 60 * sandWithFloating:
				drops += 1
		if drops < 3 and GameWorld.difficulty * 0.1 < - randf():
			drops += 1
		
		for _i in range(0, drops):
			var drop = Data.DROP_SCENES.get(tile.type).instance()
			drop.position = tile.global_position + 0.6 * Vector2(GameWorld.HALF_TILE_SIZE - randf() * GameWorld.TILE_SIZE, GameWorld.HALF_TILE_SIZE - randf() * GameWorld.TILE_SIZE)
			drop.apply_central_impulse(Vector2(0, 50).rotated(randf() * TAU))
			call_deferred("addDrop", drop)
			GameWorld.incrementRunStat("resources_mined")
	
	tiles.erase(tile.coord)
	for t in tilesByType.values():
		t.erase(tile)
	tilesByType.get(tile.type, {}).erase(tile)
	tile.queue_free()
	
	onTileRemoved(tile.coord)

func onTileRemoved(tileCoord: Vector2):
	Data.apply("map.tilesDestroyed", Data.of("map.tilesDestroyed") + 1)
	tileData.clear_resource(tileCoord.x, tileCoord.y)
	
	for listener in tileDestroyedListeners.get(tileCoord, []):
		listener.tileDestroyed(tileCoord)
	
	var id = pathfinder.get_available_point_id()
	pointIdsByCoord[tileCoord] = id
	pathfinder.add_point(id, tileCoord)
	visibleTileCoords[tileCoord] = null

	var offsets = get("NEIGHBOR_TILE_OFFSETS" + str(Data.of("map.revealdistance")))
	for n in offsets:
		var c = n + tileCoord
		tileCoordsToReveal.append(c)

		
		visibleTileCoords[c] = null
	
	for n in NEIGHBOR_TILE_OFFSETS1:
		var c = n + tileCoord

		if pointIdsByCoord.has(c) and not tiles.has(c):
			pathfinder.connect_points(id, pointIdsByCoord[c], true)
	
	for x in range( - 1, 1):
		for y in range( - 1, 1):
			updateBorderSprite(tileCoord.x + x, tileCoord.y + y)
	
	if tileCoord.x == 0 and lift:
		updateLiftLength()

func revealDistanceChanged():
	rockFalloffImage.lock()
	for tileCoord in tileData.getRevealedCells():
		var hackOffsetTileCoord = MAP_TO_TEXTURE_OFFSET_COORD + tileCoord
		var draw_pos = (Vector2(hackOffsetTileCoord.x, hackOffsetTileCoord.y) + Vector2(tilemap_size.x / 2, 0))
		var offsets = get("BORDER_TILE_OFFSETS" + str(Data.of("map.revealdistance")))
		for offset in offsets:
			var c = offset + tileCoord
			if tileData.get_biomev(c) == 0:
				continue
			var drawpos_offset = draw_pos + offset
			var rock_falloff_color_offset = rockFalloffImage.get_pixelv(drawpos_offset)
			rock_falloff_color_offset.g = 1.0
			rockFalloffImage.set_pixelv(drawpos_offset, rock_falloff_color_offset)
			tileCoordsToReveal.append(c)
			visibleTileCoords[c] = null
	rockFalloffImage.unlock()
	rockFalloffTexture.set_data(rockFalloffImage)
	mask_mat.set_shader_param("rock_falloff_map", rockFalloffTexture)



func addTileRevealedListener(listener, coord):
	var listeners: Array
	if tileRevealedListeners.has(coord):
		listeners = tileRevealedListeners[coord]
	else:
		listeners = []
		tileRevealedListeners[coord] = listeners
	listeners.append(listener)

func removeTileRevealedListener(listener, coord):
	if tileRevealedListeners.has(coord):
		var listeners = tileRevealedListeners.get(coord)
		listeners.erase(listener)
		tileRevealedListeners[coord] = listeners



func addTileDestroyedListener(listener, coord):
	var listeners: Array
	if tileDestroyedListeners.has(coord):
		listeners = tileDestroyedListeners[coord]
	else:
		listeners = []
		tileDestroyedListeners[coord] = listeners
	listeners.append(listener)

func removeTileDestroyedListener(listener, coord):
	if tileDestroyedListeners.has(coord):
		var listeners = tileDestroyedListeners.get(coord)
		listeners.erase(listener)
		tileDestroyedListeners[coord] = listeners

func findPath(fromPos: Vector2, toPos: Vector2):
	var fromCoord = getTileCoord(fromPos)
	if fromCoord.y < 0:
		fromCoord = Vector2(0, - 1)
	var toCoord = getTileCoord(toPos)
	if not pointIdsByCoord.has(fromCoord):
		Logger.warn("cannot find path as starting coord is not within pathfinding map", "Map.findPath", {"fromPos": fromPos, "toPos": toPos})
		return null
	if not pointIdsByCoord.has(toCoord):
		Logger.warn("cannot find path as destination coord is not within pathfinding map", "Map.findPath", {"fromPos": fromPos, "toPos": toPos})
		return null
	return pathfinder.get_point_path(pointIdsByCoord[fromCoord], pointIdsByCoord[toCoord])

func updateBorderSprite(x: int, y: int):
	var key = Vector2(x, y)
	border_deco.markDirtyTile(key)
	var r_tl: int = tileData.get_resource(x, y)
	var r_tr: int = tileData.get_resource(x + 1, y)
	var r_br: int = tileData.get_resource(x + 1, y + 1)
	var r_bl: int = tileData.get_resource(x, y + 1)
	var borderLayout = int(r_tl > Data.TILE_EMPTY) * 1 + int(r_tr > Data.TILE_EMPTY) * 2 + int(r_br > Data.TILE_EMPTY) * 4 + int(r_bl > Data.TILE_EMPTY) * 8
	var tileMeta = borderSprites.get(key, null)
	if borderLayout > 0:
		if not tileMeta:
			var biome_id_tl: int = tileData.get_biome(x, y)
			var biome_id_tr: int = tileData.get_biome(x + 1, y)
			var biome_id_bl: int = tileData.get_biome(x, y + 1)
			var biome_id_br: int = tileData.get_biome(x + 1, y + 1)
			var biomeEdgeCase: = biome_id_tl != biome_id_tr or biome_id_tr != biome_id_bl or biome_id_bl != biome_id_br
			var biome: = "mixed"
			if not biomeEdgeCase:
				biome = biomes[biome_id_tl]
			tileMeta = [borderLayout, biome, {}]
			borderSprites[key] = tileMeta
			
			var overlays: Dictionary = tileMeta[2]
			for typeId in [Data.TILE_IRON, Data.TILE_SAND, Data.TILE_WATER]:
				if r_tl == typeId or r_tr == typeId or r_bl == typeId or r_br == typeId:
					var overlay = RESOURCE_BORDER_OVERLAY.instance()
					overlay.material = overlay.material.duplicate()
					overlay.position.x = x * GameWorld.TILE_SIZE + borderSpriteOffset.x
					overlay.position.y = y * GameWorld.TILE_SIZE + borderSpriteOffset.y
					tile_borders_node.add_child(overlay)
					overlays[typeId] = overlay
					Style.init(overlay)
		
		assert (tileMeta.size() == 3)
		tileMeta[0] = borderLayout
		
		var overlays: Dictionary = tileMeta[2]
		for ok in tileMeta[2]:
			var offset: = Vector2()
			match ok:
				Data.TILE_IRON:
					offset.y += 8
				Data.TILE_WATER:
					offset.y += 4
			overlays[ok].set_frame_coords(layouts[borderLayout] + offset)
			overlays[ok].material.set_shader_param("frame_coords", layouts[borderLayout] + offset)
			overlays[ok].material.set_shader_param("hide_tl", float(r_tl != ok))
			overlays[ok].material.set_shader_param("hide_tr", float(r_tr != ok))
			overlays[ok].material.set_shader_param("hide_bl", float(r_bl != ok))
			overlays[ok].material.set_shader_param("hide_br", float(r_br != ok))
	elif borderSprites.has(key):
		assert (tileMeta.size() == 3)
		for ok in tileMeta[2]:
			tileMeta[2][ok].queue_free()
		borderSprites.erase(key)
		border_deco.markDirtyTile(key)

func addTileOverlay(overlay):
	$TileOverlays.add_child(overlay)

func getSceneForTileType(tileType: int)->PackedScene:
	match tileType:
		Data.TILE_GADGET: return preload("res://content/map/chamber/gadget/GadgetChamber.tscn")
		Data.TILE_RELIC: return preload("res://content/map/chamber/relic/RelicChamber.tscn")
		Data.TILE_NEST: return preload("res://content/map/chamber/nest/NestCave.tscn")
		Data.TILE_RELIC_SWITCH: return preload("res://content/map/chamber/relicswitch/RelicSwitchChamber.tscn")
		_: return null

func addChamber(coord: Vector2, scene: PackedScene):
	var chamber = scene.instance()
	addLandmark(coord, chamber)
	for c in chamber.tileCoords:
		var absCoord = chamber.coord + c
		addTileDestroyedListener(chamber, absCoord)
		tileData.set_resource(absCoord.x, absCoord.y, chamber.getTileType())
		
	return chamber

func addCave(cave, biomeIndex, minDistanceToCenter):
	cave.updateUsedTileCoords()

	
	for _i in 20:
		var cells = tileData.get_biome_cells_by_index(biomeIndex)
		if cells.size() < cave.tileCoords.size():
			return 
		
		var cell = cells[randi() % cells.size()]
		if abs(cell.x) < minDistanceToCenter:
			continue
		
		if not tileData.is_area_free(cell, cave.tileCoords):
			continue
		
		addLandmark(cell, cave)
		for c in cave.tileCoords:
			var absCoord = cell + c
			tileData.set_resource(absCoord.x, absCoord.y, Data.TILE_CAVE)
		return 

func addLandmark(coord: Vector2, landmark):
	landmark.place(coord)
	var landmarkBiome = tileData.get_biomev(landmark.coord)

	for c in landmark.tileCoords:
		var absCoord = landmark.coord + c
		addTileRevealedListener(landmark, absCoord)
		
		tileData.set_biome(absCoord.x, absCoord.y, landmarkBiome)
		
		tileData.set_hardnessv(absCoord, clamp(tileData.get_hardnessv(absCoord), 0, 4))
		border_deco.markTileUndecoratable(absCoord)
	
	
	for c in landmark.tileCoords:
		for neighborsOffset in NEIGHBOR_TILE_OFFSETS_DIAG:
			var landmarkCoord = c + neighborsOffset
			if landmark.tileCoords.has(landmarkCoord):
				continue
			
			var neighborCoord = landmark.coord + landmarkCoord
			if tileData.get_biomev(neighborCoord) < 0:
				tileData.set_biomev(neighborCoord, tileData.get_biomev(coord))
				tileData.set_resourcev(neighborCoord, 21)
				tileData.set_hardnessv(neighborCoord, 5)
	
	if GameWorld.devMode:
		print("placed " + landmark.name + " at " + str(coord))
	tiles_node.add_child(landmark)

func revealCave(cave):
	for c in cave.tileCoords:
		var absCoord = cave.coord + c
		tileData.set_resource(absCoord.x, absCoord.y, - 1)
		onTileRemoved(absCoord)
		dig(absCoord)

func addDrop(drop):
	add_child(drop)

func freeTiles(tileCoords: Array)->int:
	var destroyed: = 0
	for c in tileCoords:
		if tiles.has(c):
			var tile = tiles[c]
			if tile.has_meta("destructable"):
				tile.hit(Vector2(0, - 1), tile.health)
				destroyed += 1
	return destroyed

func damageTileDirection(pos: Vector2, dir: Vector2, distance: int, damage: float, delay: = 0.0):
	if delay > 0.0:
		$Tween.interpolate_callback(self, delay, "damageTileDirection", pos, dir, distance, damage, 0.0)
		$Tween.start()
		return 

	var startCoord = getTileCoord(pos) + dir
	for i in distance:
		var coord = startCoord + dir * i
		if tiles.has(coord):
			var tile = tiles.get(coord)
			var v = coord - startCoord

			tile.hit(v, tile.max_health + 1)
			yield (get_tree().create_timer(0.08), "timeout")

func damageTileCircleArea(pos: Vector2, radius: float, damage: float, delay: = 0.0):
	if delay > 0.0:
		$Tween.interpolate_callback(self, delay, "damageTileCircleArea", pos, radius, damage, 0.0)
		$Tween.start()
		return 
	
	var startCoord = getTileCoord(pos)
	var open: = [startCoord]
	var closed: = []
	while open.size() > 0:
		var newOpen: = []
		for coord in open:
			if closed.has(coord):
				continue
			
			for off in NEIGHBOR_TILE_OFFSETS1:
				var c2 = off + coord
				if (c2 - startCoord).length() <= radius and not closed.has(c2) and not newOpen.has(c2):
					newOpen.append(c2)
			
			if tiles.has(coord):
				var tile = tiles.get(coord)
				var v = coord - startCoord

				tile.hit(v, tile.max_health + 1)
			closed.append(coord)
		
		yield (get_tree().create_timer(0.08), "timeout")
		open = newOpen

func getTileCoord(pos: Vector2):
	return tileData.world_to_map(pos + mapToWorldOffset)

func getTilePos(coord: Vector2):
	return tileData.map_to_world(coord) + tileData.position
	
func unlockGadget(data: Dictionary):
	if data.get("id", "") == "lift":
		lift = preload("res://content/gadgets/lift/Lift.tscn").instance()
		add_child(lift)
		updateLiftLength()
		

func updateLiftLength():
	var goalY: = 0
	for y in tileData.getSize().y + 20:
		var hardness = tileData.get_hardness(0, y)


		if tileData.get_resource(0, y) == - 1 and hardness >= 0:
			goalY = y + 1
		elif hardness >= 0 and hardness <= 4:
			break
	for i in range(lift.tileLength, goalY):
		border_deco.markTileUndecoratable(Vector2(0, i))
		border_deco.markTileUndecoratable(Vector2( - 1, i))
	lift.setLength(goalY)

func getProgress()->float:
	var layerCount = startingIronCountByLayer.size()
	if layerCount == 0:
		return 0.0

	var progress = 0.0
	for layer in startingIronCountByLayer:
		progress += 1.0 - (currentIronCountByLayer[layer] / float(startingIronCountByLayer[layer]))
	progress /= layerCount


	return progress

func growRootsOnTile(coord: Vector2):
	if tiles.has(coord):
		tiles.get(coord).root()
	else:
		futureRoots.append(coord)

func isResourceTile(typeId: int)->bool:
	return typeId == Data.TILE_IRON or typeId == Data.TILE_SAND or typeId == Data.TILE_WATER

func isRevealed(coord: Vector2)->bool:
	return tiles.has(coord)

func getTile(coord: Vector2):
	return tiles.get(coord, null)

func serialize()->Dictionary:
	var tileSpecial = {}
	for t in tiles.keys():
		if tiles[t].health < tiles[t].max_health or tiles[t].hasRoots:
			tileSpecial[var2str(t)] = tiles[t].serialize()
	var data = {
		"TileSpecial": tileSpecial, 
		"dropDeltas": dropDeltas, 
		"Biomes": biomes, 
		"StartingIronCountByLayer": startingIronCountByLayer, 
		"CurrentIronCountByLayer": currentIronCountByLayer, 
	}
	return data

func deserialize(data: Dictionary):
	tileDestroyedListeners = {}
	tileRevealedListeners = {}
	for child in tiles_node.get_children(): child.free()
	
	if data.has("Biomes"):
		biomes = data["Biomes"]
	
	init(true)
	revealInitialState()
	
	if data.has("StartingIronCountByLayer"):
		startingIronCountByLayer = {}
		for key in data["StartingIronCountByLayer"].keys():
			startingIronCountByLayer[int(key)] = data["StartingIronCountByLayer"][key]
		
	if data.has("CurrentIronCountByLayer"):
		currentIronCountByLayer = {}
		for key in data["CurrentIronCountByLayer"].keys():
			currentIronCountByLayer[int(key)] = data["CurrentIronCountByLayer"][key]
	
	dropDeltas = data.get("dropDeltas", {})

	
	for t in tileCoordsToReveal:
		revealTile(t)
	tileCoordsToReveal.clear()
	
	if data.has("TileSpecial"):
		for key in data["TileSpecial"].keys():
			var t = str2var(key)
			if tiles.has(t):
				tiles[t].deserialize(data["TileSpecial"][key])

func hideTiles():
	tiles_node.hide()
	tile_borders_node.hide()
	border_deco.hide()
	$MainTileRender.hide()
	$BackgroundTileRender.hide()
	$LightSprite.hide()

func showTiles():
	tiles_node.show()
	tile_borders_node.show()
	border_deco.show()
	$MainTileRender.show()
	$BackgroundTileRender.show()
	$LightSprite.show()

func tileData()->TileData:
	return tileData

func getBiomeOfCoord(coord: Vector2)->String:
	var b = tileData.get_biomev(coord)
	if b >= 0 and b < biomes.size():
		return biomes[b]
	else:
		return ""

func getLayerOfCoord(coord: Vector2)->int:
	var b = tileData.get_biomev(coord)
	return b

func addSpriteToBGAlpha(_new_sprite: Sprite):
	var bg_alpha_pos_offset = Vector2($ViewportBackgroundAlpha.size.x / 2, 48)
	var alpha_sprite_pos = _new_sprite.global_position + bg_alpha_pos_offset + mapToWorldOffset
	var alpha_sprite = _new_sprite.duplicate()
	alpha_sprite.show()
	$ViewportBackgroundAlpha / AlphaImages.add_child(alpha_sprite)
	alpha_sprite.position = alpha_sprite_pos
	$ViewportBackgroundAlpha.render_target_clear_mode = Viewport.CLEAR_MODE_ONLY_NEXT_FRAME
	$ViewportBackgroundAlpha.render_target_update_mode = Viewport.UPDATE_ONCE

func toggleTileDataVisibility():
	tileData.visible = not tileData.visible
