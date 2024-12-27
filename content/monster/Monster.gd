extends Area2D

signal died

onready var IsHitSound: AudioStreamPlayer = find_node("IsHitSound")

export (String) var techId: = ""
var tier: int
var stunPriority: int
var size: String

var counter: int
var damageSource: String

var invulnerable: = false
var receiveDamage: = 0.0
var timeSinceLastShotAt: = 0.0
var goalStunIntensity: = 0.0
var stunIntensity: = 0.0
var fullStunAt: float
var headCount: = 1.0
var leaving: = false
var dead: = false
var hitSoundPlayed: = false

var damageSustainPerSecond: = 0.0
var damageSustainSeconds: = 0.0
var stunSustainSeconds: = 0.0

var currentHealth: float
var maxHealth: float
var currentStaggerDuration: float

var attackTween: Tween
var moveTween: Tween

var hitBoxes: = {}
var hittable: = true
var shouldUpdateHitbox: = true
var hitboxToDisable: = []
var hitboxToEnable: = []

var outline_frames = 0

var remainingFreeBlockers: = 2

var speedModifier: float
var damageModifier: float

var centerPosition: Vector2

func _ready():
	tier = Data.of(techId + ".tier")
	size = Data.of(techId + ".size")
	speedModifier = Data.ofOr("monstermodifiers.move_speed", 1.0)
	damageModifier = Data.ofOr("monstermodifiers.damage", 1.0)
	
	fullStunAt = Data.of(techId + ".fullStunThreshold")
	stunPriority = Data.of(techId + ".stunpriority")
	
	$Sprite.material = $Sprite.material.duplicate()
	$Sprite.material.set_shader_param("flash_rate", 0.0)
	$Sprite.material.set_shader_param("flash_magnitude", 0.0)
	
	if name.find("@") != - 1:
		damageSource = name.substr(1, name.find_last("@") - 1)
	else:
		damageSource = name
	currentHealth = Data.of(techId + ".health") * Data.ofOr("monstermodifiers.health", 1.0)
	maxHealth = currentHealth
	currentStaggerDuration = 0.0
	
	attackTween = Tween.new()
	add_child(attackTween)
	moveTween = Tween.new()
	add_child(moveTween)
	
	add_to_group("lostL")
	
	var regex = RegEx.new()
	regex.compile("\\D*")
	for c in get_children():
		if c.name.begins_with("Hitbox"):
			var m = regex.search(c.name.substr(6))
			var key = m.strings.front().to_lower()
			var arr = hitBoxes.get(key, [])
			arr.append(c)
			hitBoxes[key] = arr
		elif c.name.begins_with("DieSound"):
			c.connect("finished", self, "removeFreeBlocker")
	init()
	updateHitboxState()
	
	Style.init(self)

func init():
	pass

func setFlip(newFlip: bool, force: = false):
	if $Sprite.flip_h == newFlip and not force:
		return 
	
	$Sprite.flip_h = newFlip
	
	for c in get_children():
		if c is Node2D:
			c.position.x = - c.position.x
			c.rotation = - c.rotation
		if c is Sprite or c is AnimatedSprite:
			c.flip_h = newFlip
		if c is CollisionPolygon2D:
			for i in range(0, c.polygon.size()):
				c.polygon[i].x *= - 1

func animation(n: String):
	if n == $Sprite.animation:
		return 
	
	$Sprite.play(n)
	updateHitboxState()

func setHittable(do: bool):
	if hittable == do:
		return 
	hittable = do
	updateHitboxState()

func updateHitboxState():
	shouldUpdateHitbox = true
	if hittable:
		hitboxToDisable.clear()
		hitboxToEnable.clear()
		
		var goalHitbox: String = ""
		if hitBoxes.has($Sprite.animation):
			goalHitbox = $Sprite.animation
		elif hitBoxes.has("default"):
			goalHitbox = "default"
		
		for c in hitBoxes:
			if c == goalHitbox:
				for hb in hitBoxes[c]:
					centerPosition = hb.position
					if hb.disabled:
						hitboxToEnable.append(hb)
			else:
				for hb in hitBoxes[c]:
					if not hb.disabled:
						hitboxToDisable.append(hb)
	else:
		hitboxToEnable.clear()
		for c in hitBoxes:
			for hb in hitBoxes[c]:
				if not hb.disabled:
					hitboxToDisable.append(hb)

func _physics_process(delta):
	outline_frames -= 1
	if outline_frames == 0:
		$Sprite.material.set_shader_param("outline", false)
	
	if hitboxToEnable.size() > 0:
		for h in hitboxToEnable:
			hitboxToDisable.erase(h)
			h.disabled = false
		hitboxToEnable.clear()
	elif hitboxToDisable.size() > 0:
		for h in hitboxToDisable:
			h.disabled = true
		hitboxToDisable.clear()
	
	if dead:
		if remainingFreeBlockers <= 0:
			queue_free()
			
			remainingFreeBlockers = 9999
		return 
	
	if currentHealth <= 0 or GameWorld.paused:
		$Sprite.material.set_shader_param("flash_magnitude", 0.0)
		return 
	
	if leaving:
		leave(delta)
		$Sprite.material.set_shader_param("flash_magnitude", 0.0)
		return 
	
	if invulnerable:
		stunIntensity = 0.0
	
	if damageSustainSeconds > 0.0:
		damageSustainSeconds -= delta
		receiveDamage += delta * damageSustainPerSecond
	
	if stunIntensity >= fullStunAt:
		stunIntensity = fullStunAt
		
		$Sprite.speed_scale = 1.0
		$Sprite.material.set_shader_param("flash_rate", 0)
		$Sprite.material.set_shader_param("flash_magnitude", 0)
		moveTween.playback_speed = 1.0
	else:
		var sl = stunLevel()
		$Sprite.speed_scale = sl * speedModifier
		moveTween.playback_speed = sl * speedModifier
		$Sprite.material.set_shader_param("flash_rate", 2.0)
		$Sprite.material.set_shader_param("flash_magnitude", (0.8 - 0.8 * sl))
	stunIntensity += (goalStunIntensity - stunIntensity) * delta * 3.0
	
	var doSub: = true
	
	if stunSustainSeconds > 0.0:
		stunSustainSeconds -= delta
	else:
		if abs(goalStunIntensity) < 0.1:
			goalStunIntensity = 0.0
		else:
			goalStunIntensity *= (1.0 - delta * 10.0)
	
	if receiveDamage > 0:
		timeSinceLastShotAt = 0.0
		if invulnerable:
			receiveDamage = 0.0
			stunIntensity = 0.0
		else:
			currentHealth -= receiveDamage
			receiveDamage = 0
			if not hitSoundPlayed and IsHitSound:
				IsHitSound.play()
				hitSoundPlayed = true
			handleDamage()
			if currentHealth <= 0:
				die()
				animateDeath()
				return 
	else:
		timeSinceLastShotAt += delta
	
	if stunIntensity >= fullStunAt:
		currentStaggerDuration = 0.5
		attackTween.stop_all()
		moveTween.stop_all()
		doSub = false
	
	if currentStaggerDuration > 0:
		currentStaggerDuration -= delta
		if currentStaggerDuration <= 0:
			currentStaggerDuration = 0
			resumeAfterStagger()
			moveTween.resume_all()
			attackTween.resume_all()
		else:
			stagger()
			return 
	
	if doSub:
		subProcess(delta)

func die():
	if dead:
		return 
	$Sprite.speed_scale = 1.0
	emit_signal("died")
	moveTween.stop_all()
	moveTween.remove_all()
	attackTween.stop_all()
	attackTween.remove_all()
	hittable = false
	for c in hitBoxes:
			for hb in hitBoxes[c]:
				hb.disabled = true
	remove_from_group("monster")
	dead = true

func animateDeath():
	pass

func leave(delta: float):
	pass

func subProcess(delta: float):
	pass

func handleDamage():
	pass

func stagger():
	pass

func resumeAfterStagger():
	pass

func onGameLost():
	if currentHealth > 0:
		leaving = true
		$Sprite.speed_scale = 1.0

func alive()->bool:
	return currentHealth > 0.0

func aim(force: = false):
	if not hittable and not force:
		return 
	
	outline_frames = 2
	$Sprite.material.set_shader_param("outline", true)
	
func hit(damage: float, stun: float, immediateStun: = false):
	receiveDamage += damage
	goalStunIntensity = max(stun, goalStunIntensity)
	if immediateStun:
		stunIntensity = goalStunIntensity

func pause():
	moveTween.stop_all()
	attackTween.stop_all()
	$Sprite.stop()

func unpause():
	moveTween.resume_all()
	attackTween.resume_all()
	$Sprite.play()
	
func stunLevel()->float:
	return clamp(1.0 - stunIntensity / fullStunAt, 0.0, 1.0)

func removeFreeBlocker():
	remainingFreeBlockers -= 1

func domeReflectsDamage(returnedDamage: float = 0.0, returnedSpeed: float = 1.0, damageModifier: float = 2.0):
	if returnedDamage > 0:
		damageSustainSeconds = 0.6
		damageSustainPerSecond = returnedDamage / damageSustainSeconds

func domeAcceptsDamage():
	pass

func domeAbsorbsDamage():
	pass

func applyTemporarySpeedChange(change: float, time: float = 0.0):
	speedModifier *= change
	
	if time == 0.0:
		return 
	
	var t = Timer.new()
	add_child(t)
	t.connect("timeout", self, "applyTemporarySpeedChange", [(1.0 / change) if change != 0.0 else speedModifier])
	t.connect("timeout", t, "queue_free")
	t.start(time)

func sustainStun(stunLevel: float, time: float):
	hit(0, stunLevel, true)
	stunSustainSeconds = max(time, stunSustainSeconds)

func clearStun():
	goalStunIntensity = 0.0
	stunSustainSeconds = 0.0

func sustainDamage(dps: float, duration: float):
	if damageSustainSeconds > 0.0:
		var totalDamage = damageSustainSeconds * damageSustainPerSecond + dps * duration
		damageSustainSeconds = duration
		damageSustainPerSecond = totalDamage / duration
	else:
		damageSustainSeconds = duration
		damageSustainPerSecond = dps

var intervalTimer
func sustainIntervalDamage(damage, stun, interval, times, delay: = 0.0):
	if times == 0:
		intervalTimer.queue_free()
		intervalTimer = null
		return 
	
	if not intervalTimer:
		intervalTimer = Timer.new()
		intervalTimer.wait_time = interval + delay
		add_child(intervalTimer)
	else:
		intervalTimer.wait_time = interval
		intervalTimer.disconnect("timeout", self, "sustainIntervalDamage")
	
	intervalTimer.connect("timeout", self, "sustainIntervalDamage", [damage, stun, interval, times - 1])
	if delay == 0.0:
		hit(damage, stun, true)
	
	intervalTimer.start()

func getCenter()->Vector2:
	return centerPosition + global_position
