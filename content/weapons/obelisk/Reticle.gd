extends Node2D


export  var maxSpeed = 0.0
export  var acceleration = 1.9
export  var friction = 9.0
var motion = Vector2.ZERO
var input = Vector2.ZERO
var last_input = Vector2.ZERO
var speed_mod: = 1.0

var minSpread = 0.0
var maxSpread = 0.0
var spreadUpSpeed = 0.0
var spreadDownSpeed = 0.0
onready var segments = [$CrosshairContainer / ReticleR, $CrosshairContainer / ReticleD, $CrosshairContainer / ReticleL, $CrosshairContainer / ReticleU]
onready var dirs = [Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT, Vector2.UP]
var last_spread: = 0.0
var cur_spread: = 0.0
var monsterDetectionHighlightsCrosshairs: = true
var shooting_spread = 0.0
var last_shooting_spread = 0.0

var slowdownOverMonsters: = 1.0
var detectionRadius = 0
var hoveredMonsters: = []
var detectedMonsters: = []
var monsterSlowdownBridgeTime: = 0.0
var cur_bridgeTime: = 0.0

var follow_reticle_target: = false
var cur_reticle_target: ReticleTarget = null
var is_active: = false
var near_target_slowdown_increase = 0.1
var cur_near_target_slowdown = 0

const HIT_MARKER = preload("res://content/weapons/obelisk/HitMarker.tscn")
const KILL_MARKER = preload("res://content/weapons/obelisk/KillMarker.tscn")

func init():


	
	
	Data.listen(self, "obelisk.maxReticleSpeed", true)
	Data.listen(self, "obelisk.minReticleSpread", true)
	Data.listen(self, "obelisk.maxReticleSpread", true)
	Data.listen(self, "obelisk.spreadUpSpeed", true)
	Data.listen(self, "obelisk.spreadDownSpeed", true)
	Data.listen(self, "obelisk.slowdownOverMonsters", true)
	Data.listen(self, "obelisk.monsterSlowdownBridgeTime", true)
	Data.listen(self, "obelisk.detectionRadius", true)
	
	minSpread = Data.of("obelisk.minReticleSpread")
	maxSpread = Data.of("obelisk.maxReticleSpread")
	maxSpeed = Data.of("obelisk.maxReticleSpeed")
	spreadUpSpeed = Data.of("obelisk.spreadUpSpeed")
	spreadDownSpeed = Data.of("obelisk.spreadDownSpeed")
	slowdownOverMonsters = Data.of("obelisk.slowdownOverMonsters")
	monsterSlowdownBridgeTime = Data.of("obelisk.monsterSlowdownBridgeTime")
	detectionRadius = Data.of("obelisk.detectionRadius")
	
	Style.init(self)


func propertyChanged(property: String, oldValue, newValue):
	match property:
		
		"obelisk.maxreticlespeed":
			maxSpeed = newValue
			print(newValue)
		"obelisk.minreticlespread":
			minSpread = newValue
		"obelisk.maxreticlespread":
			maxSpread = newValue
		"obelisk.spreadupspeed":
			spreadUpSpeed = newValue
		"obelisk.spreaddownspeed":
			spreadDownSpeed = newValue
		"obelisk.slowdownovermonsters":
			slowdownOverMonsters = newValue
		"obelisk.monsterslowdownbridgetime":
			monsterSlowdownBridgeTime = newValue
		"obelisk.detectionradius":
			detectionRadius = newValue


func _physics_process(delta: float)->void :
	if not is_active:
		return 
	if follow_reticle_target:
		if is_instance_valid(cur_reticle_target):
			var target_pos = cur_reticle_target.global_position
			var dist_to_target = target_pos.distance_to(global_position)
			input = (target_pos - global_position).normalized() * delta * dist_to_target
	else:
		
		var x1 = 465 * 2
		var y1 = 455 * 2
		if input.x < 0:
			if global_position.x <= - (x1 / GameWorld.goalCameraZoom):
				input.x = 0
		elif input.x > 0:
			if global_position.x >= (x1 / GameWorld.goalCameraZoom):
				input.x = 0
		if input.y < 0:
			if global_position.y <= - (y1 / GameWorld.goalCameraZoom):
				input.y = 0
		elif input.y > 0:
			if global_position.y >= 0:
				input.y = 0
	
	
	if last_input.x != 0 and input.x == 0:
		var counter = Vector2(last_input.x, 0)
		apply_friction(friction * 0.7, counter)
	elif last_input.y != 0 and input.y == 0:
		var counter = Vector2(0, last_input.y)
		apply_friction(friction * 0.7, counter)
	if input == Vector2.ZERO:
		
		apply_friction(friction)
	else:
		apply_movement(input.normalized() * acceleration, speed_mod)
	
	
	if hoveredMonsters.size() > 0 or cur_bridgeTime > 0.0:
		motion *= slowdownOverMonsters
	
	position += motion
	apply_spread(((maxSpread - minSpread) * motion.length()) / maxSpeed + minSpread)
	
	last_input = input

func move(dir: Vector2, speed_mod: float):
	input = dir
	self.speed_mod = speed_mod

func _process(delta: float)->void :
	if GameWorld.paused or not is_active:
		return 
	
	if cur_bridgeTime < monsterSlowdownBridgeTime and cur_bridgeTime > 0.0:
		cur_bridgeTime += delta
	
	elif cur_bridgeTime >= monsterSlowdownBridgeTime and hoveredMonsters.size() == 0:
		cur_bridgeTime = 0.0
	
	
	if detectedMonsters.size() > 0 and monsterDetectionHighlightsCrosshairs:
		
		for ch in $CrosshairContainer.get_children():
			ch.texture = load("res://content/weapons/obelisk/crosshairs0_hover.png")
	else:
		for ch in $CrosshairContainer.get_children():
			ch.texture = load("res://content/weapons/obelisk/crosshairs0_no.png")
	
	$MonsterDetection / CollisionShape2D.shape.radius = min(cur_spread, detectionRadius)

func apply_friction(amount, direction: = Vector2.ZERO):
	if direction == Vector2.ZERO:
		if motion.length() > amount:
			motion -= motion.normalized() * amount
		else:
			motion = Vector2.ZERO
	else:
		if motion.length() > direction.length():
			motion -= direction * amount
		else:
			motion = Vector2.ZERO

func apply_movement(acceleration_vec, speed_mod):
	motion += acceleration_vec
	
	var limit = maxSpeed * speed_mod
	
	if input.length() < 1.0:
		limit *= input.length()
	
	motion = motion.clamped(limit)

func apply_spread(spread: float, useLerp: bool = true):
	var expand = last_spread < spread
	var lerp_strength = spreadUpSpeed if expand else spreadDownSpeed
	spread += shooting_spread
	for i in range(4):
		
		if (last_shooting_spread == 0 and shooting_spread > 0):
			var s = segments[i]
			s.position = dirs[i] * spread
		
		else:
			if useLerp:
				var s = segments[i]
				var spread_lerp = lerp(s.position, spread * dirs[i], lerp_strength)
				s.position = spread_lerp
				cur_spread = spread_lerp.length()
			else:
				var s = segments[i]
				s.position = dirs[i] * minSpread
			
	$SpreadArea / CollisionShape2D.shape.radius = cur_spread
	last_spread = spread
	last_shooting_spread = shooting_spread

func apply_shoot_delay(progress: float):
	var segment_count = segments.size()
	var seg_index = 1
	for cs in segments:
		if float(seg_index) / float(segment_count) < progress or progress >= 1.0:
			cs.scale = Vector2(1.0, 1.0)
		else:
			
			cs.scale = Vector2(0.6, 0.6)
		seg_index += 1

func _on_SpreadArea_area_entered(area: Area2D)->void :
	if area.is_in_group("monster"):
		addDetectedMonsters(area)

func _on_SpreadArea_area_exited(area: Area2D)->void :
	if area.is_in_group("monster"):
		removeDetectedMonsters(area)


func addDetectedMonsters(m):
	if not detectedMonsters.has(m):
		if detectedMonsters.size() == 0:
			$EnterFirstSFX.stop()
			$EnterFirstSFX.play(0.0)
		elif not detectedMonsters.has(m):
			$EnterSFX.stop()
			$EnterSFX.play(0.0)

		detectedMonsters.append(m)
		if not m.is_connected("died", self, "removeDetectedMonsters"):
			m.connect("died", self, "removeDetectedMonsters", [m])

func removeDetectedMonsters(m):
	if detectedMonsters.has(m):
		if detectedMonsters.size() == 1:
			$LeaveLastSFX.stop()
			$LeaveLastSFX.play(0.0)
		elif detectedMonsters.has(m):
			$LeaveSFX.stop()
			$LeaveSFX.play(0.0)
		detectedMonsters.erase(m)
		m.disconnect("died", self, "removeDetectedMonsters")

func addHoveredMonsters(m):
	if not hoveredMonsters.has(m):
		hoveredMonsters.append(m)
		if not m.is_connected("died", self, "removeHoveredMonsters"):
			m.connect("died", self, "removeHoveredMonsters", [m])

func removeHoveredMonsters(m):
	if hoveredMonsters.has(m):
		hoveredMonsters.erase(m)
		m.disconnect("died", self, "removeHoveredMonsters")
		if hoveredMonsters.size() == 0:
			cur_bridgeTime = 0.01


func _on_MonsterDetection_area_entered(area: Area2D)->void :
	if area.is_in_group("monster"):
		addHoveredMonsters(area)


func _on_MonsterDetection_area_exited(area: Area2D)->void :
	if area.is_in_group("monster"):
		removeHoveredMonsters(area)


func hit_marker():
	var hm = HIT_MARKER.instance()
	Level.stage.add_child(hm)
	hm.init()
	hm.global_position = global_position
	hm.z_index = 350
	var s = Data.of("obelisk.radius") / 20.0
	hm.scale = Vector2(s, s)

func kill_marker():
	var hm = KILL_MARKER.instance()
	Level.stage.add_child(hm)
	hm.init()
	hm.global_position = global_position
	hm.z_index = 350
	var s = Data.of("obelisk.radius") / 22.0
	hm.scale = Vector2(s, s)


