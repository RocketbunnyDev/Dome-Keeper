extends Node2D

var move: Vector2

var inverse: = false
var skipFrame: = false
var inputReady: = false

var firing: = false
var hitState: = 0
var laser: Laser

var currentSpeed: = 0.0
var distanceMoved: = 0.0
var acceleration: = 0.0

var animation: String
var frame: = 0.0

var variant: = 0

var followLaser1
var pathProbe

const FRAME_SHOOT_START: = 24
const FRAME_MOVE_START: = 12
const FRAME_COUNT: = 3

const LASER_MAX_LENGTH = 600.0

onready var SpriteCannon = find_node("SpriteCannon")
onready var SpriteBack = find_node("SpriteBack")

var raycasts: Array

func _ready():
	Style.init(self)
	raycasts = [$RayCast2D, $RayCastL1, $RayCastR1, $RayCastR2, $RayCastL2, $RayCastL3, $RayCastR3]
	for r in raycasts:
		r.enabled = false
	$RayCast2D.enabled = true

func init(cupulaPath: Path2D):
	$AimLine.visible = false
	
	pathProbe = cupulaPath.createPathProbe(self)
	var otherLaser = null
	for c in get_parent().get_children():
		if c != self and c.is_in_group("primaryWeapon"):
			otherLaser = c
			break
	if otherLaser:
		pathProbe.unit_offset = 1.0 - otherLaser.pathProbe.unit_offset
		inverse = true
	
	Data.listen(self, "laser.variant", true)
	Data.listen(self, "laser.hitprojectiles", true)
	Data.listen(self, "laser.bend", true)
	setLaserVariant(Data.of("laser.variant"))
	
	Style.init(self)

func propertyChanged(property: String, oldValue, newValue):
	match property:
		
		"laser.variant":
			setLaserVariant(newValue)
		"laser.hitprojectiles":
			if newValue:
				$RayCast2D.set_collision_mask_bit(CONST.LAYER_MONSTER_PROJECTILES, true)
		"laser.bend":
			for r in raycasts:
				r.enabled = r.enabled or newValue

func setLaserVariant(variant: int):
	if laser:
		laser.queue_free()
	laser = load("res://content/weapons/laser/laser_variations/laser" + str(variant) + ".tscn").instance()
	$LaserStart.add_child(laser)
	laser.visible = false
	
	self.variant = variant
	match int(variant):
		0:
			$SpriteBase.texture = preload("res://content/weapons/laser/laserbase_small_sheet.png")
			SpriteBack.texture = preload("res://content/weapons/laser/laser_small_bottomextension.png")
			SpriteBack.position.y = 6
			$SpriteBase.position.y = - 5.5
		1:
			$SpriteBase.texture = preload("res://content/weapons/laser/laserbase_small_mid_sheet.png")
			SpriteBack.texture = preload("res://content/weapons/laser/laser_bottomextension.png")
			SpriteBack.position.y = 10
			$SpriteBase.position.y = - 6.5
		2:
			$SpriteBase.texture = preload("res://content/weapons/laser/laserbase_sheet.png")
			SpriteBack.texture = preload("res://content/weapons/laser/laser_bottomextension.png")
			SpriteBack.position.y = 10
			$SpriteBase.position.y = - 8.5
		3:
			$SpriteBase.texture = preload("res://content/weapons/laser/laserbase_big_sheet.png")
			SpriteBack.texture = preload("res://content/weapons/laser/laser_big_bottomextension.png")
			SpriteBack.position.y = 13
			$SpriteBase.position.y = - 12.5
	
	var c = $SpriteBase / SpriteCannon
	c.play(c.animation.substr(0, c.animation.find("_") + 1) + str(variant))

func move(dir: Vector2, allowMove: bool):
	if GameWorld.paused or not inputReady:
		return 
	
	if allowMove:
		move.x = dir.x

func action(fireValue: float, specialValue: float, allowShoot: bool):
	if GameWorld.paused or not inputReady:
		return 

	if fireValue > 0.0 and allowShoot:
		
		if not firing:
			skipFrame = not firing
			firing = true
			laser.start()
			laser.set_endpoint(Vector2.ZERO)
			if SpriteCannon.animation.begins_with("idle"):
				setFrame(FRAME_SHOOT_START + fmod(frame, FRAME_MOVE_START))
			SpriteCannon.play("shoot_" + str(variant))


	else:
		stopFiring()
		if SpriteCannon.animation.begins_with("shoot"):
			setFrame(FRAME_MOVE_START + fmod(frame, FRAME_SHOOT_START))
		SpriteCannon.play("idle_" + str(variant))

func _physics_process(delta):
	if GameWorld.paused or not inputReady:
		return 
	
	var laserMoveSpeed = Data.of("laser.movespeed") * Data.of("laser.movespeedmod")
	if move.x == 0:
		distanceMoved = 0
		$MoveSound.stop()
		currentSpeed = 0
		acceleration = 0

	else:

		if not $MoveSound.playing:
			$MoveSound.play()
		acceleration = clamp(acceleration + (10.0 - 13.0 * laserMoveSpeed) * delta, 0.0, 1.0)
	
	var goalSpeed = laserMoveSpeed * move.x
	
	if inverse:
		goalSpeed *= - 1
	if firing:
		goalSpeed *= Data.of("laser.movespeedwhilefiring")
	currentSpeed += (goalSpeed - currentSpeed) * delta * 8.0 * acceleration
	$MoveSound.pitch_scale = 0.45 + abs(currentSpeed) * 0.5
	var thisMove: float = pathProbe.moveBy(currentSpeed * delta)
	distanceMoved += abs(thisMove)
	
	if followLaser1:
		rotation = - followLaser1.rotation
	
	var c
	var collisionPoint: Vector2
	var laserEndPos: = Vector2(0, - 1) * LASER_MAX_LENGTH
	var angleDelta: = 0.0
	for raycast in raycasts:
		if not raycast.enabled:
			continue
		var c2 = raycast.get_collider()
		if c2:
			c = c2
			collisionPoint = raycast.get_collision_point()
			angleDelta = (collisionPoint - $RayCast2D.global_position).angle() - rotation + PI * 0.5
			if angleDelta > PI:
				angleDelta -= 2 * PI
			elif angleDelta < - PI:
				angleDelta += 2 * PI
			laserEndPos = Vector2(0, - 1) * ((collisionPoint - global_position).length() + 5)
			break
	
	if laser and Data.of("laser.aimLine"):
		$AimLine.visible = not firing
		if c and c.is_in_group("monster"):
			c.aim()
		$AimLine.set_point_position(1, laserEndPos)
	
	if firing:
		if c:
			if c.is_in_group("monster"):
				
				laser.rotation += (angleDelta - laser.rotation) * delta * 5.0
				laser.target(laserEndPos)
				laser.start_hit(laserEndPos)
				if c.currentHealth >= 5:
					laser.playHitBumpSound()
				var damage = Data.of("laser.dps") * Data.of("laser.dpsmod") * delta
				c.hit(damage, Data.of("laser.stun"))





				hitState = 1
			elif Data.of("laser.hitprojectiles") and c.is_in_group("projectile"):
				c.domeAbsorbsDamage()
		elif hitState >= 1:
			hitState -= 1
		elif hitState == 0:
			laser.rotation = 0
			hitState = - 1
			
			laser.stop_hit()
			$AimLine.set_point_position(1, Vector2(0, - 1) * LASER_MAX_LENGTH)
			laserEndPos = Vector2(0, - 1) * LASER_MAX_LENGTH
			laser.target(laserEndPos)
	
	if SpriteCannon.animation.begins_with("shoot_" + str(variant)):
			frame += thisMove * 3000.0 * delta
			if frame < FRAME_SHOOT_START:
				frame += FRAME_COUNT
			elif frame > FRAME_SHOOT_START + FRAME_COUNT:
				frame -= FRAME_COUNT
	elif SpriteCannon.animation.begins_with("idle_" + str(variant)):
			frame += thisMove * 3000.0 * delta
			if frame < FRAME_MOVE_START:
				frame += FRAME_COUNT
			elif frame > FRAME_MOVE_START + FRAME_COUNT:
				frame -= FRAME_COUNT
	$SpriteBase.frame = clamp(int(frame), 0, 41)
	
	if skipFrame:
		skipFrame = false
		return 
	
	
	if firing:
		laser.visible = true


func stopFiring():
	if firing:
		laser.stop()
		var end = (laser.get_endpoint() - laser.position).length()
		var amount = round(75 * (end / 300.0))
		if amount > 0:
			var particles = preload("res://content/weapons/laser/RayParticles.tscn").instance()
			particles.process_material.emission_box_extents.y = end * 0.5
			particles.position.y = - 0.5 * end
			particles.amount = amount
			add_child(particles)
		if Data.of("laser.aimLine"):
			$AimLine.visible = true
		hitState = 0
	firing = false

func start():
	if Data.of("laser.aimLine"):
		$AimLine.visible = true
	animation = "start"
	SpriteCannon.frame = 0
	SpriteCannon.play("start_" + str(variant))
	setFrame(FRAME_MOVE_START)

func stop():
	animation = "stop"
	if SpriteCannon.animation.begins_with("shoot"):
		SpriteCannon.play("stopped_" + str(variant))
	else:
		SpriteCannon.play("stop_" + str(variant))
	stopFiring()
	if Data.of("laser.aimLine"):
		$AimLine.visible = false
	setFrame(FRAME_MOVE_START)
	inputReady = false
	distanceMoved = 0
	$MoveSound.stop()
	laser.stop_hit()

func setFrame(f: float):
	frame = f
	$SpriteBase.frame = int(f)

func _on_SpriteCannon_animation_finished():
	if SpriteCannon.animation.begins_with("start"):
		SpriteCannon.play("idle_" + str(variant))
		inputReady = true
