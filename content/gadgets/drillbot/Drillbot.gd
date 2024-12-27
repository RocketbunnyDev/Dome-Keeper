extends Carryable

enum State{WORKING, FALLING, SLEEPING, CARRIED, LANDING}
var state: int = State.SLEEPING

var cooldown: = 0.0
var hitCooldown: = 0.0
var direction: Vector2 = Vector2.LEFT
var stableTime: = 0.0
var stuckTime: = 0.0
var sparkCooldown: = - 1.0
var remainingSleepTime: = 0.0
var wasGoingDown: = false
var currentDrillSound

var remainingHits: = 0
var remainingBuffedHits: = 0
var speed: = 1.0

var station

const FootstepDust = preload("res://content/gadgets/drillbot/FootstepDust.tscn")

func _ready():
	animation("sleep")
	setDirection(Vector2.LEFT)
	
	var drillbots = get_tree().get_nodes_in_group("drillbots")
	if drillbots.size() > 1:
		$Sprite.frames = preload("res://content/gadgets/drillbot/frames2.tres")
	else:
		$Sprite.frames = preload("res://content/gadgets/drillbot/frames1.tres")
	
	Data.listen(self, "monsters.wavepresent")
	Data.listen(self, "drillbot.drilllevel", true)
	Data.listen(self, "drillbot.amount", true)
	Style.init(self)
	
	Level.addTutorial(self, "drillbothandling")
	Level.addTutorial(self, "drillbotsleeping")
	
	Achievements.addIfOpen(self, "DRILLBERT_TREATS")

func serialize()->Dictionary:
	var data = .serialize()
	data["state"] = state
	data["cooldown"] = cooldown
	data["hitCooldown"] = hitCooldown
	data["direction"] = var2str(direction)
	data["stableTime"] = stableTime
	data["stuckTime"] = stuckTime
	data["remainingSleepTime"] = remainingSleepTime
	data["wasGoingDown"] = wasGoingDown
	data["remainingHits"] = remainingHits
	data["remainingBuffedHits"] = remainingBuffedHits
	data["speed"] = speed
	return data
	
func deserialize(data: Dictionary):
	.deserialize(data)
	cooldown = data["cooldown"]
	hitCooldown = data["hitCooldown"]
	stableTime = data["stableTime"]
	stuckTime = data["stuckTime"]
	remainingSleepTime = data["remainingSleepTime"]
	wasGoingDown = data["wasGoingDown"]
	speed = data["speed"]

	setState(int(data["state"]))
	setDirection(str2var(data["direction"]))
	
	if state == State.WORKING:
		normalMode()
		startWorking()
	if state == State.FALLING:
		normalMode()
		startFalling()
	if state == State.SLEEPING:
		normalMode()
	if state == State.CARRIED:
		onCarried(carriedBy[0])
	if state == State.LANDING:
		pass

	yield (GameWorld, "savegame_loaded")
	
	remainingHits = data["remainingHits"]
	remainingBuffedHits = data["remainingBuffedHits"]

func propertyChanged(property: String, oldValue, newValue):
	match property:
		
		"drillbot.drilllevel":
			match int(newValue):
				0: currentDrillSound = $DrillSound0
				1: currentDrillSound = $DrillSound1
				2: currentDrillSound = $DrillSound2
				3: currentDrillSound = $DrillSound3
				4: currentDrillSound = $DrillSound4
				_: currentDrillSound = $DrillSound0
		"monsters.wavepresent":
			if not newValue and remainingSleepTime <= 0.0 and carriedBy.size() == 0:
				wakeUp()
		"drillbot.amount":
			if oldValue:
				remainingHits = remainingHits + (newValue - oldValue)
			else:
				remainingHits += newValue

func _physics_process(delta):
	if isCarried():
		rotateUpright()
		return 
	
	var plane = abs(fmod(rotation, PI)) <= 0.1 and abs(linear_velocity.y) < 4.0
	if not plane:
		if not state == State.FALLING:
			if stableTime > 0.0:
				stableTime = 0.0
			stableTime -= delta
			if stableTime < - 0.3:
				startFalling()
	else:
		stableTime += delta
	
	if cooldown > 0.0:
		cooldown -= delta
		return 
	
	if GameWorld.softPaused():
		if state == State.WORKING:
			if Data.of("monsters.wavepresent"):
				goToSleep(false)
			return 
	
	$DrillHitTestRay.enabled = true
	match int(state):
		State.WORKING:
			rotateUpright()
			if linear_velocity.y > 2.0 and stableTime <= - 0.3:
				startFalling()
				return 
			
			if hitCooldown > 0.0:
				hitCooldown -= delta
				if sparkCooldown > 0.0:
					sparkCooldown -= delta
				if sparkCooldown <= 0.0 and sparkCooldown > - 1:
					for _i in range(1):
						var s = Data.KEEPER_SPARK.instance()
						if $DefaultCollisionShape3.disabled:
							s.global_position = $DrillHitTestRay.get_collision_point()
						else:
							s.global_position = $DrillPoint.global_position
						s.apply_central_impulse(Vector2.LEFT.rotated($DrillHitTestRay.rotation + rand_range( - 0.5, 0.5)) * rand_range(30, 150))
						get_parent().call_deferred("add_child", s)
					sparkCooldown = 0.03 * (1.0 / speed)
				return 
			var collider = $DrillHitTestRay.get_collider()
			if not collider:
				apply_central_impulse(direction * 2.0 * speed)
				animation("walk")
				$Sprite.speed_scale = linear_velocity.length() / 50.0
				stuckTime = 0.0
				if $DefaultCollisionShape3.disabled:
					$DefaultCollisionShape3.disabled = false
				return 
			elif not collider.has_meta("destructable") or not collider.get_meta("destructable"):
				animation("idle")
				stuckTime += delta
				if stuckTime > 1.0:
					if Data.of("drillbot.turnaround"):
						setDirection(direction * Vector2.LEFT)
					else:
						goToSleep()
			else:
				if sparkCooldown == - 1:
					sparkCooldown = 0
				apply_impulse(Vector2(0, 0), - linear_velocity * 0.5)
				var dir = global_position - collider.global_position
				collider.hit(dir, Data.of("drillbot.drillstrength"))
				animation("drill")
				currentDrillSound.play()
				if remainingBuffedHits > 0:
					remainingBuffedHits -= 1
					hitCooldown = 0.2 * (1.0 / speed)
				elif remainingHits > 0:
					remainingHits -= 1
					hitCooldown = 0.2
				else:
					goToSleep()
		State.FALLING:
			wasGoingDown = wasGoingDown or linear_velocity.y > 2.0
			if abs(linear_velocity.x) > 4.0:
				if linear_velocity.x < 0:
					setDirection(Vector2.LEFT)
				else:
					setDirection(Vector2.RIGHT)
			rotateUpright()
			if stableTime > 0.1 and wasGoingDown:
				animation("land")
				$LandSound.play()
				setState(State.LANDING)
			elif stableTime > 1.0:
				startWorking()
		State.SLEEPING:
			if Data.of("monsters.wavepresent"):
				return 
			
			remainingSleepTime -= delta
			if remainingSleepTime <= 0.0:
				remainingHits = max(remainingHits, Data.of("drillbot.amount"))
				wakeUp()
			if linear_velocity.length() > 2.0:
				startFalling()
		State.LANDING:
			rotateUpright()
			if stableTime > 3.0:
				startWorking()

func rotateUpright():
	apply_torque_impulse( - rotation * 5.0)

func startFalling():
	if $SleepingSound.playing:
		$SleepingSound.stop()
	$FallingScreamSound.play()
	wasGoingDown = false
	setState(State.FALLING)
	stableTime = 0.0
	animation("knockback")
	$DefaultCollisionShape3.disabled = true

func animation(ani: String):
	$Sprite.speed_scale = 1.0 * speed
	$Sprite.play(ani)

func startWorking():
	animation("idle")
	cooldown = 1.0
	setState(State.WORKING)

func isWorking():
	return state == State.WORKING

func isCarried():
	return state == State.CARRIED

func canFocusUse()->bool:
	return not isCarried() and not state == State.FALLING

func useHold(keeper: Keeper):
	return false

func useHit(keeper: Keeper)->bool:
	if state == State.SLEEPING:
		wakeUp()
		Backend.event("gadget_used", {"gadget": "drillbot", "activity": "woken"})
	else:
		animation("idle")
		sparkCooldown = - 1
		setDirection(direction * Vector2.LEFT)
		$ChangeDirectionSound.play()
		Backend.event("gadget_used", {"gadget": "drillbot", "activity": "switched"})
	remainingHits = Data.of("drillbot.amount")
	return true

func setDirection(dir: Vector2):
	if dir == direction:
		return 
	
	direction = dir
	$Sprite.flip_h = dir == Vector2.RIGHT
	$DrillHitTestRay.rotation = direction.angle()
	$DrillHitTestRay.position.x *= - 1
	$DrillPoint.position.x *= - 1
	$Sprite.position.x *= - 1
	$DefaultCollisionShape1.position.x *= - 1
	$DefaultCollisionShape2.position.x *= - 1
	$DefaultCollisionShape3.position.x *= - 1
	$DefaultCollisionShape4.position.x *= - 1
	$CarriedCollisionShape.position.x *= - 1
	$FocusSprite.position.x *= - 1
	$CarrySprite.position.x *= - 1

func onCarried(p: Keeper):
	animation("carried")
	$DefaultCollisionShape1.disabled = true
	$DefaultCollisionShape2.disabled = true
	$DefaultCollisionShape3.disabled = true
	$DefaultCollisionShape4.disabled = true
	$CarriedCollisionShape.disabled = false
	setState(State.CARRIED)
	if $SleepingSound.playing:
		$SleepingSound.stop()
	remainingHits = Data.of("drillbot.amount")
	Backend.event("gadget_used", {"gadget": "drillbot", "activity": "pickup"})

func onDropped(p: Keeper):
	animation("knockback")
	normalMode()
	startFalling()
	Backend.event("gadget_used", {"gadget": "drillbot", "activity": "drop"})

func normalMode():
	$DefaultCollisionShape1.disabled = false
	$DefaultCollisionShape2.disabled = false
	$DefaultCollisionShape4.disabled = false
	$CarriedCollisionShape.disabled = true

func goToSleep(setSleepTime: = true):
	setState(State.SLEEPING)
	normalMode()
	animation("liedown")
	if setSleepTime:
		remainingSleepTime = Data.of("drillbot.sleeptime") * GameWorld.getTimeBetweenWaves()

func wakeUp():
	animation("getup")
	$SleepingSound.stop()
	$WakeupSound.play()
	remainingSleepTime = 0.0

func _on_Sprite_animation_finished():
	match $Sprite.animation:
		"getup":
			startWorking()
		"liedown":
			animation("sleep")
		"land":
			startWorking()

func setState(to):
	match int(state):
		State.FALLING:
			$FallingScreamSound.stop()
	state = to

func dropEntered(drop):
	if not drop.absorbed:
		drop.shred()

func dropExited(drop):
	pass

func dropTarget()->Vector2:
	return global_position

func _on_TreatArea_treat_eaten():
	if state == State.SLEEPING:
		wakeUp()
	remainingHits = Data.of("drillbot.amount") + Data.of("drillbot.buffextraamount")
	remainingBuffedHits = Data.of("drillbot.buffamount")
	speed = Data.of("drillbot.buffstrength")
	$TreatEatenSound.play()
	Backend.event("gadget_used", {"gadget": "drillbot", "activity": "treated"})

func _on_Sprite_frame_changed():
	if $Sprite.animation == "sleep" and $Sprite.frame == 14:
		$SleepingSound.play()
	elif $Sprite.animation == "walk" and $Sprite.frame % 2 == 0:
		var d = FootstepDust.instance()
		Level.stage.add_child(d)
		d.global_position = global_position
		d.flip_h = $Sprite.flip_h
		$StepSound.play()


func getRemainingSleepTime()->float:
	return remainingSleepTime
