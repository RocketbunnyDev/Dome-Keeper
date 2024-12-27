extends Node2D

class_name TileData

func _ready():
	$Biomes.set_owner(self)
	$Resources.set_owner(self)
	$Hardness.set_owner(self)

func get_biome(x: int, y: int)->int:
	var biome = $Biomes.get_cell(x, y) - 10
	if biome <= 0: biome = 0
	return biome

func get_biomev(coord: Vector2)->int:
	var biome = $Biomes.get_cellv(coord) - 10
	if biome <= 0: biome = 0
	return biome

func set_biome(x: int, y: int, val: int):
	$Biomes.set_cell(x, y, val + 10)

func set_biomev(v: Vector2, val: int):
	$Biomes.set_cellv(v, val + 10)

func get_hardness(x: int, y: int)->int:
	return $Hardness.get_cell(x, y) - 13

func set_hardness(x: int, y: int, val: int):
	$Hardness.set_cell(x, y, val + 13)

func get_hardnessv(v: Vector2)->int:
	return $Hardness.get_cellv(v) - 13

func set_hardnessv(v: Vector2, val: int):
	$Hardness.set_cellv(v, val + 13)

func get_resource(x: int, y: int)->int:
	return $Resources.get_cell(x, y)

func set_resource(x: int, y: int, val: int):
	$Resources.set_cell(x, y, val)

func get_resourcev(v: Vector2)->int:
	return $Resources.get_cellv(v)

func set_resourcev(v: Vector2, val: int):
	$Resources.set_cellv(v, val)

func is_area_free(start: Vector2, offsets: Array)->bool:
	for c in offsets:
		var absCoord = start + c
		if get_resourcev(absCoord) != 10:
			return false
	return true

func clear_cell(x: int, y: int):
	$Biomes.set_cell(x, y, - 1)
	$Resources.set_cell(x, y, - 1)

func clear_resource(x: int, y: int):
	$Resources.set_cell(x, y, - 1)

func getRevealedCells()->Array:
	var cells: = []
	for cell in $Hardness.get_used_cells():
		if $Resources.get_cellv(cell) == - 1:
			cells.append(cell)
	return cells

func get_biome_cells_by_index(index: int)->Array:
	return $Biomes.get_used_cells_by_id(10 + index)
	
func get_resource_cells_by_id(id: int)->Array:
	return $Resources.get_used_cells_by_id(id)

func get_hardness_cells_by_grade(grade: int)->Array:
	return $Hardness.get_used_cells_by_id(grade + 13)

func get_tile_count()->int:
	return $Biomes.get_used_cells().size()

func get_mineable_tile_count()->int:
	var all = $Resources.get_used_cells().size()
	return all - $Resources.get_used_cells_by_id(21).size()

func getSize()->Vector2:
	return $Resources.get_used_rect().size

func getMaxSize()->Vector2:
	var resource_rect: Rect2 = $Resources.get_used_rect()
	var x = max(abs(resource_rect.position.x), resource_rect.size.x - abs(resource_rect.position.x))
	var padding = Vector2(2, 2)
	return Vector2(x * 2, resource_rect.size.y) + padding

func getMapSizePx()->Vector2:
	return - $Biomes.get_used_rect().position + $Biomes.get_used_rect().size * GameWorld.TILE_SIZE

func world_to_map(pos: Vector2)->Vector2:
	return $Biomes.world_to_map(pos)

func map_to_world(pos: Vector2)->Vector2:
	return $Biomes.map_to_world(pos)

func pack()->PackedScene:
	var packed_scene = PackedScene.new()
	packed_scene.pack(self)
	return packed_scene
