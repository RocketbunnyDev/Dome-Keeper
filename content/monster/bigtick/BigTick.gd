extends "res://content/monster/Monster.gd"

enum Phase{WALK, BURROW, EMERGE, JUMP, EXPLODE}
var phase: int = Phase.WALK

var path: Path2D
var target: Vector2

var pathBakedLength: float
var progress: = 0.0
var burrowProgress: = 0.0
var targetProgress: int
var speedScale: float
var burrowedCooldown: float
var offset: Vector2

const FootstepDust = preload("res://content/monster/FootstepDust.tscn")

func init():
	position = path.curve.interpolate_baked(0) + path.global_position
	var d = position.x - (path.curve.interpolate_baked(50).x + + path.global_position.x)
	setFlip(d > 0.0)
	$Sprite.play("walk")
	updateHitboxState()
	speedScale = 0.9 + randf() * 0.2
	$Sprite.frame = randi() % $Sprite.frames.get_frame_count("walk")
	$Sprite.speed_scale = speedScale * speedModifier
	targetProgress = 100 + 30 * randf()
	pathBakedLength = path.curve.get_baked_length()
	burrowProgress = (0.1 + randf() * 0.4) * pathBakedLength
	offset = Vector2(0, rand_range( - 3, 3))

func subProcess(delta):
	match phase:
		Phase.WALK:
			progress += delta * Data.of("bigtick.speed") * stunLevel() * speedScale * speedModifier
			if progress > burrowProgress:
				burrowProgress += (0.1 + randf() * 0.4) * pathBakedLength
				if burrowProgress > 0.8 * pathBakedLength:
					burrowProgress = pathBakedLength
				burrow()
				return 
			if abs(target.x - global_position.x) < targetProgress:
				animation("jump")
				phase = Phase.JUMP
				$Sprite.speed_scale = 1.0
				var peakY = (target.y + position.y) * 0.5 - 50 - randf() * 20
				moveTween.interpolate_property(self, "position:x", position.x, target.x, 1.0, Tween.TRANS_LINEAR, Tween.EASE_IN, 0.4)
				moveTween.interpolate_property(self, "position:y", position.y, peakY, 0.5, Tween.TRANS_QUAD, Tween.EASE_OUT, 0.4)
				moveTween.interpolate_property(self, "position:y", peakY, target.y, 0.5, Tween.TRANS_QUAD, Tween.EASE_IN, 0.9)
				moveTween.interpolate_callback(self, 1.4, "set", "phase", Phase.EXPLODE)
				moveTween.start()
				$JumpSound.play()
			else:
				position = path.curve.interpolate_baked(progress) + path.global_position + offset
		Phase.BURROW:
			burrowedCooldown -= delta
			if burrowedCooldown <= 0.0:
				emerge()
		Phase.EXPLODE:
			animation("explode")

func burrow():
	phase = Phase.BURROW
	burrowedCooldown = Data.of("bigtick.burrowtime") + randf() * 1.0
	animation("burrow")

func emerge():
	phase = Phase.EMERGE
	animation("emerge")
	setHittable(true)

func leave(delta: float):
	if progress > 0.0 and phase == Phase.WALK:
		progress = max(0, progress - delta * Data.of("bigtick.speed") * $Sprite.speed_scale)
		position = path.curve.interpolate_baked(progress) + path.global_position

func onGameLost():
	if currentHealth > 0:
		leaving = true
		if phase == Phase.WALK:
			animation("walk")
			$Sprite.speed_scale = 0.9 + randf() * 0.5
			setFlip( not $Sprite.flip_h)
		else:
			if not dead:
				die()
				animateDeath()

func handleDamage():
	if stunIntensity >= fullStunAt:
		animation("hit")

func _on_Sprite_animation_finished():
	if $Sprite.animation == "die":
		.removeFreeBlocker()
	elif $Sprite.animation == "explode":
		.removeFreeBlocker()
		die()
		$DieSoundExplode.play()
	elif $Sprite.animation == "burrow":
		setHittable(false)
	elif $Sprite.animation == "emerge":
		phase = Phase.WALK
		animation("walk")

func _on_Sprite_frame_changed():
	if $Sprite.animation == "explode" and $Sprite.frame == 1:
		applyDamage()






func resumeAfterStagger():
	
	if phase == Phase.JUMP:
		receiveDamage = 99
	animation("walk")
	phase = Phase.WALK

func stagger():
	animation("hit")

func applyDamage():
	Level.dome.requestMeleeDamage(Data.of("bigtick.damage") * damageModifier, global_position, self)
	InputSystem.getCamera().shake(40, 0.3, 8, global_position)

func animateDeath():
	$DieSound.play()
	animation("die")
