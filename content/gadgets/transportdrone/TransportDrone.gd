extends Node2D

signal request_path_home

enum State{WAIT, PICKUP, WAIT_FOR_PATH_HOME, RETRIEVE}


var state: int = State.WAIT

var cooldown: float
var carriedResource: String
var targettedDrop
var targetSpot: Vector2
var linear_velocity: Vector2

var currentPath: Array
var hasDroneHub: = false

func _ready():
	Style.init(self)
	setCarriedResource("")
	
	for hub in get_tree().get_nodes_in_group("dronehub"):
		hub.assignDrone(self)

func _process(delta):
	if GameWorld.softPaused():
		return 
	
	if cooldown > 0.0:
		cooldown -= delta
		return 
	
	match int(state):
		State.WAIT:
			
			$MoveAmb.stop()
			$Sprite.play("idle")
			$Sprite.speed_scale = 1.0
		State.PICKUP:
			if not canTransport(targettedDrop):
				targettedDrop = null
				state = State.WAIT
				return 
			
			if not $MoveAmb.playing:
				$MoveAmb.play()
			
			if currentPath.size() == 0:
				$Sprite.play("idle")
				var d = targetSpot - $PickupSpot.global_position
				if d.length() >= GameWorld.TILE_SIZE or not is_instance_valid(targettedDrop) or (targettedDrop.global_position - $PickupSpot.global_position).length() > GameWorld.TILE_SIZE:
					targettedDrop = null
					state = State.WAIT
					return 
				if d.length() < 1.0:
					targettedDrop.remove()
					targetSpot = Level.dome.getDropTarget(targettedDrop.type).dropTarget()
					setCarriedResource(targettedDrop.type)
					state = State.WAIT_FOR_PATH_HOME
					emit_signal("request_path_home")
					$Sprite.speed_scale = 1.0
				else:
					move(d.normalized(), 10.0, delta)
			else:
				followPath(delta)
		State.RETRIEVE:
			if not $MoveAmb.playing:
				$MoveAmb.play()
			
			if currentPath.size() == 0:
				$Sprite.play("idle")
				var d = targetSpot - global_position
				if d.length() < 1.0:
					Data.changeByInt("inventory." + carriedResource, 1)
					setCarriedResource("")
					state = State.WAIT
					$Sprite.speed_scale = 1.0
				else:
					move(d.normalized(), 30.0, delta)
			else:
				followPath(delta)
		State.WAIT_FOR_PATH_HOME:
			
			$Sprite.play("idle")
			$Sprite.speed_scale = 1.0
			emit_signal("request_path_home")
			cooldown = 0.5
			$MoveAmb.stop()

func followPath(delta: float):
	var nextPoint = currentPath[0]
	var d = nextPoint - position
	if d.length() < 6.0:
		currentPath.remove(0)
	move(d.normalized(), 50.0, delta)

func move(direction: Vector2, speed: float, delta: float):
	if carriedResource != "":
		speed *= 0.75
	$Sprite.speed_scale = 0.5 + speed / 100.0
	linear_velocity = lerp(linear_velocity, direction * speed, delta * 6)
	position += linear_velocity * delta
	if direction.length() <= 0.1:
		$Sprite.play("idle")
	elif abs(direction.y) > abs(direction.x):
		var prefix = "carry_" if carriedResource != "" else "move_"
		if direction.y < 0.0:
			$Sprite.play(prefix + "up")
		else:
			$Sprite.play(prefix + "down")
	else:
		var prefix = "carry_" if carriedResource != "" else "move_"
		if direction.x < 0.0:
			$Sprite.play(prefix + "left")
		else:
			$Sprite.play(prefix + "right")

func canTransport(drop)->bool:
	return not (drop.deactivated or drop.independent or drop.isCarried() or drop.hasCarryInfluence())

func sortByDistance(a, b):
	return (a.position - position).length() < (b.position - position).length()

func targetDrop(drop, path):
	targettedDrop = drop
	targetSpot = targettedDrop.global_position - $PickupSpot.position
	state = State.PICKUP
	currentPath = path


func setPathHome(path):
	state = State.RETRIEVE
	currentPath = path
	









func setCarriedResource(res: String):
	carriedResource = res
	match res:
		"":
			$CarriedResource.texture = null
			$Sprite.play("idle")
		CONST.IRON:
			$CarriedResource.texture = preload("res://content/drop/iron/iron_smol.png")
			$Sprite.play("idle")
			$PickupSound.play()
		CONST.WATER:
			$CarriedResource.texture = preload("res://content/drop/water/water_smol.png")
			$Sprite.play("idle")
			$PickupSound.play()
		CONST.SAND:
			$CarriedResource.texture = preload("res://content/drop/sand/sand_smol.png")
			$Sprite.play("idle")
			$PickupSound.play()

func serialize()->Dictionary:
	var data = {}
	data["meta.priority"] = 100
	data["meta.kind"] = "generic"
	data["state"] = state
	data["cooldown"] = cooldown
	data["carriedResource"] = carriedResource
	return data
	
func deserialize(data: Dictionary):
	state = data["state"]
	if state == State.RETRIEVE:
		state = State.WAIT_FOR_PATH_HOME
	elif state == State.PICKUP:
		state = State.WAIT
	
	cooldown = data["cooldown"]
	carriedResource = data["carriedResource"]
	setCarriedResource(carriedResource)

func _on_Sprite_frame_changed():
	match $Sprite.animation:
		"carry_up":
			match $Sprite.frame:
				0: $CarriedResource.position.y = 8
				1: $CarriedResource.position.y = 10
				2: $CarriedResource.position.y = 11
				3: $CarriedResource.position.y = 10
				4: $CarriedResource.position.y = 7
				5: $CarriedResource.position.y = 7
		"carry_down":
			if $Sprite.frame >= 2 and $Sprite.frame <= 4:
				$CarriedResource.position.y = 7
			else:
				$CarriedResource.position.y = 8
		_:
			$CarriedResource.position.y = 8
