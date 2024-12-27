extends "res://content/map/chamber/Chamber.gd"

var id: int
var ownedCables: = []

func _ready():
	$Sprite.visible = false
	Data.changeByInt("map.remainingrelicswitches", 1)
	id = Data.of("map.remainingrelicswitches")
	connect_cables()
	chamberType = Data.TILE_RELIC_SWITCH

func connect_cables():
	for chamber in get_tree().get_nodes_in_group("chamber"):
		if chamber.type == CONST.RELIC:
			chamber.connect("relic_taken", self, "deactivate")
			
			var destinationPos = chamber.getCenter() + chamber.global_position
			var cable = preload("res://content/map/chamber/relicswitch/Cable.tscn").instance()
			addCable(cable)
			cable.asChamberCable()
			cable.setDestinationPos(destinationPos)
			ownedCables.append(cable)
			chamber.connect("relic_taken", cable, "deactivate")
			Level.map.addTileDestroyedListener(cable, Level.map.getTileCoord(cable.global_position))
			
			var originPos = getCenter() + global_position
			
			var lastPosition = cable.global_position
			var delta = destinationPos - originPos
			var connectingCables = max(0, round(rand_range(0.8, 1.2) * ((delta.length() - 48) / (4 * GameWorld.TILE_SIZE))))
			for i in connectingCables:
				var offset = rand_range(0.8, 0.95) * ((i + 1) / float(connectingCables + 1))
				var pos = originPos + delta * offset
				var coord = Level.map.getTileCoord(pos)
				cable = preload("res://content/map/chamber/relicswitch/Cable.tscn").instance()
				get_parent().add_child(cable)
				ownedCables.append(cable)
				cable.setDestinationPos(originPos, lastPosition)
				cable.position = coord * GameWorld.TILE_SIZE
				Level.map.addTileDestroyedListener(cable, coord)
				lastPosition = cable.global_position
				chamber.connect("relic_taken", cable, "deactivate")
			
			cable = preload("res://content/map/chamber/relicswitch/Cable.tscn").instance()
			chamber.addCable(cable)
			cable.asChamberCable(true)
			cable.setDestinationPos(originPos)
			ownedCables.append(cable)
			chamber.connect("relic_taken", cable, "deactivate")
			Level.map.addTileDestroyedListener(cable, Level.map.getTileCoord(cable.global_position))
			break

func deserialize(data: Dictionary):
	.deserialize(data)
	if currentState == State.REVEALED:
		pass
	if currentState == State.OPEN or currentState == State.OPENING:
		$Sprite.show()
		$Sprite.play("opening")
		$Sprite.frame = $Sprite.frames.get_frame_count("opening") - 1
	if currentState == State.EMPTY:
		$Sprite.show()

	
	if ownedCables.size() == 0:
		yield (GameWorld, "savegame_loaded")
		connect_cables()

	for cable in ownedCables:
		var coord = Level.map.getTileCoord(cable.position)
		if not Level.map.tiles.has(coord):
			cable.show()

func deactivate():
	$Sprite.play("deactivated")
	$Light.light_active = false
	$ChamberAmbOpen.queue_free()

func onExcavated():
	yield (get_tree().create_timer(1.0), "timeout")
	$Sprite.play("opening")
	$DoorOpen.play()

func onRevealed():
	$Sprite.play("default")
	$Sprite.visible = true
	$ChamberAmbClosed.play()

func _on_Sprite_animation_finished():
	if $Sprite.animation == "opening":
		currentState = State.OPEN
	elif $Sprite.animation == "empty":
		$Light.light_active = true
		$Sprite.play("running")

func onUsed():
	$Sprite.play("empty")
	Data.changeByInt("map.remainingrelicswitches", - 1)
	$Usable.queue_free()
	$ChamberSwitchHit.play()
	$ChamberAmbClosed.stop()
	$ChamberAmbClosed.queue_free()
	$ChamberAmbOpen.play()
	
	for cable in ownedCables:
		cable.activate()
		yield (get_tree().create_timer(0.5), "timeout")
	
func _on_Sprite_frame_changed():
	if $Sprite.animation == "opening" and $Sprite.frame == 2:
		pass

func addCable(cable):
	$Sprite.add_child(cable)
	cable.centerOffset = 11
