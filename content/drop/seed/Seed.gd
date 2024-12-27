extends Drop

var countDown: = 30.0

var settling: = false
var growing: = false
var averageAngularVelocity: = 0.0
var averageLinearVelocity: = 0.0
var targetTile

var collidingTiles: = []

func _ready():
	$Roots.visible = false
	if isCarried():
		settling = false
	else:
		settling = true
	
	Level.addTutorial(self, "mineraltree")

func serialize()->Dictionary:
	var data = .serialize()
	data["settling"] = settling
	data["growing"] = growing
	data["countDown"] = countDown
	if targetTile:
		data["targetTile"] = var2str(targetTile.coord)
	return data
	
func deserialize(data: Dictionary):
	.deserialize(data)
	settling = data["settling"]
	countDown = data["countDown"]
	if data["growing"]:
		$Roots.rotation = - rotation
		settled()
	if data.has("targetTile"):
		targetTile = Level.map.tiles[str2var(data["targetTile"])]
		targetTile.connect("destroyed", self, "onTargetTileDestroyed")
	
func settled():
	$Roots.visible = true
	$Roots.frame = 0
	$Roots.play("rooting")
	$TreePlantSound.play()
	mode = RigidBody2D.MODE_STATIC
	growing = true
	position.x = round(position.x)
	position.y = round(position.y)
	z_index = 1
	set_physics_process(false)

func onCarried(p: Keeper):
	if targetTile:
		targetTile.disconnect("destroyed", self, "onTargetTileDestroyed")
		targetTile = null
	uprooted()

func onDropped(p: Keeper):
	settling = true
	countDown = 30

func uprooted():
	settling = false
	growing = false
	mode = RigidBody2D.MODE_RIGID
	set_physics_process(true)
	$Roots.visible = false

func _physics_process(delta):
	averageAngularVelocity = averageAngularVelocity * (1 - delta) + abs(angular_velocity * delta)
	averageLinearVelocity = averageLinearVelocity * (1 - delta) + linear_velocity.length() * delta
	if settling:
		if targetTile:
			var deltaX = targetTile.global_position.x - global_position.x
			if abs(deltaX) <= 0.1:
				if averageAngularVelocity < 0.3:
					settled()
			else:
				apply_central_impulse(Vector2(sign(deltaX) * 1.5, 0))
		elif averageLinearVelocity < 1.0:
			for i in collidingTiles:
				if i.global_position.y > global_position.y\
				 and abs(global_position.x - i.global_position.x) <= GameWorld.TILE_SIZE * 0.5\
				 and i.type != "border":
					targetTile = i
					targetTile.connect("destroyed", self, "onTargetTileDestroyed")
					return 
	
	$Roots.rotation = - rotation

func onTargetTileDestroyed():
	targetTile = null
	uprooted()

func sprout():
	var tree = preload("res://content/gadgets/mineraltree/MineralTree.tscn").instance()
	tree.global_position = global_position
	tree.growOnTile(targetTile.coord)
	get_parent().add_child(tree)

func _process(delta):
	if growing:
		countDown -= delta
		
		if (countDown <= 0.0 and Level.keeper and Level.keeper.global_position.y < 0) or (GameWorld.devMode and Input.is_action_just_pressed("f4")):
			sprout()
			growing = false
			queue_free()

func _on_Seed_body_entered(body):
	if body is preload("res://content/map/tile/Tile.gd") and not collidingTiles.has(body):
		collidingTiles.append(body)
	_on_Drop_body_entered(body)

func _on_Seed_body_exited(body):
	if body is preload("res://content/map/tile/Tile.gd") and collidingTiles.has(body):
		collidingTiles.erase(body)
