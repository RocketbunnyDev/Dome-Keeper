extends Node2D

signal landed

const Debris = preload("res://stages/landing/Debris.tscn")
var canEnd: = false

var countdown: = 8.0

func _ready():
	Style.init($Impact)
	Style.init($SmokeParticles)

	Level.dome.hide()
	Level.keeper.hide()
	Level.map.hideTiles()

	global_position = Level.dome.global_position
	
	$AnimationPlayer.play("landing")

func impact():
	$Impact.play("impact")
	Level.stage.camera.shake(200, 6.0)
	Level.world.domeImpact()
	for _i in range(20):
		var d = Debris.instance()
		add_child(d)

func reveal():
	Level.dome.show()
	Level.keeper.show()
	Level.map.showTiles()

func _process(delta):
	if canEnd and not GameWorld.paused:
		var input: bool = Level.keeper.moveDirectionInput.length() > 0.0
		countdown -= delta
		if input or countdown <= 0.0:
			canEnd = false
			GameWorld.goalCameraZoom = 4
			queue_free()

func allowEnd():
	emit_signal("landed")
	canEnd = true
