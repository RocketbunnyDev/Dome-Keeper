extends "res://content/map/chamber/Chamber.gd"

signal relic_taken

var shouldOpen: = false

func _ready():
	$SpriteBack.visible = false
	$SpriteBack / SpriteFront.play("closed")
	$SpriteBack.play("running")
	chamberType = Data.TILE_RELIC

func deserialize(data: Dictionary):
	.deserialize(data)
	if currentState == State.REVEALED:
		pass
	if currentState == State.OPEN or currentState == State.OPENING:
		$SpriteBack.show()
		$SpriteBack / SpriteFront.play("opening")
		$SpriteBack / SpriteFront.frame = $SpriteBack / SpriteFront.frames.get_frame_count("opening") - 1
	if currentState == State.EMPTY:
		$SpriteBack.show()
		
func propertyChanged(property: String, oldValue, newValue):
	match property:
		
		"map.remainingrelicswitches":
			if newValue == 0:
				shouldOpen = true
				Data.unlisten(self, "map.remainingrelicswitches")

func _process(delta):
	if shouldOpen:
		if (Level.keeper.global_position - global_position).length() < GameWorld.TILE_SIZE * 6:
			open()
			shouldOpen = false

func onExcavated():
	if Data.of("map.remainingrelicswitches") == 0:
		open()
	else:
		
		Data.listen(self, "map.remainingrelicswitches")

func onOpening():
	$SpriteBack / SpriteFront.play("opening")
	
func onRevealed():
	$SpriteBack.visible = true
	$GizmoSpawn / ChamberAmb.play()

func onUsed():
	$DoorOpen.queue_free()
	$Usable.queue_free()
	$GizmoSpawn.queue_free()
	$Light.light_active = false
	$SpriteBack.play("empty")
	$GizmoSpawn / ChamberAmb.stop()
	emit_signal("relic_taken")
	
	Achievements.triggerIfOpen("RELICHUNT_RELICTAKEN")

func _on_SpriteFront_frame_changed():
	if $SpriteBack / SpriteFront.animation == "opening":
		if $SpriteBack / SpriteFront.frame == 1:
			$DoorOpen.play()
		elif $SpriteBack / SpriteFront.frame == 50:
			$Light.light_active = true
			Audio.stinger("stinger_relic_chamber_excavated_" + Level.keeperId())
		elif $SpriteBack / SpriteFront.frame == 65:
			currentState = State.OPEN

func addCable(cable):
	$SpriteBack / SpriteFront.add_child(cable)
	cable.centerOffset = 36

func getTileType()->int:
	return Data.TILE_RELIC
