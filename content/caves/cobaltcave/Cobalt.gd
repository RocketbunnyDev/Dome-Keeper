extends Sprite

var taken: = false

func _ready():
	Style.init(self)

func canFocusUse()->bool:
	return not taken

func useHold(keeper: Keeper):
	return useHit(keeper)

func useHit(keeper: Keeper)->bool:
	if taken:
		return false
	taken = true
	
	var drop = preload("res://content/drop/sand/SandDrop.tscn").instance()
	drop.position = global_position
	Level.map.addDrop(drop)
	keeper.attachCarry(drop)
	queue_free()
	return true
