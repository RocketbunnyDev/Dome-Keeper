extends "res://content/monster/Monster.gd"

export (float) var distanceToMeleePoint: = 10.0

var path: Path2D
var meleeTarget: Path2D
var walking: = true
var progress: = 0.0
var targetProgress: float

const FootstepDust = preload("res://content/monster/FootstepDust.tscn")

func init():
	position = path.curve.interpolate_baked(0) + path.global_position
	var d = position.x - (path.curve.interpolate_baked(50).x + + path.global_position.x)
	lastDelta = - d
	setFlip(d > 0.0)
	$Sprite.play("walk")
	updateHitboxState()
	$Sprite.frame = randi() % $Sprite.frames.get_frame_count("walk")
	$Sprite.speed_scale = speedModifier

var lastDelta: float
func subProcess(delta):
	if walking:
		progress += delta * Data.of("mucker.speed") * stunLevel() * speedModifier
		var cp = meleeTarget.curve.get_closest_point($HitPosition.global_position)
		if sign(lastDelta) != sign(cp.x - $HitPosition.global_position.x):

			animation("start_attack")
			walking = false
			$Sprite.speed_scale = 1.0
		else:
			position = path.curve.interpolate_baked(progress) + path.global_position

func leave(delta: float):
	if progress > 0.0:
		progress = max(0, progress - delta * Data.of("mucker.speed") * $Sprite.speed_scale)
		position = path.curve.interpolate_baked(progress) + path.global_position

func onGameLost():
	if currentHealth > 0:
		leaving = true
		animation("walk")
		$Sprite.speed_scale = 0.9 + randf() * 0.5
		setFlip( not $Sprite.flip_h)

func handleDamage():
	if stunIntensity >= fullStunAt:
		animation("hit")

func resumeAfterStagger():
	if walking:
		animation("walk")
	else:
		animation("attack")

func _on_Sprite_animation_finished():
	if $Sprite.animation == "die" or $Sprite.animation == "die_walk":
		.removeFreeBlocker()
	if $Sprite.animation == "start_attack":
		animation("attack")

func applyDamage():
	Level.dome.requestMeleeDamage(Data.of("mucker.damage") * damageModifier, $HitPosition.global_position, self)
	InputSystem.getCamera().shake(40, 0.3, 8, $HitPosition.global_position)
	$PunchSound1.play()
	$PunchSound2.play()
	$PunchSound3.play()

func _on_Sprite_frame_changed():
	if $Sprite.animation == "attack" and $Sprite.frame == 5:
		applyDamage()






func animateDeath():
	if walking:
		animation("die_walk")
	else:
		animation("die")
	$DieSound.play()
