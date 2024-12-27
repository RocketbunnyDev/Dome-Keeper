extends Node2D

const BeeScene: = preload("res://content/monster/swarm/Bee.tscn")
const radius: = 20

var projectileTargets

func _ready()->void :
	spawn(20)

func spawn(size: int)->void :
	
	for _i in range(0, size):
		var bee = BeeScene.instance()
		add_child(bee)
		bee.swarmCenter = $GoalPosition
		bee.position.x = $GoalPosition.x + rand_range( - radius, radius)
		bee.position.y = $GoalPosition.y + rand_range( - radius, radius)

func move(by: Vector2):
	$GoalPosition.position += by
