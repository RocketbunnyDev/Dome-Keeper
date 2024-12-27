extends "res://content/monster/Monster.gd"

const damageUnit: = 2.0

var path: Path2D
var meleeTarget: Path2D
var phase: = 0
var progress: = 0.0

var damageSum: = 0.0

var ground: = true

const FootstepDust = preload("res://content/monster/FootstepDust.tscn")

func init():
	position = path.curve.interpolate_baked(0) + path.global_position
	var d = position.x - (path.curve.interpolate_baked(50).x + path.global_position.x)
	lastDelta = - d
	if d < 0.0:
		setFlip(true, true)
		$Particles1.process_material = preload("res://content/monster/driller/P1left.tres")
		$Particles2.process_material = preload("res://content/monster/driller/P2left.tres")
	else:
		$Particles1.process_material = preload("res://content/monster/driller/P1right.tres")
		$Particles2.process_material = preload("res://content/monster/driller/P2right.tres")
		
	$Sprite.play("walk")
	updateHitboxState()
	$Sprite.speed_scale = speedModifier
	
var lastDelta: float
func subProcess(delta):
	if phase == 0:
		progress += delta * Data.of("driller.speed") * speedModifier
		var cp = meleeTarget.curve.get_closest_point($HitPosition.global_position)
		if sign(lastDelta) != sign(cp.x - $HitPosition.global_position.x):
			animation("settle")
			$Tween.interpolate_callback(InputSystem.getCamera(), 0.6, "shake", 100, 1.0, 32)
			$Tween.interpolate_callback($SettleSound, 0.6, "play")
			$Tween.start()
			phase = 1
			$Sprite.speed_scale = 1.0
		else:
			position = path.curve.interpolate_baked(progress) + path.global_position
	elif phase == 5:
		damageSum += Data.of("driller.damage") * delta
		if damageSum >= damageUnit:
			damageSum -= damageUnit
			Level.dome.requestMeleeDamage(damageUnit * damageModifier, $HitPosition.global_position, self)
			InputSystem.getCamera().shake(20, 0.2, 8)

func leave(delta: float):
	pass

func onGameLost():
	animateDeath()

func handleDamage():
	pass

func _on_Sprite_animation_finished():
	if $Sprite.animation.begins_with("die_"):
		.removeFreeBlocker()
	elif phase == 1:
		animation("attack_prepare")
		phase = 2
	elif phase == 2:
		animation("idle")
		phase = 3
	elif phase == 3:
		animation("attack_in")
		$Tween.interpolate_callback(InputSystem.getCamera(), 0.75, "shake", 100, 1.0, 32)
		$Tween.interpolate_callback($ImpactSound, 0.75, "play")
		$Tween.start()
		phase = 4
	elif phase == 4:
		phase = 5
		$Particles1.emitting = true
		$Particles2.emitting = true
		$PunchSound.play()
		animation("attack")

func _on_Sprite_frame_changed():
	pass






func animateDeath():
	$PunchSound.stop()
	if phase == 0:
		animation("die_walk")
	else:
		animation("die_attack")
	phase = 6
	$Particles1.emitting = false
	$Particles2.emitting = false
	$DieSound.play()
