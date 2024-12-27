extends "res://content/monster/Monster.gd"

signal move_finished

enum Phase{SHOOT, TELEPORT, DIE}

var projetileTargetProvider
var movePointProvider
var phase: int
var cooldown: = 0.0
var nextSide: String
var teleportsLeft: int

func init():
	teleportsLeft = 2 + randi() % 2
	finishTeleport()

func setProviders(movePointProvider, projetileTargetProvider, side: String):
	self.movePointProvider = movePointProvider
	self.projetileTargetProvider = projetileTargetProvider
	var spawnType = Data.of("shifter.spawnpoint") + "_" + side
	position = movePointProvider.getSpawn(spawnType).position
	nextSide = side

func subProcess(delta):
	if cooldown > 0.0:
		cooldown -= delta
		return 
	
	match phase:
		Phase.SHOOT:
			pass
		Phase.TELEPORT:
			pass

func leave(delta: float):
	pass

func onGameLost():
	if currentHealth > 0:
		leaving = true
		animation("teleport_start")

func handleDamage():
	if stunIntensity >= fullStunAt:
		animation("hit")

func resumeAfterStagger():
	startTeleport()

func startTeleport():
	animation("teleport_start")
	phase = Phase.TELEPORT
	$TeleportAwaySound.play()

func finishTeleport():
	emit_signal("move_finished")
	animation("teleport_end")
	$TeleportAppearSound.play()
	
	position = movePointProvider.assignRandomPoint(nextSide, self).position
	nextSide = CONST.LEFT if nextSide == CONST.RIGHT else CONST.RIGHT
	setFlip(global_position.x > 0)
	teleportsLeft -= 1

func spawnShot():
	var p = preload("res://content/monster/shifter/ShifterProjectile.tscn").instance()
	p.damageSource = damageSource
	p.position = position + $ProjectilePosition.position
	p.origin = position
	p.target = projetileTargetProvider.getRandom(position) + Vector2(8 - randi() % 16, 8 - randi() % 16)
	p.damage = Data.of("shifter.damage") * damageModifier
	p.speed = Data.of("shifter.shotspeed")
	get_parent().add_child(p)
	$ShootSound.play()

func shoot():
	animation("shoot")
	$ChargingSound.play()
	phase = Phase.SHOOT

func animateDeath():
	$DieSound.play()
	animation("die")
	phase = Phase.DIE

func _on_Sprite_animation_finished():
	match $Sprite.animation:
		"teleport_start":
			if leaving:
				removeFreeBlocker()
				removeFreeBlocker()
				visible = false
			else:
				finishTeleport()
		"shoot":
			teleportsLeft = 1 + randi() % 3
			startTeleport()
		"teleport_end":
			if teleportsLeft > 0:
				startTeleport()
			else:
				shoot()

func _on_Sprite_frame_changed():
	if $Sprite.animation == "shoot" and $Sprite.frame == 28:
		spawnShot()
		pass
