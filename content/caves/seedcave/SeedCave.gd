extends "res://content/caves/Cave.gd"

var hasSeed: = true

func _ready():
	Style.init(find_node("FocusMarker"))
	Level.map.addSpriteToBGAlpha($AlphaMap)

func serialize()->Dictionary:
	var data = .serialize()
	data["hasSeed"] = hasSeed
	return data
	
func deserialize(data: Dictionary):
	.deserialize(data)
	hasSeed = data["hasSeed"]
	if not hasSeed:
		find_node("ActiveSprite").queue_free()
		find_node("AmbSound").queue_free()
	if currentState == State.REVEALED:
		find_node("AmbSound").play()
	
func onRevealed():
	find_node("AmbSound").play()

func canFocusUse()->bool:
	return hasSeed

func useHold(keeper: Keeper):
	return useHit(keeper)

func useHit(keeper: Keeper)->bool:
	if not hasSeed:
		return false
	
	find_node("AmbSound").queue_free()
	hasSeed = false
	find_node("ActiveSprite").queue_free()
	var gizmo = Data.DROP_SCENES.get(CONST.SEED).instance()
	gizmo.position = $Usable.global_position
	Level.map.addDrop(gizmo)
	Level.keeper.attachCarry(gizmo)
	return true
