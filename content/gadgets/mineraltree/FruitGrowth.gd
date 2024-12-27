extends Sprite

const dropPositions: = {
	0: Vector2(1, 0), 
	1: Vector2( - 2, 4), 
	2: Vector2( - 1, 1), 
	3: Vector2(0, 0), 
	4: Vector2( - 2, 3), 
	5: Vector2( - 2, 1), 
	6: Vector2(1, 0), 
	7: Vector2(0, 4), 
	8: Vector2( - 1, 1)
}

var totalCycles: int
var remainingCycles: int = - 1
var type: String = ""

func _ready():
	visible = false
	Style.init($Sprite)

func canFocusUse()->bool:
	return remainingCycles == 0 and type != ""

func useHold(keeper: Keeper):
	return useHit(keeper)

func useHit(keeper: Keeper)->bool:
	if canFocusUse():
		var res = spawnResource()
		keeper.attachCarry(res)
		clear()
		return true
	else:
		return true

func spawnResource():
	var res = Data.DROP_SCENES.get(type).instance()
	res.type = type
	res.position = $Sprite.global_position
	Level.map.addDrop(res)
	return res

func setType(type: String):
	match type:
		CONST.IRON:
			frame = - 1 + int(name.substr(name.find("_") + 1))
			$Sprite.texture = preload("res://content/drop/iron/iron_smol.png")
			totalCycles = 1
		CONST.WATER:
			frame = 2 + int(name.substr(name.find("_") + 1))
			$Sprite.texture = preload("res://content/drop/water/water_smol.png")
			totalCycles = 2
		CONST.SAND:
			frame = 5 + int(name.substr(name.find("_") + 1))
			$Sprite.texture = preload("res://content/drop/sand/sand_smol.png")
			totalCycles = 3
	$Sprite.position = dropPositions[frame]
	remainingCycles = totalCycles
	self.type = type

func progressCycle():
	if type == "":
		return 
	if remainingCycles > 0:
		remainingCycles -= 1
	if remainingCycles <= 0:
		visible = true

func clear():
	remainingCycles = - 1
	visible = false
	type = ""
