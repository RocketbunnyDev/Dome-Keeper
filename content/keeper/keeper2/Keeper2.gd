extends Keeper

signal tileHit

var minBallCharge: = 0.5
var chargeDirection: = Vector2()
var laggingChargeDirection: = Vector2()
var ballCharge: = 0.0
var bundleCharge: = 0.0
var collectCharge: = 0.0
var ballActionCooldown: = 0.0
var chargingBall: = false
var chargingBundle: = false
var chargingCollect: = false
var bundleShotRefPoint: = Vector2()
var tilesInBallArea: = []
var tileHitCooldown: = 0.5
var ballRotationSpeed: = 0.0

var insideLift: = false

var moveStopSoundPlayBuffer: = 0.0
var moveStartSoundPlayBuffer: = 0.0

func _ready():
	$ChargeCentral.modulate.a = 0.0
	$ChargeCentral.play("charge")
	$ChargePointer.modulate.a = 0.0
	$ChargePointer.play("default")
	
	$CollectSprite.scale *= 0
	
	$BallSprite.play("empty")
	$BallSprite / Spin.modulate.a = 0.75
	$BallSprite / Spin.play("spin")
	$BallSprite / Spin.hide()
	$Sprite.frame = 0
	focussedUsable = null
	focussedCarryable = null
	
	Data.apply("keeper2.remainingspheres", 1)
	
	Style.init(self)
	
	Level.addTutorial(self, "assessor_intro")
	Level.addTutorial(self, "assessor_reflect")
	Level.addTutorial(self, "assessor_bundle")


func _physics_process(delta):
	
	if position.y < 0:
		$Light.hide()
	else:
		$Light.show()
	
	if not $Light / Tween.is_active():
		var s: float = rand_range(1.0, 1.05)
		$Light / Tween.interpolate_property($Light, "scale", $Light.scale, Vector2(s, s), 0.08, Tween.TRANS_CUBIC)
		$Light / Tween.start()
	
	if Data.of("keeper.insidestation") or GameWorld.paused or disabled:
		$MoveSound.stop()
		return 
	
	if Data.of("keeper.insidedome"):
		chargingBall = false
		chargingBundle = false
	
	bundleShotRefPoint = global_position + moveDirectionInput * 40
	
	if ballActionCooldown > 0.0:
		ballActionCooldown -= delta
	
	
	
	var moveDotInput = moveDirectionInput.dot(move.normalized())
	var turnSpeed = (1.0 - moveDotInput)
	var strength = 8.0
	var absX = abs(moveDirectionInput.x)
	var absY = abs(moveDirectionInput.y)
	if absX > absY * 1.0:
		if absY > 0.0:
			strength = min(strength, absX / absY)
		move.y *= 1.0 - delta * turnSpeed * strength
	elif absY > absX * 1.0:
		if absX > 0.0:
			strength = min(strength, absY / absX)
		move.x *= 1.0 - delta * turnSpeed * strength
	
	var theoreticalBaseSpeed = currentSpeed()
	var relativeSpeed = clamp(move.length() / theoreticalBaseSpeed, 0, 1.0)
	var acceleration = Data.keeper("acceleration")
	
	
	
	acceleration *= min(1.0, (1.2 + 2.0 * max(0.0, turnSpeed)) - pow(relativeSpeed, 0.5))
	var deceleration = Data.keeper("deceleration")
	var moveChange = moveDirectionInput * (acceleration + Data.of("keeper.speedBuff")) * delta * 3
	if moveDirectionInput.length() == 0:
		move = move * (1 - delta * deceleration)
	else:
		var intentionDiff = move.dot(moveDirectionInput)
		if intentionDiff < 0:
			moveChange *= 1.0 - intentionDiff / 25.0
	
	move = move + moveChange
	if move.length() < 80:
		$MoveSound / MoveFastSound.setAdditionalVolume( - 60)
	else:
		$MoveSound / MoveFastSound.setAdditionalVolume( - 12 + 12.0 * clamp((move.length() - 80) / 160.0, 0.0, 1.0))
	
	var carrySize: = carriedCarryables.size()
	var slowdown: = 1.0
	for c in carriedCarryables:
		slowdown *= 1.0 - (c.additionalSlowdown / c.carrierCount())
	
	var collectChargeAffectingSpeed = max(50.0, theoreticalBaseSpeed * (1.0 - collectCharge * 1.0))
	var ballChargeAffectingSpeed = max(9.0, theoreticalBaseSpeed * (1.0 - ballCharge * 2.0))
	var bundleChargeAffectingSpeed = max(9.0, theoreticalBaseSpeed * (1.0 - bundleCharge * 2.0))
	var loweredByCarryables = max(20.0 - carrySize, theoreticalBaseSpeed * (1.0 - pow(carrySize, 3) * 0.0065))
	var baseSpeed = min(loweredByCarryables, min(ballChargeAffectingSpeed, min(collectChargeAffectingSpeed, bundleChargeAffectingSpeed)))
	var maxSpeed = baseSpeed * slowdown
	if externallyMoved:
		move *= 0
		moveDirectionInput *= 0
	if chargingCollect:
		maxSpeed *= 0.4
	move = move.clamped(max(0, maxSpeed))
	
	var actualMove = position
	move = move_and_slide(move)
	actualMove = position - actualMove
	GameWorld.travelledDistance += actualMove.length()
	
	var speedBuff = Data.of("keeper.speedBuff")
	var drillBuff = Data.of("keeper.drillBuff")
	if speedBuff > 0 or drillBuff > 0:
		animationSuffix = "_buffed"
	else:
		animationSuffix = ""
	
	updateMoveAnimation(actualMove, delta)
	
	if tileHitCooldown > 0.0:
		tileHitCooldown -= (1.0 + 0.1 * ballRotationSpeed) * delta
	$BallSprite.rotation += ballRotationSpeed * delta * 2.0
	if ballRotationSpeed > 2.0:
		var alpha = ease(ballRotationSpeed / 10.0, 2.0)
		$BallSprite / Spin.show()
		$BallSprite / Spin.modulate.a = alpha
		$BallSprite / SpinParticles.emitting = true
		$BallSprite / SpinParticles.rotation += ballRotationSpeed * delta
	else:
		$BallSprite / Spin.hide()
		$BallSprite / SpinParticles.emitting = false
	
	updateChargeDirection(delta)
	updateBallCharge(delta)
	updateCollectCharge(delta)
	updateBundleCharge(delta)
	
	
	for influence in get_tree().get_nodes_in_group("carry_influence"):
		var carryable = influence.getCarryable()
		if not (chargingCollect and carryables.has(carryable)) and not carriedCarryables.has(carryable):
			influence.beingPulled = false
			if influence.isBundled():
				influence.strength -= delta * (1.0 / float(Data.of("keeper2.bundleduration")))
			else:
				var change = delta * 0.2
				if not carryable is Drop:
					change *= 5
				influence.strength -= change
	
	var collectScaling = min(1.0, sqrt(collectCharge))
	$CarryArea / CollisionDrops.shape.radius = 60 * collectScaling
	$CollectSprite.scale = Vector2.ONE * collectScaling
	
	
	
	updateInteractables()
	
	for c in carriedCarryables.duplicate():
		var d: Vector2 = global_position - c.global_position
		var l = d.length()
		if l > 120:
			dropCarry(c)
			continue
		d = (d.normalized() * pow(d.length() * 0.1, 2)).clamped(20)
		d += d.rotated(PI * 0.5) * 0.1
		c.apply_central_impulse(d)

func updateBallCharge(delta: float):
	if chargingBall and tilesInBallArea.size() > 0 and ballCharge > 0:
		if tileHitCooldown <= 0.0:
			var tile = tilesInBallArea.front()
			var dir = global_position - tile.global_position
			var damage = Data.of("keeper2.spherebasedamage") * 0.5 + tile.max_health * Data.of("keeper2.directminingdamage") * (1.0 + Data.of("keeper.drillBuff"))
			tile.hit(dir, damage)
			tileHitCooldown = 0.5
			$BallDrill.setAdditionalPitch(0.4 * (1.0 - tile.relativeHealth()))
		if not $BallDrill.playing:
			$BallDrill.play()
			$BallDrillInit.play()
	else:
		if $BallDrill.playing:
			$BallDrill.stop()
	
	var remainingShots = Data.of("keeper2.remainingspheres")
	if remainingShots < Data.of("keeper2.totalspheres"):

		var reloadCounter = Data.ofOr("keeper2.currentspherereload", 0.0)
		reloadCounter += delta
		if Data.of("keeper2.spherereload") <= reloadCounter:
			Data.apply("keeper2.currentspherereload", 0)
			Data.apply("keeper2.remainingspheres", remainingShots + 1)
		else:
			Data.apply("keeper2.currentspherereload", reloadCounter)
	
	if chargingBall and remainingShots > 0 and not Data.of("keeper.insidedome"):
		if ballCharge == 0.0:
			
			$PinballChargeStart.play()
			$PinballCharging.play()
			$BallSprite.rotation = 0.0
			$BallSprite.play("creating")
			$BallSprite.position = Vector2(0, 2)
			$Sprite.play("charge" + animationSuffix)
		
		$PinballCharging.pitch_scale = 1.0 + ballCharge * 1.0
		$PinballCharging.volume_db = - 12 + ballCharge * 12.0
		$BallSprite.position = Vector2(0, 2) + chargeDirection * 15
		ballRotationSpeed = clamp(ballRotationSpeed + (10.0 - ballRotationSpeed) * (laggingChargeDirection.length() - 0.5) * delta * 2, 0.0, 10.0)
		
		
		$ChargeCentral.play("charge")
		$ChargeCentral.modulate.a = laggingChargeDirection.length() * 2.0
		$ChargePointer.rotation = laggingChargeDirection.angle()
		$ChargePointer.scale.x = laggingChargeDirection.length()
		$ChargePointer.modulate.a = laggingChargeDirection.length()
		
		
		var newCharge = min(1.0, ballCharge + delta * (1.5 - ballCharge) * 1.25)
		if newCharge == 1.0 and ballCharge < 1.0:
			$PinballChargeMax.play()
		ballCharge = newCharge
		$ChargeCentral.scale = ballCharge * Vector2.ONE * rand_range(0.96, 1.04)
		$ChargeCentral.modulate.a = ballCharge * 0.5
	else:
		if ballCharge > minBallCharge and laggingChargeDirection.length() > 0.5:
			shootPinball()
		elif ballCharge > 0.0:
			abortShot()
		$PinballCharging.stop()
		
		ballCharge = 0.0
		$ChargeCentral.scale = Vector2.ONE * 0.0
		$ChargePointer.modulate.a = 0.0
		$BallSprite.play("empty")
		
		chargeDirection *= 0.0
		
		ballRotationSpeed = 0.0

func addSphere():
	Data.changeByInt("keeper2.remainingspheres", 1)

var oldAimLength: = 0.0
func updateChargeDirection(delta: float):
	var aimHelpSecondaryDirection = Vector2(moveDirectionInput.x, moveDirectionInput.y)
	if chargingBall:
		if aimHelpSecondaryDirection.length() - 0.6 > oldAimLength:
			$PinballAimStart.play()
			oldAimLength = 1.0
		elif aimHelpSecondaryDirection.length() + 0.6 < oldAimLength:
			$PinballAimCancel.play()
			oldAimLength = 0.0
	if chargingBundle:
		if aimHelpSecondaryDirection.length() - 0.6 > oldAimLength:
			$BundleAimStart.play()
			oldAimLength = 1.0
		elif aimHelpSecondaryDirection.length() + 0.6 < oldAimLength:
			$BundleAimCancel.play()
			oldAimLength = 0.0
	
	for rot in [ - 0.5 * PI, 0, 0.5 * PI, PI, 1.5 * PI]:
		var rotDelta = aimHelpSecondaryDirection.angle() - rot
		if abs(rotDelta) < PI * 0.08:
			aimHelpSecondaryDirection = aimHelpSecondaryDirection.rotated( - rotDelta * 1.0)
			break
	chargeDirection = laggingChargeDirection * (1.0 - delta * 10.0) + aimHelpSecondaryDirection * (delta * 10.0)
	if chargeDirection.length() > 1.0:
		chargeDirection = chargeDirection.normalized()
	
	var ldiff = chargeDirection.length() - laggingChargeDirection.length()
	if ldiff > 0.0:
		laggingChargeDirection = chargeDirection
	else:
		var oldLength = laggingChargeDirection.length()
		var newLength = max(0.0, oldLength * (1.0 - delta * 2) - delta)
		if chargeDirection.length() > 0.5:
			laggingChargeDirection = chargeDirection.normalized() * newLength
		else:
			laggingChargeDirection = laggingChargeDirection.normalized() * newLength

func updateBundleCharge(delta: float):
	var relativeBundleCharge = bundleCharge / 1.0
	if chargingBundle:
		if bundleCharge == 0.0:
			
			$BundleChargeStart.play()
			$BundleCharging.play()
		bundleCharge = min(1.0, bundleCharge + delta * 4.0)
		
		
		$ChargeCentral.play("bundle")
		$ChargeCentral.modulate.a = laggingChargeDirection.length() * 2.0
		$ChargeCentral.rotation = rand_range(deg2rad( - 1), deg2rad(1))
		$ChargePointer.rotation = laggingChargeDirection.angle()
		$ChargePointer.scale.x = laggingChargeDirection.length()
		$ChargePointer.modulate.a = laggingChargeDirection.length()
		
		if bundleCharge > minBallCharge:
			$ChargeCentral.modulate.a = bundleCharge * 0.5
			$ChargeCentral.scale = bundleCharge * Vector2.ONE * rand_range(0.96, 1.04)
	elif bundleCharge > 0.0:
		if bundleCharge > minBallCharge and laggingChargeDirection.length() > 0.4:
			shootBundle(relativeBundleCharge)
		else:
			abortShot()
		bundleCharge = 0.0
		chargeDirection *= 0.0
		$ChargeCentral.scale = Vector2.ONE * 0.0
		$BundleCharging.stop()

func updateCollectCharge(delta):
	
	if chargingCollect:
		$CarryArea / CollisionDrops.disabled = false
		$CarryArea / CollisionNotDrops.disabled = true
		$Sprite.play("pull" + animationSuffix)
		var untilMaxCharge = 1.0 - collectCharge
		collectCharge = min(1.0, collectCharge + delta * 0.15 + pow(untilMaxCharge, 2) * delta * 0.4)
		for c in carryables:
			if c.carryableType != "resource":
				continue
			var influence = c.getOrCreateCarryInfluence()
			var newStrength = influence.strength + delta * 1.0
			influence.strength = min(1.0, newStrength)
			influence.beingPulled = true
			if carriedCarryables.has(c):
				continue
			
			var d: Vector2 = global_position - c.global_position
			if d.length() < GameWorld.TILE_SIZE * 2 and newStrength >= 0.9:
				if influence.isBundled():
					var inBundle = influence.getBundle().getBundledInfluences()
					for i in inBundle:
						influence.exitBundle()
					for i in inBundle:
						attachCarry(i.getCarryable())
					return 
				else:
					attachCarry(c)
					continue
			
			c.apply_central_impulse(d.clamped(pow(newStrength * 4, 1.5)))
	else:
		if collectCharge > 0.0:
			collectCharge = max(0.0, collectCharge - 1 * delta)
		$CarryArea / CollisionDrops.disabled = true
		$CarryArea / CollisionNotDrops.disabled = false
	
	
	$ChargeCollectAmb.setAdditionalPitch(collectCharge * 0.6)
	var carrysize = carriedCarryables.size()
	if carrysize == 0:
		$ChargeCollectAmb.stop()
	elif not chargingCollect:
		
		$ChargeCollectAmb.setAdditionalVolume( - 12 + min(1.0, 8 * carrysize / 6.0))
	else:
		$ChargeCollectAmb.setAdditionalVolume(0)

func updateMoveAnimation(actualMove: Vector2, delta: float):
	var combinedMove = moveDirectionInput
	if actualMove.length() > 0.15:
		combinedMove += actualMove
	var moving = combinedMove.length() > 0.35
	$Trail.emitting = moving
	$StoppedParticles.emitting = not moving
	
	if collectCharge == 0.0 and ballCharge == 0.0:
		if combinedMove.length() < 0.35:
			$Sprite.play("default" + animationSuffix)
		else:
			if abs(combinedMove.x) > abs(combinedMove.y) * 0.95:
				$Sprite.play("left" + animationSuffix if combinedMove.x < 0 else "right" + animationSuffix)
			else:
				$Sprite.play("up" + animationSuffix if combinedMove.y < 0 else "down" + animationSuffix)
		if moveDirectionInput.length() == 0:
			moveStartSoundPlayBuffer = 0
			if $MoveSound.shouldPlay:
				moveStopSoundPlayBuffer += delta
				if moveStopSoundPlayBuffer >= 0.2:
					$MoveSound.stop()
					$MoveStopSound.play()
					moveStopSoundPlayBuffer = 0
		else:
			moveStopSoundPlayBuffer = 0
			if not $MoveSound.shouldPlay:
				moveStartSoundPlayBuffer += delta
				if moveStartSoundPlayBuffer >= 0.1:
					$MoveSound.play()
					$MoveStartSound.play()
					moveStartSoundPlayBuffer = 0

func updateCarryables():
	if not is_instance_valid(focussedCarryable):
		focussedCarryable = null
	
	if focussedCarryable:
		if not focussedCarryable.canFocusCarry()\
		 or not carryables.has(focussedCarryable)\
		 or carriedCarryables.has(focussedCarryable)\
		 or (focussedCarryable.is_in_group("usables") and not usables.has(focussedCarryable.get_meta("usable"))):
			focussedCarryable.unfocusCarry(self)
			focussedCarryable = null
	
	
	var potentialCarryables: = []
	for carryable in carryables:
		if not is_instance_valid(carryable):
			continue
		
		if not carriedCarryables.has(carryable)\
		 and carryable.carryableType == "gadget"\
		 and carryable.canFocusCarry()\
		 and (pickupType == "" or pickupType == carryable.carryableType)\
		 and ( not carryable.is_in_group("usables") or usables.has(carryable.get_meta("usable"))):
				
				potentialCarryables.append(carryable)
	
	potentialCarryables.sort_custom(self, "sortByDistance")
	
	for carryable in potentialCarryables:
		if focussedCarryable == carryable:
			return 
		else:
			if focussedCarryable:
				focussedCarryable.unfocusCarry(self)
			focussedCarryable = carryable
			focussedCarryable.focusCarry(self)
		return 

func abortShot():
	$ChargeAbort.play()

func attachCarry(body):
	if carriedCarryables.has(body):
		Logger.error("Tried to attach carryable " + body.name + "although it's already carried ")
		return 
	body.unfocusCarry(self)
	var influence = body.getOrCreateCarryInfluence()
	influence.strength = 1.0
	
	var po = CarryablePhysicsOverride.new()
	po.gravity_scale = 0.0
	po.linear_damp = 2
	po.angular_damp = 2
	body.addPhysicsOverride(po)
	carriedCarryables.append(body)
	body.setCarriedBy(self)
	
	$Pickup.play()

func shootPinball():
	$Shoot.play()
	var sphere = preload("res://content/keeper/keeper2/Pinball.tscn").instance()
	sphere.position = position
	get_parent().add_child(sphere)
	
	sphere.apply_central_impulse(laggingChargeDirection.length() * laggingChargeDirection.normalized() * 150)
	InputSystem.getCamera().shake(50, 0.2)
	
	move += chargeDirection.normalized().rotated(PI) * 100
	
	Data.changeByInt("keeper2.remainingspheres", - 1)

func shootBundle(relativeSmashCharge: float):
	var bundle = preload("res://content/keeper/keeper2/Bundle.tscn").instance()
	bundle.position = position
	Level.stage.add_child(bundle)
	var bundleGroup: Array = []
	for carryable in carriedCarryables:
		if carryable.carryableType == "resource":
			bundleGroup.append(carryable)
	
	if bundleGroup.size() == 0:
		bundleGroup = carriedCarryables.duplicate()
	
	bundleGroup.sort_custom(self, "sortByDistanceToRefPo")
	for b in bundleGroup:
		dropCarry(b)
	bundle.start(laggingChargeDirection.normalized(), 30.0 * relativeSmashCharge, bundleGroup)
	
	if relativeSmashCharge > 0.0:
		var groupSize = bundleGroup.size()
		if groupSize <= 3:
			$BundleShotSmall.play()
		elif groupSize <= 8:
			$BundleShotMedium.play()
		else:
			$BundleShotBig.play()
		move += laggingChargeDirection.normalized().rotated(PI) * groupSize * relativeSmashCharge * 10

func ballHold():
	if disabled or Data.of("keeper.insidedome"):
		return 
	
	collectRelease()
	if carriedCarryables.size() == 0:
		chargingBall = true
		chargingBundle = false
	elif Data.of("keeper2.bundlespheres"):
		chargingBall = false
		chargingBundle = true

func ballRelease():
	collectRelease()
	chargingBall = false
	
	if chargingBundle:
		chargingBundle = false
		

func ballHit():
	if disabled or Data.of("keeper.insidedome"):
		return 
	
	if carriedCarryables.size() > 0:
		if Data.of("keeper2.bundlespheres"):
			shootBundle(0.0)
	else:
		if Data.of("keeper2.reflectsphere"):
			if ballActionCooldown <= 0.0:
				move *= 0.0
				$BallReflectArea.reflect()
				$Tween.interpolate_callback($BallReflectArea, 0.3, "stopReflect")
				$Tween.start()
				$ReflectionActivated.play()
				ballActionCooldown = 0.5
			else:
				$ReflectionBlocked.play()
		elif Data.of("keeper2.spheresplit"):
			if ballActionCooldown <= 0.0:
				move *= 0.0
				$BallSplitArea.catch()
				$Tween.interpolate_callback($BallSplitArea, 0.2, "stopCatching")
				$Tween.start()
				$CatchActivated.play()
				$SphereSplit.play();
				ballActionCooldown = 2.5
			else:
				$ReflectionBlocked.play()

func collectHold():
	if disabled:
		return 
	
	chargingBall = false
	chargingCollect = true
	chargingBundle = false
	$ChargeCollectStart.play()
	$ChargeCollectAmb.play()

func collectRelease():
	if chargingCollect:
		chargingCollect = false
		$ChargeCollectStart.stop()

func collectHit():
	
	if focussedCarryable:
		attachCarry(focussedCarryable)
		return 
	
	for u in usables:
		if u.canPickup():
			u.useHit(self)
			return 
	
	if carriedCarryables.size() == 0:
		$NothingToDrop.play()
		return 
	
	var carrySort = carriedCarryables.duplicate()
	if moveDirectionInput.length() > 0:
		carrySort.sort_custom(self, "sortByDistanceToRefPo")
		var farthestCarryable
		for carryable in carrySort:
			if carryable.carryableType == "resource":
				farthestCarryable = carryable
				break
		if not farthestCarryable:
			farthestCarryable = carrySort.front()
		dropCarry(farthestCarryable)
		$Drop.play()
		var influence = farthestCarryable.getOrCreateCarryInfluence()
		influence.strength = 1.0
		var impulse = laggingChargeDirection.normalized() * 150
		farthestCarryable.apply_central_impulse(impulse - farthestCarryable.linear_velocity)
	else:
		carrySort.sort_custom(self, "sortByDistanceToGlobalPos")
		var farthestCarryable
		for carryable in carrySort:
			if carryable.carryableType == "resource":
				farthestCarryable = carryable
				break
		if not farthestCarryable:
			farthestCarryable = carrySort.front()
		dropCarry(farthestCarryable)
		$Drop.play()
		var influence = farthestCarryable.getOrCreateCarryInfluence()
		influence.strength = 1.0
		farthestCarryable.apply_central_impulse(farthestCarryable.linear_velocity.rotated(PI))

func sortByDistanceToRefPo(d1, d2)->bool:
	return (d1.global_position - bundleShotRefPoint).length() < (d2.global_position - bundleShotRefPoint).length()

func sortByDistanceToGlobalPos(d1, d2)->bool:
	return (d1.global_position - global_position).length() > (d2.global_position - global_position).length()

func dropCarry(carryable):
	carriedCarryables.erase(carryable)
	carryable.freeCarry(self)

func currentSpeed()->float:
	var s = Data.keeper("maxSpeed") + Data.of("keeper.additionalmaxspeed")
	s += Data.of("keeper.speedBuff")
	var yMove = move.normalized().y
	if yMove < 0:
		s += Data.of("keeper.additionalupwardsspeed") * abs(yMove)
	return s

func disableEffects():
	$StoppedParticles.emitting = false
	$Trail.emitting = false
	$PinballAmmo.visible = false

func enableEffects():
	$PinballAmmo.visible = true

func _on_BallSprite_animation_finished():
	if $BallSprite.animation == "creating":
		$BallSprite.play("ready")

func _on_BallArea_body_entered(body):
	if body.has_meta("destructable") and body.get_meta("destructable"):
		tilesInBallArea.append(body)

func _on_BallArea_body_exited(body):
	if body.has_meta("destructable") and body.get_meta("destructable"):
		tilesInBallArea.erase(body)

func getBallActionCooldown()->float:
	return ballActionCooldown
