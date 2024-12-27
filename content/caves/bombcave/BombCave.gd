extends "res://content/caves/Cave.gd"

var hasBomb: = true

func _ready():
	Style.init(find_node("FocusMarker"))
	Level.map.addSpriteToBGAlpha($AlphaMap)
	$Sprite.play("default")

func serialize()->Dictionary:
	var data = .serialize()
	data["hasBomb"] = hasBomb
	return data
	
func deserialize(data: Dictionary):
	.deserialize(data)
	hasBomb = data["hasBomb"]
	if not hasBomb:
		$Sprite.play("empty")
	if currentState == State.REVEALED:
		find_node("AmbSound").play()
	
func onRevealed():
	find_node("AmbSound").play()

func canFocusUse()->bool:
	return hasBomb

func useHold(keeper: Keeper):
	return useHit(keeper)

func useHit(keeper: Keeper)->bool:
	if not hasBomb:
		return false
	
	$BombTakenSound.play()
	$Sprite.play("empty")
	hasBomb = false
	
	var gizmo = preload("res://content/caves/bombcave/CaveBomb.tscn").instance()
	gizmo.position = $Usable.global_position
	Level.map.addDrop(gizmo)
	Level.keeper.attachCarry(gizmo)
	return true
