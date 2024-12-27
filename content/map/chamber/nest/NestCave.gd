extends "res://content/caves/Cave.gd"

var hasEgg: = true

func _ready():
	$Sprite.play("egged")
	Style.init(find_node("FocusMarker"))

func serialize()->Dictionary:
	var data = .serialize()
	data["hasEgg"] = hasEgg
	return data
	
func deserialize(data: Dictionary):
	.deserialize(data)
	hasEgg = data["hasEgg"]
	if not hasEgg:
		$GizmoSpawn.queue_free()
		$Usable.queue_free()
		$Sprite.play("empty")

func updateUsedTileCoords():
	tileCoords.clear()
	tileCoords.append(Vector2(0, 0))
	tileCoords.append(Vector2(1, 0))
	tileCoords.append(Vector2(0, 1))
	tileCoords.append(Vector2(1, 1))

func canFocusUse()->bool:
	return hasEgg

func useHold(keeper: Keeper):
	return useHit(keeper)

func useHit(keeper: Keeper)->bool:
	if not hasEgg:
		return false
	
	hasEgg = false
	$Sprite.play("empty")
	$Usable.queue_free()
	$GizmoSpawn / AmbBird.stop()
	$GizmoSpawn / AmbCricket.stop()
	yield (get_tree().create_timer(0.5), "timeout")
	
	var gizmo = preload("res://content/drop/egg/Egg.tscn").instance()
	gizmo.position = find_node("GizmoSpawn").global_position
	Level.map.addDrop(gizmo)
	Level.keeper.attachCarry(gizmo)
	$GizmoSpawn.queue_free()
	
	return true

func onRevealed():
	$GizmoSpawn / AmbBird.play()
	$GizmoSpawn / AmbCricket.play()
