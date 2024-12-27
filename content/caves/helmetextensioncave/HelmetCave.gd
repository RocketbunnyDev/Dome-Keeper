extends "res://content/caves/Cave.gd"

var hasHelmet: = true

func _ready():
	Style.init(find_node("FocusMarker"))
	Level.map.addSpriteToBGAlpha($AlphaMap)
	$Sprite.play("default")

func serialize()->Dictionary:
	var data = .serialize()
	data["hasHelmet"] = hasHelmet
	return data
	
func deserialize(data: Dictionary):
	.deserialize(data)
	hasHelmet = data["hasHelmet"]
	if not hasHelmet:
		$Sprite.play("empty")
	if currentState == State.REVEALED:
		find_node("AmbSound").play()
	
func onRevealed():
	find_node("AmbSound").play()

func canFocusUse()->bool:
	return hasHelmet

func useHold(keeper: Keeper):
	return useHit(keeper)

func useHit(keeper: Keeper)->bool:
	if not hasHelmet:
		return false
	
	$HelmetTakenSound.play()
	$Sprite.play("empty")
	hasHelmet = false
	
	Data.apply("keeper.zoominmine", 3)
	return true
