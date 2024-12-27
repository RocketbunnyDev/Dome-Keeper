extends Area2D

onready var particles: = $CollisionShape2D / Particles2D
const LiftOrb = preload("res://content/gadgets/lift/LiftOrb.tscn")

var liftedRigids: = []
var tileLength: int = - 1
var orbCooldown: float
var keeperInsideLift: = false
var addedSpeed: = 0.0
var orbState = []
var queuedOrbs = 0

func _ready():
	$build.play("default")
	$build.hide()
	
	Data.listen(self, "lift.orbs", true)
	
	Style.init(self)
	
	Achievements.addIfOpen(self, "LIFT_JAM")
	Achievements.addIfOpen(self, "LIFT_TRANSPORT")

func serialize()->Dictionary:
	orbState = []
	for lo in get_tree().get_nodes_in_group("lift_orbs"):
		orbState.append(lo.serialize())
		
	var data = {
		"tileLength": tileLength, 
		"orbState": orbState, 
		"keeperInsideLift": keeperInsideLift, 
		"addedSpeed": addedSpeed, 
	}

	data["meta.priority"] = 200
	data["meta.kind"] = "station"
	
	return data

func deserialize(data: Dictionary):
	Level.map.lift = self
	setLength(int(data["tileLength"]))
	$Tween.seek($Tween.get_runtime())
	orbState = data["orbState"]
	keeperInsideLift = data["keeperInsideLift"]
	addedSpeed = data["addedSpeed"]
	
func propertyChanged(property: String, oldValue, newValue):
	match property:
		
		"lift.orbs":
			var diff = newValue - get_tree().get_nodes_in_group("lift_orbs").size() - queuedOrbs
			for _i in diff:
				spawnOrb()

func getTopOfLift()->float:
	return - 40.0
		
func getBottomOfLift()->float:
	return position.y + $Sprite.region_rect.size.y + 24
	
func getLength()->float:
	return getBottomOfLift() - getTopOfLift()
	
func setLength(tileLength: int):
	if tileLength == self.tileLength:
		return 
	
	var goal = GameWorld.TILE_SIZE * tileLength + 14 + GameWorld.TILE_SIZE
	var growth = goal - $Sprite.region_rect.size.y
	if growth <= 0:
		return 
	
	var duration = growth / float(GameWorld.TILE_SIZE)
	self.tileLength = tileLength
	
	$Tween.stop_all()
	$Tween.remove_all()
	$Tween.interpolate_property($Sprite, "region_rect:size:y", $Sprite.region_rect.size.y, goal, duration, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	$Tween.interpolate_property($OverlaySprite, "region_rect:size:y", $OverlaySprite.region_rect.size.y, goal, duration, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	$Tween.interpolate_property($CollisionShape2D, "position:y", $CollisionShape2D.position.y, $Sprite.position.y + goal * 0.5, duration, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	$Tween.interpolate_property($CollisionShape2D, "shape:extents:y", $CollisionShape2D.shape.extents.y, goal * 0.5, duration, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	
	particles.amount = max(1, 5 * tileLength)
	$Tween.interpolate_property(particles, "process_material:emission_box_extents:y", particles.process_material.emission_box_extents.y, goal * 0.5, duration, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	$Tween.start()
	$build.show()
	$build / buildSfx.play()

func _physics_process(delta):
	for b in liftedRigids:
		if b.independent:
			
			continue
		var impulseX = clamp( - b.linear_velocity.x * 0.15, - 20.0, 20.0) + clamp( - b.position.x, - 1.0, 1.0)
		var impulseY = clamp( - Data.of("lift.speed") - b.linear_velocity.y, - 8, 0)
		impulseY = 0
		if abs(b.position.x - position.x) > 12:
			b.apply_central_impulse(Vector2(impulseX, impulseY))
	
	if GameWorld.softPaused():
		return 
	$build.position.y = $Sprite.position.y + $Sprite.region_rect.size.y
	
func _on_Lift_body_entered(body):
	if body is RigidBody2D:
		liftedRigids.append(body)
		body.isAutoTransported = true
	elif body is Keeper:
		var ups = Data.of("lift.keeperupwardsspeed")
		if not keeperInsideLift and ups > 0:
			keeperInsideLift = true
			addedSpeed = ups
			Data.changeByInt("keeper.additionalupwardsspeed", addedSpeed)
	particles.emitting = liftedRigids.size()

func _on_Lift_body_exited(body):
	if body is RigidBody2D:
		liftedRigids.erase(body)
		body.isAutoTransported = false
	elif body is Keeper:
		if keeperInsideLift:
			keeperInsideLift = false
			Data.changeByInt("keeper.additionalupwardsspeed", - addedSpeed)
			addedSpeed = 0

	particles.emitting = liftedRigids.size()
	
func liftUpgraded():
	particles.process_material.initial_velocity = max(1, Data.of("lift.speed") - 2.0)

func _on_Tween_tween_all_completed():
	$build.hide()
	$build / buildSfx.stop()

func spawnOrb():
	if $Sprite.region_rect.size.y < GameWorld.TILE_SIZE:
		$SpawnTween.interpolate_callback(self, 1.0, "spawnOrb")
		$SpawnTween.start()
		queuedOrbs += 1
		return 
		
	var l = LiftOrb.instance()
	add_child(l)
	if orbState.size():
		var state = orbState.pop_front()
		l.deserialize(state)
		
	if queuedOrbs > 0:
		queuedOrbs -= 1
