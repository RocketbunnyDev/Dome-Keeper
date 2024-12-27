extends Node2D

export (String) var id: = ""
export (bool) var looksLeft: = false

var positions
var supportedPositions: = []
var currentPos: String
var currentActions: = []

var switchCooldown: = 0.0

func _ready():
	Style.init(self)
	
	var scenePath = "res://content/pets/" + id + "/Positions" + Data.startCaptialized(Level.domeId()) + ".tscn"
	var scene = load(scenePath)
	if scene:
		positions = scene.instance()
		Level.dome.add_child(positions)
	else:
		Logger.error("pet positions missing", "Pet.ready", scenePath)
		queue_free()
		return 
	
	for a in $Sprite.frames.get_animation_names():
		if a.find("idle") != - 1:
			var posId = a.substr(3, a.find("_") - 3)
			supportedPositions.append("pos" + posId)
	
	findRandomPlace()
	
	add_to_group("lostL")
	
	Data.apply("keeper.additionalmaxspeed", 4.0)

func _process(delta):
	if GameWorld.devMode and Input.is_action_just_pressed("f4"):
		findRandomPlace()
	if switchCooldown > 0.0:
		switchCooldown -= delta
	else:
		if Level.keeper and Level.keeper.global_position.y >= 200.0:
			findRandomPlace()

func findRandomPlace():
	var consideredPositions: = []
	for place in positions.get_children():
		var pos = "pos" + place.name.substr(8, 1)
		if supportedPositions.has(pos):
			consideredPositions.append(place)
	
	if consideredPositions.size() > 1 and consideredPositions.has(currentPos):
		consideredPositions.erase(currentPos)
	
	if consideredPositions.empty():
		visible = false
		return 
	
	var place = consideredPositions[randi() % consideredPositions.size()]
	currentPos = "pos" + place.name.substr(8, 1)
	if place.name.ends_with("left"):
		$Sprite.flip_h = not looksLeft
	elif place.name.ends_with("right"):
		$Sprite.flip_h = looksLeft
	else:
		$Sprite.flip_h = randf() > 0.5
	
	$Sprite.play(currentPos + "_idle")
	currentActions.clear()
	for a in $Sprite.frames.get_animation_names():
		if a.begins_with(currentPos) and a.find("action") != - 1:
			currentActions.append(a)
	
	position = place.position
	visible = true
	switchCooldown = 30.0

func _on_Sprite_animation_finished():
	if not visible:
		return 
	
	if $Sprite.animation == currentPos + "_idle" and currentActions.size() > 0 and randf() > 0.5:
		$Sprite.play(currentActions[randi() % currentActions.size()])
	else:
		$Sprite.play(currentPos + "_idle")

func onGameLost():
	visible = false
