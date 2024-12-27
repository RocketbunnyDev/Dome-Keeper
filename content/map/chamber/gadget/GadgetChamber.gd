extends "res://content/map/chamber/Chamber.gd"

func _ready():
	$Sprite.visible = false
	$SocketedGizmo.visible = false
	chamberType = Data.TILE_GADGET

func deserialize(data: Dictionary):
	.deserialize(data)
	if currentState == State.REVEALED:
		pass
	if currentState == State.OPEN or currentState == State.OPENING:
		$Sprite.show()
		$Sprite.play("opening")
		$Sprite.frame = $Sprite.frames.get_frame_count("opening") - 1
		$SocketedGizmo.show()
	if currentState == State.EMPTY:
		$Sprite.show()
		
func onExcavated():
	$Sprite.play("opening")
	$DoorOpen.play()

func onRevealed():
	$Sprite.play("default")
	$Sprite.visible = true

func _on_Sprite_animation_finished():
	if $Sprite.animation == "opening":
		currentState = State.OPEN
		$SocketedGizmo.visible = true

func onUsed():
	$Sprite.play("empty")
	$SocketedGizmo.queue_free()
	$Usable.queue_free()
	$GizmoSpawn / ChamberAmb.queue_free()
	$DoorOpen.queue_free()
	$GizmoSpawn.queue_free()
	
func _on_Sprite_frame_changed():
	if $Sprite.animation == "opening" and $Sprite.frame == 7:
		Audio.stinger("stinger_gadget_chamber_excavated_" + Level.keeperId())
