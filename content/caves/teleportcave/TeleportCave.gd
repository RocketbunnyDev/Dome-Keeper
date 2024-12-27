extends "res://content/caves/Cave.gd"

var hasEye: = true

func _ready():
	Level.map.addSpriteToBGAlpha($AlphaMap)

func serialize()->Dictionary:
	var data = .serialize()
	data["hasEye"] = hasEye
	
	var hud = Level.hud.find_node("TeleporterHud", true, false)
	if hud and has_method("serialize"):
		data["hud"] = hud.serialize()
	
	return data
		
func deserialize(data: Dictionary):
	.deserialize(data)
	
	if currentState == State.REVEALED:
		find_node("Eye").play("default")
	
	hasEye = data["hasEye"]
	if not hasEye:
		find_node("Eye").queue_free()
		for s in $Sprites.get_children():
			s.frame += 4
		var hud = Level.hud.addHudElement({"hud": "content/caves/teleportcave/TeleporterHud.tscn"})
		if hud and hud.has_method("deserialize"):
			hud.deserialize(data["hud"])
	
func onRevealed():
	find_node("Eye").play("default")
	find_node("CaveAmb").play()

func canFocusUse()->bool:
	return hasEye

func useHold(keeper: Keeper):
	return useHit(keeper)

func useHit(keeper: Keeper)->bool:
	if hasEye:
		find_node("Eye").play("taken")
		$EyeCloseSound.play()
		hasEye = false
		find_node("CaveAmb").queue_free()
		return true
	else:
		return false

func _on_Eye_animation_finished():
	if find_node("Eye").animation == "taken":
		find_node("Eye").queue_free()
		for s in $Sprites.get_children():
			s.frame += 4
		Level.hud.addHudElement({"hud": "content/caves/teleportcave/TeleporterHud.tscn"})
