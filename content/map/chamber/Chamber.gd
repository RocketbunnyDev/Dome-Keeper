extends Node2D

export (PackedScene) var GIZMO_SCENE: PackedScene
export (String) var type: = "chamber"

enum State{HIDDEN, REVEALED, OPENING, OPEN, EMPTY}
var currentState = State.HIDDEN

var tileCoords: = []
var coord: Vector2

var chamberType

func _ready():
	Style.init(self)
	
	$TileCover.modulate = Style.TILE_COVER_MODULATE

func serialize()->Dictionary:
	var tileCover = {}
	if has_node("TileCover"):
		for c in $TileCover.get_used_cells():
			tileCover[var2str(c)] = $TileCover.get_cell(c.x, c.y)

	var data = {
		"coord": var2str(coord), 
		"tileCoords": var2str(tileCoords), 
		"currentState": currentState, 
		"type": type, 
		"tileCover": tileCover
	}
	
	data["meta.priority"] = 100
	data["meta.kind"] = "chamber"
	data["meta.chamberType"] = chamberType
	data["meta.scenepath"] = filename
	
	return data
	
func deserialize(data: Dictionary):
	coord = str2var(data["coord"])
	tileCoords = str2var(data["tileCoords"])
	currentState = int(data["currentState"])
	type = data["type"]
	
	$TileCover.clear()
	for key in (data["tileCover"] as Dictionary).keys():
		var c = str2var(key)
		var v = int(data["tileCover"][key])
		$TileCover.set_cellv(c, v)

	
	
	
	for c in tileCoords:
		var absCoord = coord + c
		if $TileCover.get_cellv(c) == TileMap.INVALID_CELL:
			Level.map.onTileRemoved(absCoord)
		
	var remainingCells = $TileCover.get_used_cells().size()
	if remainingCells == 0 and currentState == State.REVEALED:
		onExcavated()

	if currentState == State.REVEALED:
		show()
		onRevealed()
		$TileCover.show()
	if currentState == State.OPEN or currentState == State.OPENING:
		show()
		currentState = State.OPEN
	if currentState == State.EMPTY:
		show()
		onUsed()
	
func place(c: Vector2):
	var cells = $TileCover.get_used_cells()
	for c in cells:
		tileCoords.append(c)
	coord = c
	position = coord * GameWorld.TILE_SIZE - Vector2(GameWorld.TILE_SIZE, GameWorld.TILE_SIZE) * 0.5
	visible = false

func tileDestroyed(tileCoord: Vector2):
	var c = tileCoord - coord
	$TileCover.set_cell(c.x, c.y, - 1)
	var remainingCells = $TileCover.get_used_cells().size()

	if remainingCells == 0 and currentState == State.REVEALED:
		onExcavated()

		
func open():
	currentState = State.OPENING
	$TileCover.queue_free()
	onOpening()
	Backend.event("chamber", {"status": "opened", "coord": tileCoords, "type": type})

func onRevealed():
	pass

func onExcavated():
	pass

func onUsed():
	pass

func onOpening():
	pass

func addCable(cable):
	pass

func tileRevealed(tileCoord: Vector2):
	if currentState == State.HIDDEN:
		currentState = State.REVEALED
		onRevealed()
		visible = true
		$TileCover.visible = true
		Backend.event("chamber", {"status": "revealed", "coord": tileCoords, "type": type})

func canFocusUse()->bool:
	return currentState == State.OPEN

func useHold(keeper: Keeper):
	return useHit(keeper)

func useHit(keeper: Keeper)->bool:
	if currentState == State.OPEN:
		if GIZMO_SCENE:
			var gizmo = GIZMO_SCENE.instance()
			gizmo.position = find_node("GizmoSpawn").global_position
			Level.map.addDrop(gizmo)
			Level.keeper.attachCarry(gizmo)
		currentState = State.EMPTY
		onUsed()
		Backend.event("chamber", {"status": "used", "coord": tileCoords, "type": type})
		return true
	else:
		return false

func getCenter()->Vector2:
	return $Usable.position

func getTileType()->int:
	return Data.TILE_GADGET
