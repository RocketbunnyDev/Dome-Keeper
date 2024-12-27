extends RigidBody2D

var maxLifetime: float
var lifeTime: float
var timeAlive: float

var baseDamage: float
var damageDealt: = 0.0
var damageModNextHit: = 1.0
var remainingCollisions: = 100
var size: = 1.0

var speedScale: = 1.0

var maxSpeed: = 200
var bumpSpeedup: = 30

var hitCounter: = 0
var removeBlockers: = 2
var consecutiveIndestructibleHits: = 0
var reflectCounter: = 0
var consecutiveReflections: = 0
var destroyed: = false

var approachingBody

func _ready():
	baseDamage = Data.of("keeper2.spherebasedamage")
	lifeTime = Data.of("keeper2.spherebaselifetime") * (1.0 + 0.5 * Data.of("keeper.drillBuff"))
	maxLifetime = lifeTime
	$Sprite.play("ready")
	Style.init($Sprite)
	
	$RayCastFront.enabled = true
	$Amb.play()
	
	Achievements.addIfOpen(self, "KEEPER2_REFLECTIONS")
	Achievements.addIfOpen(self, "KEEPER2_SPHEREDURATION")

func _physics_process(delta):
	if linear_velocity.length() > 100:
		$Trail.emitting = true
	else:
		$Trail.emitting = false
		
	if GameWorld.paused or destroyed:
		$Trail.emitting = false
		return 
	
	lifeTime = lifeTime - delta
	timeAlive += delta
	
	if lifeTime <= 0.0:
		destroy()
		return 
	
	linear_damp = 0.15 + 0.15 * (1.0 - min(1.0, lifeTime / maxLifetime))
	
	if $RayCastFront.enabled:
		var c = $RayCastFront.get_collider()
		if c:
			c.sphereApproaching(self)
			approachingBody = c
		elif approachingBody:
			approachingBody.spherePassed(self)
			approachingBody = null
	
	var speedScale = min(1.0, (linear_velocity.length() - 40) / 260.0)
	var sizeScale = (0.6 + 1.0 * speedScale) * size
	$Sprite.scale = Vector2.ONE * sizeScale
	$CollisionShape2D.shape.radius = 4.0 * sizeScale
	
	$Sprite.modulate.r = 0.4 + speedScale * 1.5
	$Sprite.modulate.g = 0.3 + speedScale * 0.7
	$RayCastFront.rotation = linear_velocity.angle() - PI * 0.5 - rotation
	$RayCastFront.position = Vector2.DOWN.rotated($RayCastFront.rotation + PI) * 20

func reflect():
	addLifetime(Data.of("keeper2.reflectlifetime") + Data.of("keeper2.spherelifetimeperbounce"))
	damageModNextHit = Data.of("keeper2.reflectnexthitdamage")
	if damageModNextHit > 1.0:
		$ReflectionMoreDamage.play()
	var direction = linear_velocity * - 2
	var maxMod = 1.0 - (clamp(linear_velocity.length() - 100, 0.1, 100) / 100.0)
	var speedup = Data.of("keeper2.reflectspeedup")
	if speedup > 0.0:
		$ReflectionSpedUp.play()
	direction *= 1.0 + speedup * maxMod
	apply_central_impulse(direction)
	$ReflectionBaseSound.play()
	
	if reflectCounter > 0:
		consecutiveReflections += 1
	else:
		consecutiveReflections = 0
	reflectCounter = 2

func catch():
	linear_damp = 12
	$Sprite.play("vanish")
	$Sprite.frame = 0
	if approachingBody:
		approachingBody.spherePassed(self)
		approachingBody = null
	$RayCastFront.set_deferred("enabled", false)
	destroyed = true
	$SphereCatchSound.play()

func destroy():
	if destroyed:
		return 
	
	linear_damp = 8
	$Sprite.play("vanish")
	$Sprite.frame = 0
	$VanishSound.play()
	if approachingBody:
		approachingBody.spherePassed(self)
		approachingBody = null
	$RayCastFront.set_deferred("enabled", false)
	destroyed = true

func _on_Pinball_body_entered(body):
	if not body or destroyed:
		return 
	
	var velocity = linear_velocity.length()
	if velocity <= 20.0:
		destroy()
		return 
	
	if remainingCollisions <= 0:
		destroy()
		return 
	
	var dir = global_position - body.global_position
	var surface: Vector2
	if abs(dir.x) > abs(dir.y):
		surface = Vector2(0, linear_velocity.y)
	else:
		surface = Vector2(linear_velocity.x, 0)
	var steepnessMod = 1.0 - surface.normalized().dot(linear_velocity.normalized())
	
	var bs = getFreeBounceSound()
	if bs:
		bs.baseVolume = - 6 + 6 * steepnessMod
		bs.play()
	
	var isDestructible = body.has_meta("destructable") and body.get_meta("destructable")
	
	if isDestructible:
		var damage = baseDamage + baseDamage * velocity / 100.0
		damage = min(damage, body.health)
		damage += Data.of("keeper2.spherefractiondamage") * body.max_health
		damage = damage * steepnessMod * size
		var mod = damageModNextHit
		damageModNextHit = 1.0
		if hitCounter == 0:
			mod += Data.of("keeper2.sphereadditionalfirsthitdamage")
		damage *= mod
		hitCounter += 1
		body.hit(dir, damage)
		damageDealt += damage
		
		var pinballhit = preload("res://content/keeper/keeper2/PinballHit.tscn").instance()
		Level.add_child(pinballhit)
		var pinballhit_scale = clamp(velocity / 150.0, 0.25, 1)
		pinballhit.scale = Vector2(pinballhit_scale, pinballhit_scale)
		pinballhit.global_position = global_position
		
		var soundPlayer: AudioStreamPlayer = get_node("TileHitHardness" + str(body.hardness))
		soundPlayer.play()
		
		addLifetime(Data.of("keeper2.spherelifetimeperbounce") * steepnessMod)
		consecutiveIndestructibleHits = 0
	else:
		addLifetime(Data.of("keeper2.spherelifetimeperbounce") * steepnessMod * 0.5)
		consecutiveIndestructibleHits += 1
	
	if consecutiveIndestructibleHits > 5:
		destroy()
	
	if linear_velocity.length() < maxSpeed * (1.0 + 0.5 * Data.of("keeper.drillBuff")):
		apply_central_impulse(linear_velocity.normalized() * bumpSpeedup * steepnessMod)
	
	remainingCollisions -= 1
	reflectCounter -= 1

func addLifetime(time: float):
	lifeTime = lifeTime + time


func getFreeBounceSound():
	if not $BounceSound1.playing:
		return $BounceSound1
	elif not $BounceSound2.playing:
		return $BounceSound2
	elif not $BounceSound3.playing:
		return $BounceSound3

func explode():
	Level.map.damageTileCircleArea(position, 1.5, 100)
	destroy()

func _on_Sprite_animation_finished():
	if $Sprite.animation == "vanish":
		removeBlockerFreed()

func removeBlockerFreed():
	removeBlockers -= 1
	if removeBlockers <= 0:
		queue_free()

var oldVelocity = Vector2()
func pauseChanged():
	if GameWorld.paused:
		oldVelocity = linear_velocity
		set_axis_velocity(Vector2.ZERO)
		mode = RigidBody2D.MODE_STATIC
	else:
		mode = RigidBody2D.MODE_RIGID
		set_axis_velocity(oldVelocity)
