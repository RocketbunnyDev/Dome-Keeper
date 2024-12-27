extends "res://content/monster/Monster.gd"

enum Phase{ANNOUNCE, DIVE, STICK, RETREAT, RISE, GO_TO_DIVE_POSITION, LEAVE, DIE_DIVE}

var phase: int = Phase.DIVE
var domeTarget
var target

var retreatPosition: Position2D
var divePosition: Vector2

var cooldown: = 0.0
var yDiff: = 0

func init():
	position = divePosition
	$DeathFly.visible = false
	$DeathDive.visible = false
	$Sprite.play("dive")
	announce()

func dive():
	phase = Phase.DIVE
	target = domeTarget
	if target.x < global_position.x:
		rotation = (target - global_position).angle() - 0.74 * PI
	else:
		rotation = (target - global_position).angle() - 0.26 * PI
	animation("dive")
	$DiveSound.play()
	setHittable(true)

func retreat():
	phase = Phase.RETREAT
	target = retreatPosition.global_position
	target.y += 50 - 100 * randf()
	rotation = 0.0
	$Sprite.speed_scale = speedModifier

func announce():
	setHittable(false)
	phase = Phase.ANNOUNCE
	cooldown = Data.of("diver.announcedelay")
	$AnnounceSound.play()
	var warner = preload("res://content/monster/diver/DiveWarner.tscn").instance()
	warner.process_material = warner.process_material.duplicate()
	get_parent().add_child(warner)
	Style.init(warner)
	(warner.process_material as ParticlesMaterial).color.r *= 3
	(warner.process_material as ParticlesMaterial).color.g *= 3
	(warner.process_material as ParticlesMaterial).color.b *= 3
	var d = domeTarget - global_position
	if domeTarget.x < global_position.x:
		warner.process_material.direction.x = d.x
		warner.process_material.direction.y = d.y

	else:
		warner.process_material.direction.x = d.x
		warner.process_material.direction.y = d.y

	warner.position = global_position
	warner.get_node("Tween").interpolate_callback(warner, 3.0, "queue_free")
	warner.get_node("Tween").start()
	warner.emitting = true

func _process(delta: float)->void :
	if phase == Phase.DIE_DIVE:
		move(Data.of("diver.divespeed") * 0.3, delta)

func subProcess(delta):
	setFlip(position.x > 0)
	
	match phase:
		Phase.ANNOUNCE:
			cooldown -= delta
			if cooldown <= 0.0:
				dive()
		Phase.DIVE:
			if not move(Data.of("diver.divespeed"), delta):
				animation("dive_in")
				applyDamage()
		Phase.RETREAT:
			if not move(Data.of("diver.retreatspeed") * speedModifier, delta):
				$Sprite.speed_scale = 1.0
				phase = Phase.RISE
				target.y = divePosition.y
				setHittable(false)
				yDiff = 0
		Phase.RISE:
			if not move(Data.of("diver.risespeed"), delta):
				phase = Phase.GO_TO_DIVE_POSITION
				target = divePosition
		Phase.GO_TO_DIVE_POSITION:
			if not move(Data.of("diver.retreatspeed"), delta):
				announce()

func resumeAfterStagger():
	match phase:
		Phase.DIVE:
			animation("dive")
		Phase.RETREAT:
			animation("fly")
			$Sprite.speed_scale = speedModifier
		Phase.STICK:
			retreat()
			animation("fly")

func move(speed: float, delta: float):
	if target == null:
		return false
	var d = target - global_position
	var m = (d.normalized() * speed * delta).clamped(d.length()) * stunLevel()
	position += m
	return d.length() > 2.0

func applyDamage():
	Level.dome.requestMeleeDamage(Data.of("diver.damage") * damageModifier, global_position, self)
	InputSystem.getCamera().shake(100, 0.2, 8)

func domeAcceptsDamage():
	
	phase = Phase.STICK
	$ImpactSound.play()

func domeReflectsDamage(returnedDamage: float = 0.0, returnedSpeed: float = 1.0, damageModifier: float = 2.0):
	.domeReflectsDamage(returnedDamage, returnedSpeed)
	retreat()

func domeAbsorbsDamage():
	retreat()

func leave(delta: float):
	position += delta * (retreatPosition.position - position).normalized() * 100.0
	animation("fly")

func animateDeath():
	$DeathFly.flip_h = $Sprite.flip_h
	$DeathDive.flip_h = $Sprite.flip_h
	$Sprite.visible = false
	if phase == Phase.STICK or phase == Phase.RETREAT:
		$DeathFly.visible = true
		$DeathFly.play("default")
		$DieSoundFly.play()
	else:
		$DeathDive.visible = true
		$DeathDive.play("default")
		phase = Phase.DIE_DIVE
		$DieSoundDive.play()

func handleDamage():
	if phase == Phase.DIVE:
		currentHealth = 0
	
	if stunIntensity >= fullStunAt:
		animation("hit")

func _on_Sprite_animation_finished():
	if $Sprite.animation == "dive_in":
		animation("dive_out")
		
		moveTween.interpolate_property(self, "position", position, position + domeTarget * 0.5, 1.2, Tween.TRANS_LINEAR, Tween.EASE_IN, 1.2)
		moveTween.interpolate_callback($RetreatSound, 0.9, "play")
		moveTween.start()
	elif $Sprite.animation == "dive_out":
		retreat()
		animation("fly")
	elif $Sprite.animation == "fly" and $Sprite.frame % 4 == 0:
		$FlapSound.play()

func _on_Death_animation_finished()->void :
	.removeFreeBlocker()

