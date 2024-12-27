extends "res://content/monster/Monster.gd"

enum Phase{APPEAR, EMERGE, SHOOT, BURROW, DIE}

var phase: int = Phase.APPEAR
var projetileTargetProvider
var path: Path2D

var cooldown: = 0.0
var didShoot: = false

func init():
	$Sprite.play("appear")
	setHittable(false)
	global_position = path.curve.interpolate_baked(path.curve.get_baked_length() * rand_range(0.2, 0.4)) + path.global_position
	setFlip(position.x > 0)

func subProcess(delta):
	if cooldown > 0.0:
		cooldown -= delta
		return 
	
	match phase:
		Phase.APPEAR:
			cooldown = 2.0 + randf() * 2.0
			phase = Phase.EMERGE
		Phase.EMERGE:
			animation("emerge")
			$EmergeSound.play()
			cooldown = 2.0 + randf() * 2.0
			phase = Phase.SHOOT
		Phase.SHOOT:
			animation("shoot")
			cooldown = 2.0 + randf() * 2.0
			didShoot = false
		Phase.BURROW:
			animation("burrow")
			$BurrowSound.play()
			cooldown = 3.0 + randf() * 3.0
			phase = Phase.EMERGE

func handleDamage():
	if stunIntensity >= fullStunAt:
		animation("hit")

func stagger():
	animation("hit")

func resumeAfterStagger():
	cooldown = 0.0
	if didShoot and phase == Phase.SHOOT:
		phase = Phase.BURROW

func _on_Sprite_animation_finished():
	match $Sprite.animation:
		"shoot":
			phase = Phase.BURROW
			animation("idle")
		"die":
			.removeFreeBlocker()
		"emerge":
			animation("idle")

func _on_Sprite_frame_changed():
	if $Sprite.animation == "burrow" and $Sprite.frame == 9:
		setHittable(false)
	elif $Sprite.animation == "emerge" and $Sprite.frame == 4:
		setHittable(true)
	elif $Sprite.animation == "shoot" and $Sprite.frame == 7:
		var rock = preload("res://content/monster/worm/Rock.tscn").instance()
		rock.setFlip($Sprite.flip_h)
		rock.position = $RockSpawnPosition.position + position
		rock.target = projetileTargetProvider.getRandom(global_position)
		get_parent().add_child(rock)
		rock.damageSource = damageSource
		$SpitSound.play()
		didShoot = true

func leave(delta: float):
	animation("burrow")

func animateDeath():
	$DieSound.play()
	animation("die")
