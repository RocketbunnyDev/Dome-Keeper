extends "res://content/map/chamber/Chamber.gd"

func _ready():
	set_process(false)
	var variant = randi() % 5
	$Background.frame = variant
	$Eye.frame = 5 + variant
	$Front.frame = 10 + variant

func serialize()->Dictionary:
	var data = .serialize()
	data["variant"] = $Background.frame
	return data
	
func deserialize(data: Dictionary):
	.deserialize(data)
	var variant = data["variant"]
	$Background.frame = variant
	$Eye.frame = 5 + variant
	$Front.frame = 10 + variant

func onExcavated():
	set_process(true)

func _process(delta):
	var deltaPos = Level.keeper.global_position - (global_position + $Background.offset)

	$Background.modulate.r = clamp(120.0 / deltaPos.length(), 1.0, 5.0)


	deltaPos = (deltaPos * 0.1).clamped(3)
	$Eye.position = deltaPos

func getTileType()->int:
	return Data.TILE_SAND
