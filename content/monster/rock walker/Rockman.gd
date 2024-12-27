extends "res://content/monster/Monster.gd"

export (float) var distanceToMeleePoint: = 10.0

enum State{WALK, STANDUP, ATTACK, DIE}

var state: int = State.WALK

var path: Path2D
var meleeTarget: Path2D
var attacking: = false
var progress: = 0.0
var targetProgress: float
var lastDelta: float

var initialPunchSpeed: float
var additionalPunchSpeed: float
var speedupTime: float
var currentAttackTime: float

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
	
	initialPunchSpeed = Data.of("rockman.initialPunchSpeed")
	additionalPunchSpeed = Data.of("rockman.additionalPunchSpeed")
	speedupTime = Data.of("rockman.speedupTime")

func subProcess(delta):
	match state:
		State.WALK:
			progress += delta * Data.of("rockman.speed") * stunLevel() * speedModifier
			var cp = meleeTarget.curve.get_closest_point($HitPosition.global_position)
			if sign(lastDelta) != sign(cp.x - $HitPosition.global_position.x):
				animation("standup")
				state = State.STANDUP
				$Sprite.speed_scale = speedModifier
			else:
				position = path.curve.interpolate_baked(progress) + path.global_position
		State.ATTACK:
			currentAttackTime += delta
			var progress = min(1.0, currentAttackTime / speedupTime)
			var speed = initialPunchSpeed + additionalPunchSpeed * progress
			$Sprite.speed_scale = speed * stunLevel() * speedModifier

func leave(delta: float):
		progress = max(0, progress - delta * Data.of("rockman.speed") * $Sprite.speed_scale)
		position = path.curve.interpolate_baked(progress) + path.global_position

func onGameLost():
	if currentHealth > 0:
		leaving = true
		animation("walk")
		$Sprite.speed_scale = 0.9 + randf() * 0.5
		setFlip( not $Sprite.flip_h)

func stagger():
	animation("hit")

func resumeAfterStagger():
	if state == State.WALK:
		animation("walk")
	elif state == State.ATTACK or state == State.STANDUP:
		animation("attack")

func _on_Sprite_animation_finished():
	if $Sprite.animation == "die":
		.removeFreeBlocker()
	elif $Sprite.animation == "standup":
		animation("attack")
		state = State.ATTACK

func applyDamage():
	Level.dome.requestMeleeDamage(Data.of("rockman.damage") * damageModifier, $HitPosition.global_position, self)
	InputSystem.getCamera().shake(40, 0.3, 8, $HitPosition.global_position)
	$PunchSound1.play()
	$PunchSound2.play()
	$PunchSound3.play()

func _on_Sprite_frame_changed():
	if $Sprite.animation == "attack" and $Sprite.frame == 9:
		applyDamage()





func animateDeath():
	state = State.DIE
	animation("die")
	$DieSound.play()
