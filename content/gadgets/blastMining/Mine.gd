extends Carryable

var activated: = false
var untilExplosion: = 0.0
var maxUntilExplosion: = 0.0
var exploded: = false
var sticks: = false
var lastVelocity
var stickingTo: Vector2
var animationSuffix: String

func _ready():
	Style.init(self)
	contact_monitor = false
	$Adhesion.visible = false
	var bombsize = Data.of("blastMining.bombsize")
	animationSuffix = "_" + str(Data.of("blastMining.bombsize"))
	$Adhesion.frame = int(bombsize)
	$Sprite.play("normal" + animationSuffix)

func serialize()->Dictionary:
	var data = .serialize()
	data["activated"] = activated
	data["untilExplosion"] = untilExplosion
	data["maxUntilExplosion"] = maxUntilExplosion
	data["exploded"] = exploded
	data["sticks"] = sticks
	data["stickingTo"] = var2str(stickingTo)
	return data
	
func deserialize(data: Dictionary):
	.deserialize(data)
	activated = data["activated"]
	untilExplosion = data["untilExplosion"]
	maxUntilExplosion = data["maxUntilExplosion"]
	exploded = data["exploded"]
	sticks = data["sticks"]
	stickingTo = str2var(data["stickingTo"])
	
	if activated:
		activate()
	else:
		deactivate()
		
	if exploded:
		queue_free()
	
	if sticks and stickingTo:
		var delta = getStickToDirection()
		$Adhesion.visible = true
		$Adhesion.rotation = delta.angle() - rotation
		call_deferred("set", "mode", RigidBody2D.MODE_STATIC)
	
func canFocusCarry()->bool:
	return not exploded

func onCarried(keeper: Keeper):
	deactivate()

func deactivate():
	if sticks:
		mode = RigidBody2D.MODE_RIGID
		$Adhesion.visible = false
	sticks = false
	activated = false
	untilExplosion = 0.0
	$Sprite.play("normal" + animationSuffix)
	$ActivateSound.stop()
	contact_monitor = false

func activate():
	if Data.of("blastMining.stickyCharge"):
		maxUntilExplosion = 1.5
		untilExplosion = maxUntilExplosion
	else:
		maxUntilExplosion = 3.0
		untilExplosion = maxUntilExplosion
	activated = true
	$Sprite.play("activated" + animationSuffix)
	$ActivateSound.play()

func onDropped(keeper: Keeper):
	if Data.of("blastMining.explodeOnImpact") or Data.of("blastMining.stickyCharge"):
		contact_monitor = true
	else:
		activate()

func _physics_process(delta):
	if GameWorld.paused or exploded:
		return 
	
	if Data.of("blastMining.explodeOnImpact") and not activated and not isCarried():
		if linear_velocity.length() > 20:
			activated = true
			$Sprite.play("activated" + animationSuffix)
			$ActivateSound.play()
	
	if not activated:
		return 
	
	lastVelocity = linear_velocity
	if not Data.of("blastMining.explodeOnImpact"):
		if untilExplosion > 0.0:
			untilExplosion -= delta
			$Sprite.speed_scale = 0.3 + 1.7 * (1.0 - untilExplosion / maxUntilExplosion)
			$CountdownSound.play()
		else:
			explode()

func getStickToDirection()->Vector2:
	var delta = stickingTo - global_position
	if abs(delta.x) > abs(delta.y):
		delta.y = 0
	else:
		delta.x = 0
	return delta

func explode():
	$ActivateSound.stop()
	var ex = load("res://content/gadgets/blastMining/Explosion.tscn").instance()
	ex.position = position
	get_parent().add_child(ex)
	if Level.map:
		if sticks:
			var delta = getStickToDirection()
			Level.map.damageTileDirection(global_position, delta.normalized(), round(pow(2, Data.of("blastMining.radius"))), Data.of("blastMining.damage"), 0.1)
		else:
			Level.map.damageTileCircleArea(global_position, Data.of("blastMining.radius"), Data.of("blastMining.damage"), 0.1)
	exploded = true
	deactivated = true
	Backend.event("gadget_used", {"gadget": "blastMining"})
	GameWorld.incrementRunStat("blastcharges_used")
	queue_free()

func _on_Mine_body_entered(body):
	if not body.has_meta("destructable") or not body.get_meta("destructable"):
		return 
	
	if not sticks and Data.of("blastMining.stickyCharge"):
		call_deferred("set", "mode", RigidBody2D.MODE_STATIC)
		sticks = true
		stickingTo = body.global_position
		$Adhesion.visible = true
		var delta = getStickToDirection()
		$Adhesion.rotation = delta.angle() - rotation
		activate()
		return 
	
	if not activated:
		return 
	
	if Data.of("blastMining.explodeOnImpact"):
		explode()
