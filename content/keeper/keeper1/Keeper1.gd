extends Keeper

signal tileHit

onready var DrillSprite = $DrillSprite
onready var DrillHitTestRay = $DrillHitTestRay

export (bool) var simulatedCarrySlowdown: = false

var knockbackDirection: = Vector2()
var moveSlowdown: = 0.0
var carrySlowdown: = 0.0
var hitCooldown: = 0.0
var spriteLockDuration: = 0.0
var moveStopSoundPlayBuffer: = 0.0
var moveStartSoundPlayBuffer: = 0.0
const maxCarryLineLength: = 150.0

var carryLines: = {}

func _ready():
	Data.listen(self, "keeper1.jetpackStage")
	
	$Sprite.frame = 0
	focussedUsable = null
	focussedCarryable = null
	hitCooldown = 0.0
	
	$ThrusterLeft.emitting = true
	$ThrusterRight.emitting = true
	$ThrusterLeft / Booster.playing = true
	$ThrusterRight / Booster.playing = true
	$DrillHit.frame = 4
	
	Style.init(self)
	
	Level.addTutorial(self, "keeper1_pickup")
	Level.addTutorial(self, "keeper1_drop")
	
	Achievements.addIfOpen(self, "KEEPER1_SHOPPINGBAG")
	Achievements.addIfOpen(self, "KEEPER1_SPEED")

func propertyChanged(property: String, oldValue, newValue):
	match property:
		"keeper1.jetpackstage":
			setJetpackStage(newValue)

func _physics_process(delta):
	
	$Light.visible = position.y > 0
	
	if Data.of("keeper.insidestation") or GameWorld.paused or disabled:
		$MoveSound.stop()
		$CarryLoadSound.stop()
		return 
	
	control_thruster_vfx(move, moveDirectionInput.length() > 0.0, delta)
	
	var carrySize: = 0.0
	for i in range(1, carriedCarryables.size() + 1):
		if not is_instance_valid(carriedCarryables[i - 1]):
			continue
		carrySize += i / float(carriedCarryables[i - 1].carrierCount())
	
	moveSlowdown *= 1.0 - delta * Data.of("keeper1.slowdownRecovery") * 1.0
	
	var baseSpeed = currentSpeed()
	var desiredMove: Vector2 = moveDirectionInput * baseSpeed
	
	if abs(moveDirectionInput.x) < 0.1 and abs(moveDirectionInput.y) > 0.9:
		move.x *= 1 - delta * Data.of("keeper1.deceleration")
	if abs(moveDirectionInput.y) < 0.1 and abs(moveDirectionInput.x) > 0.9:
		move.y *= 1 - delta * Data.of("keeper1.deceleration")
	
	var moveChange = desiredMove * Data.of("keeper1.acceleration") * delta * max(0.1, 1.0 - moveSlowdown)
	moveChange = moveChange.clamped(max(0, desiredMove.length() - move.length()))
	move = (move * (1 - delta * Data.of("keeper1.deceleration"))) + moveChange
	
	var totalCarryImpulse = updateCarry()
	if simulatedCarrySlowdown:

		carrySlowdown = clamp(totalCarryImpulse.length() / 20.0, 0.0, 0.9)

	else:
		
		carrySlowdown = 0.01 * Data.of("keeper1.speedLossPerCarry") * carrySize
	
	var slowdown: = 1.0
	for c in carriedCarryables:
		slowdown *= 1.0 - (c.additionalSlowdown / c.carrierCount())
	
	var maxSpeed = baseSpeed * slowdown
	maxSpeed -= carrySlowdown * maxSpeed
	if externallyMoved:
		move *= 0
		moveDirectionInput *= 0
	move = move.clamped(max(0, maxSpeed))
	
	var actualMove = position
	move_and_slide(move)
	actualMove = position - actualMove
	GameWorld.travelledDistance += actualMove.length()

	
	if hitCooldown > 0:
		hitCooldown = max(hitCooldown - delta, 0)

	
	if moveDirectionInput.length() > 0.0 and hitCooldown <= 0:
		drill_check()
	
	updateCarry()
	
	if $CarryLoadSound.playing:
		$CarryLoadSound.volume_db = min( - 2, - 30 + carrySlowdown * 50)
	
	var speedBuff = Data.of("keeper.speedBuff")
	var drillBuff = Data.of("keeper.drillBuff")
	if speedBuff > 0 or drillBuff > 0:
		animationSuffix = "_buffed"
	else:
		animationSuffix = ""
	
	$Trail.emitting = moveDirectionInput.length() > 0 and hitCooldown <= 0.0 and spriteLockDuration <= 0.0
	$Trail.direction = - moveDirectionInput
	
	if spriteLockDuration > 0.0:
		spriteLockDuration -= delta
	else:
		var combinedMove = moveDirectionInput
		if actualMove.length() > 0.15:
			combinedMove += actualMove
		$DrillSprite.hide()
		$DrillSprite.stop()
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
					$CarryLoadSound.stop()
					$MoveStopSound.play()
					$StillSound.play()
					moveStopSoundPlayBuffer = 0
		else:
			moveStopSoundPlayBuffer = 0
			if not $MoveSound.shouldPlay:
				moveStartSoundPlayBuffer += delta
				if moveStartSoundPlayBuffer >= 0.1:
					$MoveSound.play()
					$CarryLoadSound.play()
					$MoveStartSound.play()
					$StillSound.stop()
					moveStartSoundPlayBuffer = 0
			
	
	for t in carryLines:
		var line = carryLines[t]
		line.set_point_position(0, global_position)
		line.set_point_position(1, t.global_position)
	
	
	
	updateInteractables()

func updateCarry():
	var longest = 0
	for c in carriedCarryables.duplicate():
		if c.independent:
			dropCarry(c)
		else:
			var d = (position - c.position).length()
			if d > longest:
				longest = d
			if d > maxCarryLineLength:
				dropCarry(c)
				$CarryLineBreak.play()

	var breakThreshold = 0.7
	if longest > breakThreshold * maxCarryLineLength:
		if not $CarryLineStretch.playing:
			$CarryLineStretch.play()
		var pitch = (longest - breakThreshold * maxCarryLineLength) / ((1.0 - breakThreshold) * maxCarryLineLength)
		$CarryLineStretch.pitch_scale = 1 + ease(pitch, 0.6)
	else:
		$CarryLineStretch.stop()
	
	var strength: = 0.15
	var totalImpulse: = Vector2()
	for c in carriedCarryables:
		var dist = position - c.position
		
		if dist.length() < 12.0:
			dist *= 0.0
		else:
			dist -= dist.normalized() * 12
		if dist.y < 0:
			dist.y -= 2.0 * pow(1.0 + dist.length() / maxCarryLineLength, 4)
		
		var factor: = 1.0
		var off = dist.length() - 0.15 * maxCarryLineLength
		if off > 0:
			var fill = abs(off / (0.8 * maxCarryLineLength))
			if randf() < fill:
				factor = 10.0 * fill
		var impulse = (dist * strength * factor).clamped(100)
		totalImpulse += impulse
		c.apply_central_impulse(impulse)
		strength = max(strength * 0.9, 0.005)
	return totalImpulse

func attachCarry(body):
	if carriedCarryables.has(body):
		Logger.error("Tried to attach carryable " + body.name + "although it's already carried ")
		return 
	body.unfocusCarry(self)
	var po = CarryablePhysicsOverride.new()
	po.linear_damp = 2
	po.angular_damp = 2
	body.addPhysicsOverride(po)
	carriedCarryables.append(body)
	body.setCarriedBy(self)
	$Pickup.play()
	
	var carryLine = preload("res://content/keeper/Carryline.tscn").instance()
	carryLine.add_point(position)
	carryLine.add_point(body.position)
	get_parent().add_child(carryLine)
	carryLines[body] = carryLine
	Style.init(carryLine)
	
	if not $CarryLine.playing:
		$CarryLine.play()

func dropCarry(body):
	if not carriedCarryables.has(body):
		Logger.error("keeper wants to drop carryable that isn't carried", "Keeper.dropCarry", {"carryable": body.name, "carry": str(carriedCarryables)})
		return 
	carriedCarryables.erase(body)
	body.freeCarry(self)
	$Drop.play()
	
	
	var brk = Data.CARRYLINE_BREAK.instance()
	brk.global_position = global_position
	brk.target = body.global_position
	Level.stage.add_child(brk)
	
	
	carryLines[body].queue_free()
	carryLines.erase(body)

	if carryLines.size() == 0:
		$CarryLine.stop()

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

func pickupHit():
	if Data.of("keeper.insidestation") or disabled:
		return false
	
	if focussedCarryable:
		pickup(focussedCarryable)

func pickupHold():
	if Data.of("keeper.insidestation") or disabled:
		return false
	
	if focussedCarryable:
		pickup(focussedCarryable)
		pickupType = focussedCarryable.carryableType

func pickupHoldStopped():
	pickupType = ""

func dropHit():
	if Data.of("keeper.insidestation") or disabled:
		return 
	
	var farthestDrop
	var distance: = 0.0
	for c in carriedCarryables:
		var dist = (c.global_position - global_position).length()
		if dist > distance:
			distance = dist
			farthestDrop = c
	if farthestDrop:
		dropCarry(farthestDrop)
		return true

func dropHold():
	if Data.of("keeper.insidestation") or disabled:
		return 

	if carriedCarryables.size() > 0:
		var drop = carriedCarryables.front()
		dropCarry(drop)

func pickup(drop):
	attachCarry(drop)

func currentSpeed()->float:
	var s = Data.of("keeper1.maxSpeed") + Data.of("keeper.additionalmaxspeed")
	s += Data.of("keeper.speedBuff")
	var yMove = move.normalized().y
	if yMove < 0:
		s += Data.of("keeper.additionalupwardsspeed") * abs(yMove)
	var limit = Data.ofOr("keeper.speedlimit", - 1)
	if limit >= 0.0 and limit < s:
		s = limit
	return s

func drill_check()->void :
	DrillHitTestRay.rotation = moveDirectionInput.angle()

	DrillHitTestRay.force_raycast_update()
	var tile = DrillHitTestRay.get_collider()
	if not (tile and tile.has_meta("destructable") and tile.get_meta("destructable")):
		return 
	var dir = global_position - tile.global_position
	tile.hit(dir, Data.of("keeper1.drillStrength"))

	if Options.shakeDrill:
		InputSystem.getCamera().shake(20, 0.2, 8)

	
	var soundPlayer: AudioStreamPlayer = get_node("TileHitHardness" + str(tile.hardness))
	$TileHitPitch.pitch_scale = 0.8 + 0.4 * (1.0 - tile.health / tile.max_health)
	$TileHitPitch.play()
	soundPlayer.play()

	
	if has_node("TileHit" + tile.type.capitalize()):
		soundPlayer = get_node("TileHit" + tile.type.capitalize())
		soundPlayer.play()

	var knockback = Data.of("keeper1.acceleration") * Data.of("keeper1.tileKnockback")
	hitCooldown = Data.of("keeper1.tileHitCooldown")
	moveSlowdown = 0.25 + currentSpeed() * 0.01
	spriteLockDuration = hitCooldown
	var drillbuff = Data.of("keeper.drillBuff")
	if drillbuff > 0.0:
		$TileHitBuffed.play()
		hitCooldown *= 1.0 - drillbuff
		knockback *= 1.0 - drillbuff
		spriteLockDuration *= 1.0 - drillbuff
	if abs(dir.x) > abs(dir.y):
		move.x = sign(dir.x) * knockback
		move.y *= 0.1
	else:
		move.y = sign(dir.y) * knockback
		move.x *= 0.1

	DrillSprite.show()
	DrillSprite.frame = 0
	DrillSprite.play("drill" + animationSuffix)
	DrillSprite.rotation = DrillHitTestRay.rotation + PI

	var anim_name = ""
	if abs(move.x) > abs(move.y):
		anim_name = "drill_right" if move.x < 0 else "drill_left"
	else:
		anim_name = "down" if move.y < 0 else "up"

	$Sprite.play(anim_name + animationSuffix)
	
	var hits_needed_to_destroy: float = float(tile.max_health) / float(Data.of("keeper1.drillStrength"))
	emit_sparks(DrillHitTestRay.get_collision_point(), tile, hits_needed_to_destroy)
	emit_signal("tileHit")


onready var drill_hit = $DrillHit
func emit_sparks(hit_position: Vector2, tile: Node, hits_needed_to_destroy: float):
	var tile_type = tile.type
	drill_hit.position = to_local(hit_position) * 1.5
	drill_hit.rotation = DrillHitTestRay.rotation + PI
	drill_hit.frame = 0
	drill_hit.play("hit")
	var particle_amount = int(round(range_lerp(clamp(hits_needed_to_destroy, 1.0, 8.0), 1, 8, 60, 10)))
	$DrillHit / DrillHitParticles.amount = particle_amount
	$DrillHit / DrillHitParticles.restart()

	var spark_amount = int(round(range_lerp(clamp(hits_needed_to_destroy, 1.0, 8.0), 1, 8, 20, 3)))
	for _i in range(spark_amount + randi() % 3):
		var s = Data.KEEPER_SPARK.instance()
		s.global_position = hit_position
		s.apply_central_impulse(Vector2.RIGHT.rotated(drill_hit.rotation + rand_range( - 0.4, 0.4)) * rand_range(30, 150))
		get_parent().call_deferred("add_child", s)
	
	var dirt_color = Level.map.getBiomeColorByCoord(tile.coord)
	
	var dirt_amount = int(round(range_lerp(clamp(hits_needed_to_destroy, 1.0, 8.0), 1, 8, 5, 0)))
	for _i in range(dirt_amount + randi() % 2):
		var t = Data.TILE_DIRT_PARTICLE.instance()
		t.modulate = dirt_color
		t.type = tile_type
		t.global_position = hit_position
		t.apply_central_impulse(Vector2.RIGHT.rotated(drill_hit.rotation + rand_range( - 0.7, 0.7)) * rand_range(60, 130))
		get_parent().call_deferred("add_child", t)

func setJetpackStage(stage: int):
	$Trail.amount = 20 + stage * 8
	$Trail.initial_velocity = 12 + stage * 1

onready var thruster_l: ParticlesMaterial = $ThrusterLeft.process_material
onready var thruster_r: ParticlesMaterial = $ThrusterRight.process_material
onready var thruster_l_boost: AnimatedSprite = $ThrusterLeft / Booster
onready var thruster_r_boost: AnimatedSprite = $ThrusterRight / Booster
const THRUSTER_IDLE_DIR_L: Vector3 = Vector3( - 0.5, 1, 0)
const THRUSTER_IDLE_DIR_R: Vector3 = Vector3(0.5, 1, 0)
const THRUSTER_IDLE_VEL: float = 40.0

func control_thruster_vfx(_dir: Vector2, _is_moving: bool, delta: float)->void :
	var target_angle_l: Vector3
	var target_angle_r: Vector3
	var target_vel: float
	var lerp_speed: float
	if not _is_moving:
		thruster_l_boost.animation = "idle"
		thruster_r_boost.animation = "idle"
		lerp_speed = 7.0
		target_vel = THRUSTER_IDLE_VEL
		target_angle_l = THRUSTER_IDLE_DIR_L
		target_angle_r = THRUSTER_IDLE_DIR_R
	else:
		thruster_l_boost.animation = "boosting"
		thruster_r_boost.animation = "boosting"
		lerp_speed = 12.0
		target_angle_l = - Vector3(_dir.x, _dir.y, 0).normalized()
		target_angle_r = target_angle_l
		target_vel = _dir.length() + THRUSTER_IDLE_VEL
	thruster_l.direction = lerp(thruster_l.direction, target_angle_l, lerp_speed * delta).normalized()
	thruster_r.direction = lerp(thruster_r.direction, target_angle_r, lerp_speed * delta).normalized()
	thruster_l.initial_velocity = lerp(thruster_l.initial_velocity, target_vel, lerp_speed * delta)
	thruster_r.initial_velocity = lerp(thruster_r.initial_velocity, target_vel, lerp_speed * delta)

func disableEffects():
	$ThrusterLeft.emitting = false
	$ThrusterRight.emitting = false
	$ThrusterLeft / Booster.visible = false
	$ThrusterRight / Booster.visible = false
	$StillSound.stop()

func enableEffects():
	$ThrusterLeft.emitting = true
	$ThrusterRight.emitting = true
	$ThrusterLeft / Booster.visible = true
	$ThrusterRight / Booster.visible = true
	$StillSound.play()


func getCarrySlowdown()->float:
	return carrySlowdown
