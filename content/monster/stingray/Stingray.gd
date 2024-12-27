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

var entering: = true
var pathProgress: = 0.0
var curveRotationRadians: = 0.5
var curveRotationStrength: = 50

var line: Line2D

func setProviders(movePointProvider, projetileTargetProvider, side: String):
	self.movePointProvider = movePointProvider
	self.projetileTargetProvider = projetileTargetProvider
	var spawnType = Data.of("stingray.spawnpoint") + "_" + side
	position = movePointProvider.getSpawn(spawnType).position
	nextSide = side
	currentMoveCurve = Curve2D.new()

func init():
	startMove()

func createNextPath():
	pathProgress = 0
	var targetPos: Vector2 = movePointProvider.assignRandomPoint(nextSide + "_low", self).position
	nextSide = CONST.LEFT if nextSide == CONST.RIGHT else CONST.RIGHT
	var direction = (targetPos - position).normalized()
	currentMoveCurve.clear_points()
	var rot = direction.rotated(PI * 0.5 * curveRotationRadians - PI * curveRotationRadians * randf()) * curveRotationStrength
	currentMoveCurve.add_point(position, Vector2.ZERO, rot)
	currentMoveCurve.add_point(targetPos, direction.rotated(PI * (1 + curveRotationRadians * 0.5) - PI * curveRotationRadians * randf()) * curveRotationStrength)

func startMove():
	createNextPath()
	var pathLength = currentMoveCurve.get_baked_length()
	$Sprite.speed_scale = speedModifier
	var duration = pathLength / (Data.of("stingray.speed") * speedModifier)
	moveTween.interpolate_property(self, "pathProgress", 0, pathLength, duration, Tween.TRANS_QUAD, Tween.EASE_IN_OUT)
	moveTween.start()
	phase = Phase.MOVE
	animation("fly")

func subProcess(delta):
	match phase:
		Phase.MOVE:
			var pathLength = currentMoveCurve.get_baked_length()
			var newPos = currentMoveCurve.interpolate_baked(pathProgress)
			var moveDelta = position - newPos
			if pathProgress > 0.0 and moveDelta.length() > 0:
				setFlip(moveDelta.x > 0)
				$Sprite.rotation = moveDelta.angle()
				if not $Sprite.flip_h:
					$Sprite.rotation += PI
				$Sprite.speed_scale = speedModifier + 0.2 * moveDelta.length()
			position = newPos
			if pathProgress >= pathLength:
				grow()
				emit_signal("move_finished")
				$Sprite.rotation = 0
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
		animation("idle")

func handleDamage():
	if stunIntensity >= fullStunAt:
		animation("hit")

func stagger():
	animation("hit")

func resumeAfterStagger():
	if phase != Phase.MOVE:
		shrink()
	else:
		animation("fly")

func spawnShot():
	var p = preload("res://content/monster/flyer/FlyerProjectile.tscn").instance()
	p.damageSource = damageSource
	p.position = position + $ProjectilePosition.position
	p.origin = position
	p.target = projetileTargetProvider.getRandom(position) + Vector2(8 - randi() % 16, 8 - randi() % 16)
	p.damage = Data.of("stingray.damage") * damageModifier
	p.speed = Data.of("stingray.shotspeed")
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
	remainingShots = Data.of("stingray.maxshots") - randi() % int(1 + Data.of("stingray.maxshots") - Data.of("stingray.minshots"))
	
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
		if entering or randf() > 0.5:
			animation("idle")
			entering = false
	elif $Sprite.animation == "idle" and not leaving:
		startShoot()

func _on_Sprite_frame_changed():
	if $Sprite.animation == "shoot" and $Sprite.frame == 3:
		spawnShot()
