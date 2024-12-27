extends Keeper

var markedTiles: = []
var drones: = []
var markers: = {}

var marker = preload("res://content/keeper/keeper4/marker.png")
var DRONE_SCENE = preload("res://content/keeper/keeper4/drone/Drone.tscn")

func _process(delta):
	if Input.is_action_just_pressed("ui_focus_next"):
		spawnDrone()

func _on_TileHitArea_body_entered(body):
	if body.has_meta("destructable") and body.get_meta("destructable"):
		pass

func currentSpeed()->float:
	var s = Data.of("keeper4.maxSpeed") + Data.of("keeper.additionalmaxspeed")
	if Data.of("keeper.buffed"):
		s += Data.of("keeper.speedBuff")
	return s

func markTile(body):
	markedTiles.append(body)
	body.connect("destroyed", self, "unmarkTile", [body])
	var s = Sprite.new()
	s.texture = marker
	s.z_index = 2
	body.add_child(s)
	markers[body] = s
	
	for d in drones:
		if d.target == self:
			d.target = body
			return 

func unmarkTile(body):
	body.disconnect("destroyed", self, "unmarkTile")
	markedTiles.erase(body)
	markers[body].queue_free()
	
	for d in drones:
		if d.target == body:
			d.target = self

func spawnDrone():
	var drone = DRONE_SCENE.instance()
	drone.position = position
	Level.stage.add_child(drone)
	drone.setTarget(self)
	drones.append(drone)
	
