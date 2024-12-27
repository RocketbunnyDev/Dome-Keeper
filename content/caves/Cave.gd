extends Node2D

export (String, "", "grey", "green", "red", "blue", "yellow") var biome: = ""
export (int) var minLayer: = 1
export (float) var minRelativeDepth: = 0.0
export (float) var maxRelativeDepth: = 0.8

enum State{HIDDEN, REVEALED}
var currentState = State.HIDDEN

var tileCoords: = []
var coord: Vector2

func _ready():
	Style.init(self)

func serialize()->Dictionary:
	var data = {
		"coord": var2str(coord), 
		"tileCoords": var2str(tileCoords), 
		"currentState": currentState, 
		"biome": biome
	}
	
	data["meta.priority"] = 100
	data["meta.kind"] = "cave"

	return data
	
func deserialize(data: Dictionary):
	coord = str2var(data["coord"])

	tileCoords = str2var(data["tileCoords"])
	biome = data["biome"]
	Level.map.addLandmark(coord, self)
	currentState = int(data["currentState"])

	hide()
	if currentState == State.REVEALED:
		show()
		
		
		
		
		for c in tileCoords:
			var absCoord = coord + c
			Level.map.onTileRemoved(absCoord)

	
	for c in tileCoords:
		var absCoord = coord + c
		Level.map.tileData.set_resource(absCoord.x, absCoord.y, Data.TILE_CAVE)
			
func updateUsedTileCoords():
	tileCoords.clear()
	for x in ceil($Sprites.rect_size.x / float(GameWorld.TILE_SIZE)):
		for y in ceil($Sprites.rect_size.y / float(GameWorld.TILE_SIZE)):
			tileCoords.append(Vector2(x, y))

func place(c: Vector2):
	coord = c
	position = coord * GameWorld.TILE_SIZE - Vector2(GameWorld.TILE_SIZE, GameWorld.TILE_SIZE) * 0.5
	visible = false

func tileRevealed(tileCoord: Vector2):
	if currentState == State.HIDDEN:
		currentState = State.REVEALED
		onRevealed()
		visible = true
		Level.map.revealCave(self)

func onRevealed():
	pass

func canFocusUse()->bool:
	return false

func useHold(keeper: Keeper):
	return useHit(keeper)

func useHit(keeper: Keeper)->bool:
	return false
