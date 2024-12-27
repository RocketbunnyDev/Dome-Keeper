extends "res://content/monster/Monster.gd"

const delayBetweenShots = 0.0

enum Phase{ENTER, SHOOT, DIE}

var phase: int = Phase.ENTER

var remainingShots: = 0

var movePointProvider
var projetileTargetProvider
var currentMoveCurve: Curve2D

var applyInRotation: = false
var pathProgress: = 0.0
var averagedMoveDelta: = 0.0
var curveRotationRadians: = 0.75
var curveRotationStrength: = 150

var line: Line2D
var cooldown: = 0.0

func setProviders(movePointProvider, projetileTargetProvider, side: String):
	self.movePointProvider = movePointProvider
	self.projetileTargetProvider = projetileTargetProvider
	var spawnType = Data.of("bolter.spawnpoint") + "_" + side
	position = movePointProvider.getSpawn(spawnType).position
	currentMoveCurve = Curve2D.new()

func init():
	applyInRotation = true
	setFlip(position.x > 0)
	
	pathProgress = 0
	var targetPos: Vector2 = projetileTargetProvider.getRandom(position) + Vector2(4 - randi() % 8, 4 - randi() % 8) - find_node("ShotPosition").position
	var direction = (targetPos - position).normalized()
	currentMoveCurve.add_point(position, Vector2.ZERO)
	var rot = direction.rotated(PI * 1.25 * curveRotationRadians - 0.5 * PI * curveRotationRadians * randf()) * curveRotationStrength
	currentMoveCurve.add_point(targetPos, rot, Vector2.ZERO)
	
	animation("fly")
	var pathLength = currentMoveCurve.get_baked_length()
	var duration = pathLength / (Data.of("bolter.speed") * speedModifier)
	moveTween.interpolate_property(self, "pathProgress", 0, pathLength, duration, Tween.TRANS_QUAD, Tween.EASE_OUT)
	moveTween.interpolate_callback(self, duration, "startShooting")
	moveTween.start()
	
	$Bolt.play("default")

func subProcess(delta):
	if cooldown > 0.0:
		cooldown -= delta
		return 
	
	match phase:
		Phase.ENTER:
			var oldPos: = position
			position = currentMoveCurve.interpolate_baked(pathProgress)
			if averagedMoveDelta == 0.0:
				averagedMoveDelta = (position - oldPos).length()
			else:
				averagedMoveDelta = averagedMoveDelta * (1.0 - delta) + (position - oldPos).length() * delta
			$Sprite.speed_scale = max(0.5, averagedMoveDelta) * speedModifier
		Phase.SHOOT:
			pass

func startShooting():
	phase = Phase.SHOOT
	$Sprite.speed_scale = 1.0
	animation("shoot2")
	$ChargingShotSound.play()

func leave(delta: float):
	position.y -= delta * 50
	position.x += delta * position.x * 0.1

func onGameLost():
	if currentHealth > 0:
		moveTween.stop_all()
		moveTween.remove_all()
		leaving = true
		setFlip( not $Sprite.flip_h)
		animation("fly")

func handleDamage():
	if stunIntensity >= fullStunAt:
		animation("hit")

func resumeAfterStagger():
	if phase == Phase.SHOOT:
		animation("idle")
	else:
		animation("fly")

func hitDome():
	Level.dome.requestProjectileDamage(Data.of("bolter.damage") * damageModifier, global_position, self)

func animateDeath():
	$DieSound.play()
	animation("die")
	phase = Phase.DIE

func _on_Sprite_animation_finished():
	if $Sprite.animation == "die":
		.removeFreeBlocker()
	elif $Sprite.animation == "shoot2":
		animation("idle")
	elif $Sprite.animation == "idle":
		animation("shoot2")
		$ChargingShotSound.play()

func _on_Sprite_frame_changed():
	if $Sprite.animation == "shoot2":
		if $Sprite.frame == 9:
			hitDome()
		elif $Sprite.frame == 5:
			$ShootSound.play()
		elif $Sprite.frame == 8:
			InputSystem.getCamera().shake(80, 0.2)
		elif $Sprite.frame == 0:
			$Bolt.play("bolt" + str(1 + randi() % 3))

func _on_Bolt_animation_finished():
	$Bolt.play("default")
