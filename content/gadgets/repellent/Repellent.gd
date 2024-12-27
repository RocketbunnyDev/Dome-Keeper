extends Node2D

enum Mode{NOTHING, HEALTH_REDUCTION, SLOWDOWN}
var mode: int = Mode.NOTHING

var shouldFocus: = false

var repellentReady: = false
var producing: = false
var grownAfter: = 0.0
var growFactor: = 1.0

var coolDown: = 0.0
var oldStage: = - 1
var emitting: = false

var battleAbilityActive: = false
var maxStage: int

var affectedMonsters: = {}
var particles

func _ready():
	maxStage = $Sprite.frames.get_frame_count("filling_" + Level.domeId())
	$Filling.modulate.a = 0.0
	$Cloud.play("empty")
	$Spinner.playing = false
	$FullScreenMist1Particles.emitting = false
	$FullScreenMist2Particles.emitting = false
	$Overcharge.visible = false
	
	match Level.domeId():
		"dome1":
			$Filling.position = Vector2(2, - 11)
			$Spinner.position = Vector2(2, - 24)
			$Cloud.position = Vector2( - 14, - 18)
			$Overcharge.position = Vector2(0, - 11)
		"dome2":
			$Filling.position = Vector2( - 7, - 18)
			$Spinner.position = Vector2( - 8, - 44)
			$Cloud.position = Vector2( - 16, - 39)
			$Overcharge.position = Vector2( - 10, - 17)
			position.x += 12
	updateFilling(0)
	
	Data.apply("repellent.currentgrowth", 0)
	Data.listen(self, "repellent.battlehealthReduction")
	Data.listen(self, "repellent.battleslowdown")
	Data.listen(self, "repellent.particles")
	Data.listen(self, "repellent.particlelifetime")
	Data.listen(self, "monsters.wavepresent")
	Data.apply("repellent.overchargedbattle", false)
	Data.apply("repellent.overchargedusage", false)
	Data.apply("repellent.remainingovercharged", 0.0)
	Data.apply("repellent.remainingbattleuses", 0)
	
	Style.init(self)
	
	Level.addTutorial(self, "repellent")
	
	Achievements.addIfOpen(self, "REPELLENT_BIGDELAY")

func serialize()->Dictionary:
	var data = {
		"mode": mode, 
		"shouldFocus": shouldFocus, 
		"repellentReady": repellentReady, 
		"producing": producing, 
		"grownAfter": grownAfter, 
		"growFactor": growFactor, 
		"coolDown": coolDown, 
		"oldStage": oldStage, 
		"emitting": emitting, 
		"maxStage": maxStage
	}
	data["meta.priority"] = 200
	data["meta.kind"] = "station"
	return data

func deserialize(data: Dictionary):
	mode = int(data["mode"])
	shouldFocus = data["shouldFocus"]
	repellentReady = data["repellentReady"]
	producing = data["producing"]
	grownAfter = data["grownAfter"]
	growFactor = data["growFactor"]
	coolDown = data["coolDown"]
	oldStage = data["oldStage"]
	emitting = data["emitting"]
	maxStage = data["maxStage"]

	yield (GameWorld, "savegame_loaded")

	if repellentReady:
		$BubbleParticles.emitting = true
		$Spinner.playing = false
		$Usable.updateFocus()
		$Filling.modulate.a = 1.0
	else:
		$Filling.modulate.a = 0.0
		$BubbleParticles.emitting = false
	
	if producing:
		$Sprite.frame = 0
		$Spinner.playing = true

	if emitting:
		$Sprite.frame = 0
		updateFilling(0)
		$Filling.modulate.a = 0.0
		for g in get_tree().get_nodes_in_group("effectL"):
			g.startEffect("screenGlitter")
	else:
		for g in get_tree().get_nodes_in_group("effectL"):
			g.stopEffect("screenGlitter")
	
	if Data.of("repellent.remainingovercharged") > 0:
		$Overcharge.visible = true
	else:
		$Overcharge.visible = false
	
	$Sprite.play("filling_" + Level.domeId())

func propertyChanged(property: String, oldValue, newValue):
	match property:
		
		"monsters.wavepresent":
			if newValue:
				Data.apply("repellent.remainingbattleuses", Data.of("repellent.battleuses"))
			else:
				Data.apply("repellent.overchargedbattle", false)
		"repellent.battlehealthreduction":
			if mode == Mode.NOTHING and newValue > 0:
				mode = Mode.HEALTH_REDUCTION
				add_to_group("battle1")
				$FullScreenMist1Particles.queue_free()
				Style.init($FullScreenMist2Particles)
				particles = $FullScreenMist2Particles
		"repellent.battleslowdown":
			if mode == Mode.NOTHING and newValue > 0:
				mode = Mode.SLOWDOWN
				add_to_group("battle1")
				$FullScreenMist2Particles.queue_free()
				Style.init($FullScreenMist1Particles)
				particles = $FullScreenMist1Particles
		"repellent.particles":
			if particles:
				pass
		"repellent.particlelifetime":
			if particles:
				pass

func _process(delta):
	if GameWorld.paused:
		return 
	
	if battleAbilityActive:
		match int(mode):
			Mode.HEALTH_REDUCTION:
				var tell = $AbilityTween.tell()
				var time = $AbilityTween.get_runtime() - tell
				var reduction = Data.of("repellent.battlehealthReduction")
				if tell <= 1.0:
					for m in get_tree().get_nodes_in_group("monster"):
						if not affectedMonsters.has(m):
							var stun = 0.99 * m.fullStunAt
							affectedMonsters[m] = 1
							m.hit(m.currentHealth * reduction, 0)
							m.sustainStun(stun, 0.5)
				else:
					var times = round(time)
					var damage = Data.of("repellent.battledamageovertime")
					if times > 0 and damage > 0:
						for m in get_tree().get_nodes_in_group("monster"):
							if affectedMonsters.get(m, 0) < 2:
								affectedMonsters[m] = 2
								var stun = 0.99 * m.fullStunAt
								m.sustainIntervalDamage(damage, stun, 1.0, times, 0.25 + randf())
			Mode.SLOWDOWN:
				var time = $AbilityTween.get_runtime() - $AbilityTween.tell()
				var stun = Data.of("repellent.battleslowdown")
				for m in get_tree().get_nodes_in_group("monster"):
					if not affectedMonsters.has(m):
						affectedMonsters[m] = 0
						m.sustainStun(stun * Data.of(m.techId + ".fullStunThreshold"), time)
						
	if GameWorld.softPaused():
		return 
	
	if GameWorld.waveDelay > 0.0:
		return 
	elif emitting:
		emitting = false
		$RepellentActiveSound.stop()
		for g in get_tree().get_nodes_in_group("effectL"):
			g.stopEffect("screenGlitter")
		return 
	
	if not repellentReady:
		if producing and GameWorld.runStarted:
			var d: float = delta
			var overchargeTime = Data.of("repellent.remainingovercharged")
			if overchargeTime >= 0.0:
				d *= 2
				overchargeTime -= delta
				Data.apply("repellent.remainingovercharged", overchargeTime)
				if overchargeTime <= 0.0:
					$Overcharge.visible = false
			var repellentGrowth = Data.of("repellent.currentgrowth") + d / grownAfter
			Data.apply("repellent.currentgrowth", repellentGrowth)
			if repellentGrowth >= 1.0:
				finishProduction()
				$RepellentReadySound.play()
				$RepellentCharging.stop()
			else:
				updateFilling(repellentGrowth)
		else:
			$RepellentCharging.play()
			producing = true
			grownAfter = GameWorld.getTimeBetweenWaves() * float(Data.of("repellent.growthTime"))
			$Sprite.play("filling_" + Level.domeId())
			$Sprite.frame = 0
			updateFilling(0)
			$Spinner.playing = true

func updateFilling(growth: float):
	var frame = clamp(floor((maxStage) * growth), 0, maxStage)
	$Sprite.frame = int(frame)

func finishProduction():
	producing = false
	repellentReady = true
	$Usable.updateFocus()
	$Tween.interpolate_property($Filling, "modulate:a", 0.0, 1.0, 1.0, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	$Tween.start()
	$BubbleParticles.emitting = true
	$Spinner.playing = false

func executeBattle1()->bool:
	if mode == Mode.NOTHING:
		return false
	
	if battleAbilityActive:
		return false
	
	var remainingUses = Data.of("repellent.remainingbattleuses")
	if remainingUses <= 0:
		Audio.sound("gui_err")
		return false
	Data.apply("repellent.remainingbattleuses", remainingUses - 1)
	
	var duration = getBattleAbilityDuration()
	
	battleAbilityActive = true
	match int(mode):
		Mode.HEALTH_REDUCTION:
			$WitherSound.play()
		Mode.SLOWDOWN:
			$DebilitateSound.play()
	
	$AbilityTween.interpolate_callback(self, duration, "deactivate")
	$AbilityTween.start()
	
	particles.emitting = true
	$Cloud.play("spray")
	
	Backend.event("battle_ability_used", {"gadget": "repellent", "ability": Mode.keys()[mode]})
	return true

func deactivate():
	battleAbilityActive = false
	affectedMonsters.clear()
	particles.emitting = false
	match int(mode):
		Mode.HEALTH_REDUCTION:
			pass
		Mode.SLOWDOWN:
			pass

func getBattleAbilityName()->String:
	match int(mode):
		Mode.HEALTH_REDUCTION:
			return tr("upgrades.repellentbattlehealthreduction.title")
		Mode.SLOWDOWN:
			return tr("upgrades.repellentbattleslowdown.title")
	return ""

func getBattleAbilityDuration()->float:
	var duration = Data.of("repellent.battleabilityduration")
	if Data.of("repellent.overchargedbattle"):
		duration += duration * Data.of("repellent.overchargebattleabilityduration")
	return duration

func canFocusUse()->bool:
	if Data.of("monsters.wavepresent"):
		return false
	if repellentReady:
		return true
	if canOvercharge():
		return true
	return false

func useHold(keeper: Keeper):
	useHit(keeper)

func useHit(keeper: Keeper)->bool:
	if repellentReady:
		$ReleaseSound.play()
		repellentReady = false
		$Tween.stop_all()
		$Tween.remove_all()
		$Filling.modulate.a = 0.0
		Data.apply("repellent.currentgrowth", 0.0)
		$BubbleParticles.emitting = false
	
		var delay: float = Data.of("repellent.wavedelay")
		if Data.of("repellent.overchargedusage"):
			delay += Data.of("repellent.overchargewavedelay")
			Data.apply("repellent.overchargedusage", false)
		Data.changeByInt("repellent.delayedcycles", delay)
		GameWorld.waveDelay += delay * GameWorld.getTimeBetweenWaves()
		
		for g in get_tree().get_nodes_in_group("effectL"):
			$Tween.interpolate_callback(g, 2.0, "startEffect", "screenGlitter")
		$Tween.start()
		emitting = true
		$Sprite.play("spray_" + Level.domeId())
		$Cloud.play("spray")
		
		$RepellentActiveSound.play()
		
		Backend.event("gadget_used", {"gadget": "repellent"})
		return true
	else:
		if Data.of("inventory.water") <= 0:
			$NoOverchargeSound.play()
			return false
		else:
			overcharge()
			return true

func overcharge():
	$OverchargeSound.play()
	Data.apply("repellent.remainingovercharged", GameWorld.getTimeBetweenWaves() * Data.of("repellent.overchargeDuration"))
	$Overcharge.visible = true
	Data.apply("repellent.overchargedbattle", true)
	Data.apply("repellent.overchargedusage", true)
	
	Data.changeByInt("inventory.water", - 1)
	Backend.event("gadget_overcharged", {"gadget": "repellent"})
	
func canOvercharge()->bool:
	return Data.of("repellent.overchargeDuration") > 0.0 and Data.of("repellent.remainingovercharged") <= 0.0

func _on_Cloud_animation_finished():
	$Cloud.play("empty")

func pauseChanged():
	if GameWorld.paused:
		$Tween.stop_all()
		$AbilityTween.stop_all()
	else:
		$Tween.resume_all()
		$AbilityTween.resume_all()
