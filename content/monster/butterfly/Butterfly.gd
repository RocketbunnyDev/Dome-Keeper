extends "res://content/monster/Monster.gd"

signal move_finished

const delayBetweenShots = 0.0

enum Phase{TURN, TURNING, MOVE, DIE}

var phase: int = Phase.MOVE

var remainingShots: = 0

var nextSide: String
var movePointProvider
var projetileTargetProvider
var currentMoveCurve: Curve2D

var pathProgress: = 0.0
var curveRotationRadians: = 0.5
var curveRotationStrength: = 80

var line: Line2D
var cooldown: = 0.0

func setProviders(movePointProvider, projetileTargetProvider, side: String):
	self.movePointProvider = movePointProvider
	self.projetileTargetProvider = projetileTargetProvider
	var spawnType = Data.of("butterfly.spawnpoint") + "_" + side.substr(0, side.find("_"))
	position = movePointProvider.getSpawn(spawnType).position
	nextSide = getOtherSide(side)
	currentMoveCurve = Curve2D.new()

func getOtherSide(side: String)->String:
	return CONST.LEFT_HIGH if side == CONST.RIGHT_HIGH else CONST.RIGHT_HIGH

func init():
	startMove()
	attackTween.interpolate_callback(self, 2.0, "set", "remainingShots", 3)
	attackTween.start()
	setFlip(position.x > 0)

func createNextPath():
	pathProgress = 0
	var targetPos: Vector2 = movePointProvider.assignRandomPoint(nextSide, self).position
	nextSide = getOtherSide(nextSide)
	var direction = (targetPos - position).normalized()
	currentMoveCurve.clear_points()
	var rot1 = direction.rotated(0.5 * PI * curveRotationRadians) * curveRotationStrength
	currentMoveCurve.add_point(position, Vector2.ZERO, rot1)
	currentMoveCurve.add_point(targetPos)

func startMove():
	animation("fly")
	createNextPath()
	var pathLength = currentMoveCurve.get_baked_length()
	$Sprite.speed_scale = speedModifier
	var duration = pathLength / (Data.of("butterfly.speed") * speedModifier)
	moveTween.interpolate_property(self, "pathProgress", 0, pathLength, duration, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
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
			position = newPos
			if pathProgress >= pathLength:
				phase = Phase.TURN
				$Sprite.speed_scale = 1.0
				emit_signal("move_finished")
		Phase.TURN:
			animation("turn")
			$TurnSound.play()
			phase = Phase.TURNING

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

func resumeAfterStagger():
	animation("fly")
	phase = Phase.MOVE

func shoot():
	var delay: = 0.01
	for _i in range(0, 3):
		attackTween.interpolate_callback(self, delay, "spawnProjectile")
		attackTween.start()
		delay += 0.15
	$ShootSound.play()
	remainingShots -= 1

func spawnProjectile():
	var p = preload("res://content/monster/butterfly/ButterflyProjectile.tscn").instance()
	p.damageSource = damageSource
	p.position = position + $ProjectilePosition.position
	p.origin = position
	p.target = projetileTargetProvider.getRandom(position) + Vector2(8 - randi() % 16, 8 - randi() % 16)
	p.damage = Data.of("butterfly.damage") * damageModifier
	p.speed = Data.of("butterfly.shotspeed")
	get_parent().add_child(p)

func animateDeath():
	$DieSound.play()
	animation("die")
	phase = Phase.DIE

func _on_Sprite_animation_finished():
	if $Sprite.animation == "shoot":
		if remainingShots <= 0:
			animation("fly")
	elif $Sprite.animation == "fly" and remainingShots > 0:
		animation("shoot")
	elif $Sprite.animation == "die":
		.removeFreeBlocker()
	elif $Sprite.animation == "turn":
		remainingShots = 6
		startMove()
		animation("fly")
		setFlip( not $Sprite.flip_h)

func _on_Sprite_frame_changed():
	if $Sprite.animation == "shoot" and ($Sprite.frame == 4 or $Sprite.frame == 18 or $Sprite.frame == 25):
		shoot()
