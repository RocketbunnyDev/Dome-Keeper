extends "res://content/monster/Monster.gd"

signal move_finished


enum Phase{ENTER, SHOOT, SHRINK, GROW, PROTECTED, ARMOFF, DIE}
var phase: int = Phase.ENTER

var movePointProvider
var projectileTargetProvider

var entering: = true

var cooldown: = 0.0
var nextProtectionHealthThreshold: float

var pathProgress: = 0.0
var currentMoveCurve: Curve2D

func setProviders(movePointProvider, projectileTargetProvider, side: String):
	self.movePointProvider = movePointProvider
	self.projectileTargetProvider = projectileTargetProvider
	var spawnType = Data.of("scarab.spawnpoint") + "_" + side
	position = movePointProvider.getSpawn(spawnType).position

func init():
	var goalPos = movePointProvider.assignRandomPoint(CONST.CENTER, self).position
	currentMoveCurve = Curve2D.new()
	$EnterSound.play()
	currentMoveCurve.add_point(position)
	currentMoveCurve.add_point(goalPos)
	var pathLength = currentMoveCurve.get_baked_length()
	var time = pathLength / float(Data.of("scarab.speed"))
	moveTween.interpolate_property(self, "pathProgress", 0, pathLength, time, Tween.TRANS_QUAD, Tween.EASE_OUT)
	moveTween.start()
	
	$Sprite.play("idle")
	updateHitboxState()
	setFlip(position.x > 0)
	nextProtectionHealthThreshold = 0.5 * maxHealth


func _process(delta):
	if phase == Phase.SHOOT and currentHealth <= maxHealth * 0.25:
		armoff()

func subProcess(delta):
	if phase == Phase.ARMOFF:
		return 
	
	if phase != Phase.SHRINK and phase != Phase.ENTER and currentHealth <= nextProtectionHealthThreshold:
		phase = Phase.SHRINK
		$Sprite.play("shrink")
		$InvulnerableStartSound.play()
		lowerProtectionThreshold()
		return 
	
	if cooldown > 0.0:
		if phase != Phase.PROTECTED or timeSinceLastShotAt > 0.2:
			cooldown -= delta
		return 
	
	match phase:
		Phase.ENTER:
			var newPos = currentMoveCurve.interpolate_baked(pathProgress)
			position = newPos
			$Sprite.speed_scale = speedModifier
			if not moveTween.is_active():
				startBigShot()
		Phase.PROTECTED:
			$Sprite.play("grow")
			$InvulnerableStopSound.play()
			phase = Phase.GROW
		Phase.SHOOT:
			startBigShot()
			if cooldown > 0.0:
				cooldown -= delta

func armoff():
	$SplitSound.play()
	animation("armoff")
	phase = Phase.ARMOFF
	nextProtectionHealthThreshold = - 1
	for side in ["left", "right"]:
		var arm = preload("res://content/monster/scarab/ScarabArm.tscn").instance()
		var path = Level.world.getPath(Data.of("walker.movetype"), side)
		Level.monsters.registerMonster(arm)





		arm.position = find_node(side.capitalize() + "Arm").global_position
		arm.start(side, path)

func lowerProtectionThreshold():

	nextProtectionHealthThreshold = - 1

func leave(delta: float):
	position.y -= delta * 50
	position.x += delta * position.x * 0.1

func onGameLost():
	if currentHealth > 0:
		leaving = true
		animation("idle")

func handleDamage():
	pass

func stagger():
	moveTween.stop_all()

func resumeAfterStagger():
	moveTween.resume_all()

func animateDeath():
	$Sprite.play("die")
	$QuickShotSound.stop()
	$MassShootSound.stop()
	$DieSound.play()

func startBigShot():
	phase = Phase.SHOOT

	animation("shoot")

func _on_Sprite_animation_finished():
	match $Sprite.animation:
		"armoff":
			animation("quickshot")
		"shrink":
			animation("protected")
			cooldown = rand_range(5.0, 7.0)
			phase = Phase.PROTECTED
		"shoot":
			animation("idle")
			cooldown = 2.0
		"grow":
			startBigShot()
		"die":
			.removeFreeBlocker()
		"quickshot":
			$QuickShotSound.play()

func _on_Sprite_frame_changed():
	match $Sprite.animation:
		"grow":
			if $Sprite.frame == 8:
				invulnerable = false
				hitboxToDisable.append($HitboxQuickshot)
				hitboxToDisable.append($HitboxProtected)
				hitboxToEnable.append($HitboxDefault1)
				hitboxToEnable.append($HitboxDefault2)
				$InvulnerableHoldSound.stop()
		"shrink":
			if $Sprite.frame == 5:
				invulnerable = true
				stunIntensity = 0
				hitboxToDisable.append($HitboxDefault1)
				hitboxToDisable.append($HitboxDefault2)
				hitboxToDisable.append($HitboxQuickshot)
				hitboxToEnable.append($HitboxProtected)
				$InvulnerableHoldSound.play()
		"shoot":
			if $Sprite.frame == 12:
				spawnBigShot()
				$MassShootSound.play()
			elif $Sprite.frame == 2:
				$PreMassShootSound.play()
		"quickshot":
			if ($Sprite.frame == 3 or $Sprite.frame == 6 or $Sprite.frame == 9):
				spawnSmallShot()


func spawnBigShot():
	for offsetX in [ - 250, - 150, 150, 250]:
		var p = preload("res://content/monster/scarab/ScarabProjectile.tscn").instance()
		p.damageSource = damageSource
		p.damage = Data.of("scarab.damage") * damageModifier
		p.speed = Data.of("scarab.shotspeed") * rand_range(0.9, 1.1)
		offsetX *= rand_range(0.9, 1.1)
		get_parent().add_child(p)
		var path = Curve2D.new()
		var shotDirection = Vector2(offsetX + position.x * 0.5, - abs(offsetX))
		var target = projectileTargetProvider.getRandom(shotDirection) + Vector2(8 - randi() % 16, 8 - randi() % 16)
		path.add_point(position + $PositionBigProjectile.position, Vector2.ZERO, shotDirection)
		path.add_point(target, shotDirection)
		p.start(path, Tween.TRANS_CUBIC, Tween.EASE_OUT_IN)

func spawnSmallShot():
	var x = rand_range(100, 400)
	if randf() > 0.5:
		x *= - 1
	var y = rand_range( - 100, - 400)
	var p = preload("res://content/monster/scarab/ScarabProjectile.tscn").instance()
	p.damageSource = damageSource
	p.damage = Data.of("scarab.damage") * damageModifier
	p.speed = Data.of("scarab.shotspeed") * rand_range(0.9, 1.1)
	get_parent().add_child(p)
	var path = Curve2D.new()
	var shotDirection = Vector2(x, y)
	var target = projectileTargetProvider.getRandom(shotDirection) + Vector2(8 - randi() % 16, 8 - randi() % 16)
	path.add_point(position + $PositionBigProjectile.position, Vector2.ZERO, shotDirection)
	path.add_point(target, shotDirection)
	$QuickShotSound.play()
	p.start(path, Tween.TRANS_CUBIC, Tween.EASE_OUT_IN)
