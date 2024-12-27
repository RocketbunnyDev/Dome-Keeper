extends "res://content/caves/Cave.gd"

var hasDrone: = true
var opening: = false

func _ready():
	Level.map.addSpriteToBGAlpha($AlphaMap)
	$Drone.visible = true
	$Door.play("default")
	$Drone.play("idle")
	
	Style.init($Drone)

func serialize()->Dictionary:
	var data = .serialize()
	data["hasDrone"] = hasDrone
	data["opening"] = opening
	data["resourceused"] = $ResourceGrabber.spent
	return data
	
func deserialize(data: Dictionary):
	.deserialize(data)
	hasDrone = data["hasDrone"]
	opening = data["opening"]
	$ResourceGrabber.spent = data.get("resourceused", false)
	
	if not hasDrone:
		$Drone.visible = false
		$Door.visible = false
	if opening:
		$Door.play("opening")
	
	if currentState == State.REVEALED:
		find_node("AmbSound").play()

func onRevealed():
	find_node("AmbSound").play()

func _on_Door_animation_finished():
	if $Door.animation == "opening" and hasDrone:
		$Door.visible = false
		
		$Tween.interpolate_callback(self, 2.0, "spawnDrone")
		$Tween.start()

func spawnDrone():
	var gizmo = preload("res://content/gadgets/transportdrone/TransportDrone.tscn").instance()
	gizmo.position = $Drone.global_position
	$Drone.queue_free()
	Level.map.addDrop(gizmo)
	$DroneHub.assignDrone(gizmo)
	hasDrone = false
	opening = false
	$Background / DroneTakenSound.play()

func _on_ResourceGrabber_grabbed_resource():
	$Door.play("opening")
	$DoorOpenSound.play()
	opening = true
