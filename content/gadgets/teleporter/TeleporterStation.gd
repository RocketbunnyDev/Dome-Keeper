extends "res://content/gadgets/CellarGadget.gd"

var hasTeleporter: = true
var teleporter

func _ready():
	$Sprite.play("default")
	
	Style.init(self)
	
	Level.addTutorial(self, "teleporter_take")

func serialize()->Dictionary:
	var data = .serialize()
	data["hasTeleporter"] = hasTeleporter
	return data

func deserialize(data: Dictionary):
	.deserialize(data)
	hasTeleporter = data["hasTeleporter"]
	for teleporter in get_tree().get_nodes_in_group("teleporters"):
		teleporter.station = self
		setTeleporter(teleporter)

func useHold(keeper: Keeper)->bool:
	if hasTeleporter:
		return useHit(keeper)
	return false

func canFocusUse()->bool:
	return true

func setTeleporter(new_teleporter):
	teleporter = new_teleporter
	teleporter.station = self
	hasTeleporter = false
	$Teleporter.queue_free()

func useHit(keeper: Keeper)->bool:
	if hasTeleporter:
		teleporter = preload("res://content/gadgets/teleporter/Teleporter.tscn").instance()
		teleporter.position = $DropPosition.global_position
		Level.map.addDrop(teleporter)
		keeper.attachCarry(teleporter)
		setTeleporter(teleporter)
		return true
	elif teleporter and Data.of("teleporter.teleportTo"):
		teleporter.teleporting = true
		var shrinkTime: = min(2.0, Data.of("teleporter.teleportDuration") * 0.33)
		var transitionTime: float = Data.of("teleporter.teleportDuration") - (2 * shrinkTime)
		keeper.shrink(shrinkTime, teleportPosition())
		$Timer.wait_time = shrinkTime
		$Timer.start()
		yield ($Timer, "timeout")
		keeper.teleport(teleporter.global_position)
		keeper.grow(shrinkTime, transitionTime - 0.2)
		Level.stage.startEffect("dissolveTransition", [transitionTime])
		teleporter.onTeleported()
		teleporter.teleporting = false
		return true
	else:
		return false

func onTeleported():
	pass

func teleportPosition()->Vector2:
	return $DropPosition.global_position

func pauseChanged():
	$Timer.paused = GameWorld.paused
