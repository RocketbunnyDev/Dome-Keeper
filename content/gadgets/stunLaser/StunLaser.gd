extends Node2D

var dist: float

var playSound: = false

var firing: = false
var active: = false
var animatingCountdown: = 0.0
var totalFireTime: float
var remainingFireTime: float
var remainingCooldown: float

var target
var pathProbe: PathFollow2D

func _ready():
	Style.init(self)
	
	$HitParticles.emitting = false
	$CooldownParticles.emitting = false

func serialize()->Dictionary:
	var data = {
		"probeOffset": pathProbe.offset
	}
	data["meta.priority"] = 200
	data["meta.kind"] = "station"
	return data
	
func deserialize(data: Dictionary):
	yield (GameWorld, "savegame_loaded")
	
	pathProbe.offset = data["probeOffset"]
	
func init(cupulaPath: Path2D):
	$Laser.visible = false
	deactivate()
	
	pathProbe = cupulaPath.createPathProbe(self)
	
	$Sprite.play("off")

func _physics_process(delta):
	if GameWorld.paused:
		return 
	
	if animatingCountdown > 0.0:
		animatingCountdown -= delta
		return 
	
	if active:
		if not Data.of("monsters.wavepresent") or ( not Data.of("keeper.insidestation") and not Data.of("stunLaser.autonomy")):
			deactivate()
			return 
	else:
		if Data.of("monsters.wavepresent") and (Data.of("keeper.insidestation") or Data.of("stunLaser.autonomy")):
			activate()
			return 
	
	if not active:
		return 
	
	var fraction = floor(min(11, 12.0 * remainingFireTime / totalFireTime))
	setCannonFraction(fraction)
	
	if remainingCooldown > 0.0:
		$Sprite.play("cooldown")
		$CooldownParticles.emitting = true
		$CooldownParticles.rotation = - rotation
		remainingCooldown -= delta
		if remainingCooldown <= 0.0:
			$CooldownParticles.emitting = false
			$ActivateSound.play()
			remainingFireTime = Data.of("stunLaser.fireTime")
			$Tween.stop_all()
			$Tween.remove_all()
			$Tween.interpolate_method(self, "setCannonFraction", 0, 11, 1.0, Tween.TRANS_CUBIC, Tween.EASE_IN_OUT)
			$Tween.start()
			animatingCountdown = 1.0
			return 
		elif not Data.of("stunLaser.trackingInCooldown"):
			return 
	
	if firing:
		remainingFireTime -= delta
		if remainingFireTime <= 0.0:
			stopFire()
			$Sprite.play("idle")
			remainingCooldown = Data.of("stunLaser.cooldown")
			return 
	
	if not is_instance_valid(target):
		target = null
	
	if not target and not firing and (remainingCooldown <= 0 or Data.of("stunLaser.trackingInCooldown")):
		findTarget()
		return 
	
	if target and (remainingCooldown <= 0 or Data.of("stunLaser.trackingInCooldown")):
		
		
		
		var d: Vector2 = target.getCenter() - $Position2D.global_position
		dist = d.angle() - (rotation - CONST.PI_HALF)
		if dist > PI:
			dist -= 2 * PI
		elif dist < - PI:
			dist += 2 * PI
		
		
		if rotation > 0.8 and dist > CONST.PI_HALF:
			dist -= 2 * PI
		elif rotation < - 0.8 and dist < - CONST.PI_HALF:
			dist += 2 * PI
		
		dist = clamp(dist, - 0.4, 0.4)
		if abs(dist) > 0.01:
			pathProbe.moveBy(delta * dist * Data.of("stunLaser.speed"))
			$Sprite.play("move")
			$MoveSound.play()
	else:
		$MoveSound.stop()
	
	var c = $RayCast2D.get_collider()
	if $RayCast2D.enabled and remainingFireTime > 0:
		if c and is_instance_valid(c):
			if c and canTarget(c):
				if c != target:
					setTarget(c)
				fire(delta)
			else:
				stopFire()

func setCannonFraction(fraction: int):
	$Cannon.region_rect.size.y = fraction
	$Cannon.region_rect.position.y = 0
	$Cannon.offset.y = 11 - fraction

func activate():
	$Sprite.play("start")
	animatingCountdown = 0.7
	active = true
	remainingFireTime = Data.of("stunLaser.fireTime")
	totalFireTime = remainingFireTime
	remainingCooldown = 0.0
	$ActivateSound.play()

func deactivate():
	stopFire()
	$CooldownParticles.emitting = false
	$Sprite.play("shutdown")
	active = false
	target = null
	var time = max(0.1, $Cannon.region_rect.size.y / 11.0)
	$Tween.stop_all()
	$Tween.remove_all()
	$Tween.interpolate_method(self, "setCannonFraction", $Cannon.region_rect.size.y, 0, time, Tween.TRANS_CUBIC, Tween.EASE_IN_OUT)
	$Tween.interpolate_callback(self, time, "set", "animating", false)
	$Tween.start()
	animatingCountdown = time

func fire(delta: float):
	var collisionPoint = $RayCast2D.get_collision_point()
	var laserEndPos = Vector2(0, - 1) * ((collisionPoint - global_position).length() + 5)
	$Sprite.play("shoot")
	$Laser.set_point_position(1, laserEndPos)
	target.hit(Data.of("stunLaser.damage") * delta, 2.0)
	if not firing:
		$FireSound.play()
	firing = true
	$Laser.visible = true
	$HitEffect.visible = true
	$HitEffect.position = laserEndPos
	$HitParticles.position = laserEndPos
	if not $HitParticles.emitting:
		$HitParticles.amount = 10
		$HitParticles.emitting = true

func stopFire():
	$Laser.set_point_position(1, Vector2(0, - 1) * 300)
	$Laser.visible = false
	$HitParticles.emitting = false
	$HitEffect.visible = false
	
	if firing:
		$FireSound.stop()
		$StopSound.play()
		firing = false

func canTarget(m):
	return m.alive() and m.stunPriority > 0 and not m.invulnerable

func findTarget():
	var closestM
	var minimalAngle: = 99.0
	
	var monsters = get_tree().get_nodes_in_group("monster")
	for i in range(1, 5):
		for m in monsters:
			if i != m.stunPriority or not canTarget(m):
				continue
			
			var angle = abs((m.global_position - global_position).angle() - (rotation - CONST.PI_HALF))
			if angle < minimalAngle:
				minimalAngle = angle
				closestM = m
			
		if closestM:
			if closestM != target:
				setTarget(closestM)
			return 

func setTarget(m):
	if target:
		target.disconnect("died", self, "targetDied")
	target = m
	if not target.is_connected("died", self, "targetDied"):
		target.connect("died", self, "targetDied")

func targetDied():
	target = null
	stopFire()
	findTarget()

func _on_Sprite_animation_finished():
	if $Sprite.animation == "start":
		$Cannon.visible = true

func onGameLost():
	deactivate()
