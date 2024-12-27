extends "res://content/monster/Monster.gd"

signal move_finished

const delayBetweenShots = 0.0

enum Phase{GROW, SHOOT, SHRINK, MOVE, DIE}

var phase: int = Phase.MOVE

var remainingShots: = 0

var nextSide: String
var movePointProvider
var projetileTargetProvider
var currentMoveCurve: Curve2D

var applyInRotation: = false
var drawMovementLine: = false
var pathProgress: = 0.0
var curveRotationRadians: = 0.75
var curveRotationStrength: = 150

var cooldown: = 0.0

func setProviders(movePointProvider, projetileTargetProvider, side: String):
	self.movePointProvider = movePointProvider
	self.projetileTargetProvider = projetileTargetProvider
	var spawnType = Data.of("flyer.spawnpoint") + "_" + side
	position = movePointProvider.getSpawn(spawnType).position
	nextSide = side
	currentMoveCurve = Curve2D.new()

func init():
	applyInRotation = true
	startMove()
	setHittable(false)
	

func createNextPath():
	pathProgress = 0
	var targetPos: Vector2 = movePointProvider.assignRandomPoint(nextSide, self).position
	nextSide = CONST.LEFT if nextSide == CONST.RIGHT else CONST.RIGHT
	var direction = (targetPos - position).normalized()
	currentMoveCurve.clear_points()
	var rot = direction.rotated(PI * 0.5 * curveRotationRadians - PI * curveRotationRadians * randf()) * curveRotationStrength if applyInRotation else Vector2.ZERO
	currentMoveCurve.add_point(position, Vector2.ZERO, rot)
	currentMoveCurve.add_point(targetPos, direction.rotated(PI * (1 + curveRotationRadians * 0.5) - PI * curveRotationRadians * randf()) * curveRotationStrength)

func startMove():
	animation("fly")
	createNextPath()
	var pathLength = currentMoveCurve.get_baked_length()
	$Sprite.speed_scale = speedModifier
	var duration = pathLength / (Data.of("flyer.speed") * speedModifier)
	moveTween.interpolate_property(self, "pathProgress", 0, pathLength, duration, Tween.TRANS_QUAD, Tween.EASE_IN_OUT)
	moveTween.start()
	phase = Phase.MOVE

func subProcess(delta):
	if cooldown > 0.0:
		cooldown -= delta
		return 
	
	match phase:
		Phase.MOVE:
			var pathLength = currentMoveCurve.get_baked_length()
			var newPos = currentMoveCurve.interpolate_baked(pathProgress)
			setFlip(position.x - newPos.x > 0)
			position = newPos
			$Sprite.speed_scale = speedModifier
			if pathProgress >= pathLength:
				grow()
				emit_signal("move_finished")
		Phase.SHOOT:
			$Sprite.speed_scale = stunLevel() * speedModifier
		Phase.SHRINK:
			pass
		Phase.GROW:
			pass

func leave(delta: float):
	position.y -= delta * 50
	position.x += delta * position.x * 0.1

func onGameLost():
	if currentHealth > 0:
		leaving = true
		animation("fly")

func handleDamage():
	if stunIntensity >= fullStunAt:
		animation("hit")

func stagger():
	if phase != Phase.MOVE:
		animation("hit")

func resumeAfterStagger():
	if phase != Phase.MOVE:
		shrink()

func spawnShot():
	var p = preload("res://content/monster/flyer/FlyerProjectile.tscn").instance()
	p.damageSource = damageSource
	p.position = position + $ProjectilePosition.position
	p.origin = position
	p.target = projetileTargetProvider.getRandom(position) + Vector2(8 - randi() % 16, 8 - randi() % 16)
	p.damage = Data.of("flyer.damage") * damageModifier
	p.speed = Data.of("flyer.shotspeed")
	get_parent().add_child(p)
	$ShootSound.play()
	remainingShots -= 1

func shrink():
	animation("shrink")
	$ShrinkSound.play()
	phase = Phase.SHRINK

func grow():
	animation("grow")
	setFlip(position.x > 0)
	$AppearSound.play()
	phase = Phase.GROW

func startShoot():
	remainingShots = Data.of("flyer.maxshots") - randi() % int(1 + Data.of("flyer.maxshots") - Data.of("flyer.minshots"))
	
	phase = Phase.SHOOT
	updateShoot()

func updateShoot():
	if remainingShots > 0:
		animation("shoot")
		$Sprite.frame = 0
	else:
		shrink()

func animateDeath():
	$DieSound.play()
	animation("die")
	phase = Phase.DIE

func _on_Sprite_animation_finished():
	if $Sprite.animation == "shoot":
		updateShoot()
	elif $Sprite.animation == "die":
		.removeFreeBlocker()
	elif $Sprite.animation == "shrink":
		startMove()
	elif $Sprite.animation == "grow":
		startShoot()

func _on_Sprite_frame_changed():
	if $Sprite.animation == "shrink" and $Sprite.frame == 3:
		setHittable(false)
	elif $Sprite.animation == "grow" and $Sprite.frame == 2:
		setHittable(true)
	elif $Sprite.animation == "shoot" and $Sprite.frame == 4:
		spawnShot()
