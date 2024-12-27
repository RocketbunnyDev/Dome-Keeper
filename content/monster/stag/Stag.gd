extends "res://content/monster/Monster.gd"

export (float) var distanceToMeleePoint: = 10.0

var path: Path2D
var meleeTarget: Path2D
var projectileTargetProvider
var walking: = true
var progress: = 0.0
var lastDelta: float
var goalProgress: float

func init():
	goalProgress = path.curve.get_baked_length() * 0.6
	position = path.curve.interpolate_baked(progress) + path.global_position
	var d = position.x - (path.curve.interpolate_baked(progress + 50).x + path.global_position.x)
	lastDelta = - d
	setFlip(d > 0.0)
	$Sprite.play("walk")
	$StagEnters.play()
	updateHitboxState()
	$Sprite.speed_scale = speedModifier

func subProcess(delta):
	if walking:
		progress += delta * Data.of("stag.speed") * stunLevel() * speedModifier
		if goalProgress <= progress:
			animation("ground")
			$Sprite.speed_scale = 1.0
			walking = false
		else:
			position = path.curve.interpolate_baked(progress) + path.global_position

func leave(delta: float):
	if progress > 0.0:
		progress = max(0, progress - delta * Data.of("stag.speed") * $Sprite.speed_scale)
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
	if walking:
		animation("shoot")
	else:
		animation("ground")

func _on_Sprite_animation_finished():
	match $Sprite.animation:
		"walk":
			if abs(position.x) < 400 and not leaving:
				animation("shoot")


		"die":
			.removeFreeBlocker()

func _on_Sprite_frame_changed():
	match $Sprite.animation:
		"shoot":
			var spawnPos = get_node_or_null("Shot" + str($Sprite.frame))
			if spawnPos:
				spawnShot(spawnPos.global_position)
			if $Sprite.frame == 0:
				$BarrageSound.play()
		"ground":
			if $Sprite.frame == 16:
				spawnGroundProjectile()
			elif $Sprite.frame == 0:
				$StartPound.play()

func animateDeath():
	animation("die")
	$DieSound.play()

func spawnShot(startPos: Vector2):
	var x = rand_range(100, 400)
	var y = rand_range( - 300, - 500)
	if startPos.x > 0:
		x = - x
	
	var p = preload("res://content/monster/stag/StagAirProjectile.tscn").instance()
	p.damageSource = damageSource
	p.damage = Data.of("stag.airprojectiledamage") * damageModifier
	p.speed = Data.of("stag.airprojectilespeed") * rand_range(0.9, 1.1)
	get_parent().add_child(p)
	var path = Curve2D.new()
	var shotDirection = Vector2(x, y)
	var target = projectileTargetProvider.getRandom(shotDirection) + Vector2(8 - randi() % 16, 8 - randi() % 16)
	path.add_point(startPos, shotDirection)
	path.add_point(target, shotDirection)
	$StagShot.play()
	p.start(path, Tween.TRANS_LINEAR, Tween.EASE_OUT_IN)

func spawnGroundProjectile():
	InputSystem.getCamera().shake(100, 0.3, 8, $HitPosition.global_position)
	var p = preload("res://content/monster/stag/StagGroundProjectile.tscn").instance()
	p.damageSource = damageSource
	p.position = get_node("Ground1").global_position
	p.origin = p.position
	p.target = meleeTarget.curve.get_closest_point(p.origin) + Vector2(4 - randi() % 8, 4 - randi() % 8)
	p.damage = Data.of("stag.groundprojectiledamage") * damageModifier
	p.speed = Data.of("stag.groundprojectilespeed")
	$GroundPoundSound.play()
	get_parent().add_child(p)
	
