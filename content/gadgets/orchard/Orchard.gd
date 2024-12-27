extends Node2D

enum Mode{NOTHING, ROOTS, SHIELD}
var mode: int = Mode.NOTHING

var battleAbilityActive: = false

var plantReady: = false
var producing: = false
var grownAfter: float
var addedSpeedBuff: float
var addedDrillBuff: float

const FRUIT_OFFSETS: = {
	"dome1": Vector2(10, 8), 
	"dome2": Vector2(4, - 5), 
	"dome3": Vector2(), 
}

func _ready():
	$Sprite / Fruit.visible = false
	$Sprite.play("empty_" + Level.domeId())
	Data.apply("orchard.currentgrowth", 0)
	
	Data.listen(self, "monsters.wavepresent")
	Data.listen(self, "orchard.battleshields")
	Data.listen(self, "orchard.battleroots")
	Data.apply("orchard.remainingbattleuses", 0)
	Data.apply("orchard.overchargedbuff", false)
	Data.apply("orchard.overchargedbattle", false)
	Data.apply("orchard.remainingovercharged", 0.0)
	Data.apply("orchard.remainingbattleuses", 0)
	Data.apply("orchard.remainingbuffduration", 0)
	Data.apply("orchard.buffed", false)
	
	Style.init(self)
	
	Level.addTutorial(self, "orchard")
	
	Achievements.addIfOpen(self, "ORCHARD_LONG")

func serialize()->Dictionary:
	var data = {
		"mode": mode, 
		"battleAbilityActive": battleAbilityActive, 
		"plantReady": plantReady, 
		"producing": producing, 
		"grownAfter": grownAfter, 
		"addedSpeedBuff": addedSpeedBuff, 
		"addedDrillBuff": addedDrillBuff, 
	}
	data["meta.priority"] = 200
	data["meta.kind"] = "station"
	return data
	
func deserialize(data: Dictionary):
	mode = data["mode"]
	battleAbilityActive = data["battleAbilityActive"]
	plantReady = data["plantReady"]
	producing = data["producing"]
	grownAfter = data["grownAfter"]
	addedSpeedBuff = data["addedSpeedBuff"]
	addedDrillBuff = data["addedDrillBuff"]
	
	if producing:
		$Sprite.play("growing_" + Level.domeId())
		$Center / OrchardActive.play()
		
	if plantReady:
		createFruit()
	
func propertyChanged(property: String, oldValue, newValue):
	match property:
		
		"monsters.wavepresent":
			if newValue:
				var uses = Data.of("orchard.battleabilityuses")
				if Data.of("orchard.overchargedbattle"):
					uses += Data.of("orchard.overchargeadditionalabilityUses")
					Data.apply("orchard.overchargedbattle", false)
				Data.apply("orchard.remainingbattleuses", uses)
			else:
				var delay: = 0.0
				for root in get_tree().get_nodes_in_group("orchard-root"):
					root.dissolve(delay)
					delay += 0.15 + randf() * 0.1
				for shield in get_tree().get_nodes_in_group("orchard-shield"):
					shield.dissolve(delay)
					delay += 0.15 + randf() * 0.1
		"orchard.battleshields":
			if mode == Mode.NOTHING and newValue > 0:
				mode = Mode.SHIELD
				add_to_group("battle1")
				$RootingSound.queue_free()
		"orchard.battleroots":
			if mode == Mode.NOTHING and newValue > 0:
				mode = Mode.ROOTS
				add_to_group("battle1")
				$ShieldSound.queue_free()

func _process(delta):
	if GameWorld.softPaused():
		return 
	
	var remainingBuffDuration = Data.of("orchard.remainingbuffduration")
	if remainingBuffDuration > 0.0:
		var moveLength = Level.keeper.moveDirectionInput.length()
		if moveLength > 0.0:
			remainingBuffDuration -= delta * moveLength
			Data.apply("orchard.remainingbuffduration", remainingBuffDuration)
			if remainingBuffDuration <= 0:
				Data.changeByInt("keeper.speedBuff", - addedSpeedBuff)
				Data.changeByInt("keeper.drillbuff", - addedDrillBuff)
	
	if plantReady:
		return 
	
	if producing and GameWorld.runStarted:
		var d: float = delta
		var overchargeTime = Data.of("orchard.remainingovercharged")
		if overchargeTime >= 0.0:
			if not $Sprite.animation.begins_with("overcharged"):
				$Sprite.play("overcharged_" + Level.domeId())
			d *= 2
			overchargeTime -= delta
			Data.apply("orchard.remainingovercharged", overchargeTime)
		else:
			if not $Sprite.animation.begins_with("growing"):
				$Sprite.play("growing_" + Level.domeId())
			
		var plantGrowth = Data.of("orchard.currentgrowth") + d / grownAfter
	
		Data.apply("orchard.currentgrowth", plantGrowth)
		if plantGrowth >= 1.0:
			createFruit()
			$Center / OrchardActive.stop()
	else:
		producing = true
		grownAfter = GameWorld.getTimeBetweenWaves() * float(Data.of("orchard.growthTime"))
		$Sprite.play("growing_" + Level.domeId())
		$Center / OrchardActive.play()

func canFocusUse()->bool:
	if plantReady:
		return true
	if canOvercharge():
		return true
	return false

func useHold(keeper: Keeper):
	useHit(keeper)

func useHit(keeper: Keeper)->bool:
	if plantReady:
		Audio.sound("apple")
		$Sprite.play("empty_" + Level.domeId())
		var durationCycles: float = Data.of("orchard.buffduration")
		if Data.of("orchard.overchargedbuff"):
			durationCycles += Data.of("orchard.overchargeadditionalbuffduration")
			Data.apply("orchard.overchargedbuff", false)
		Data.changeByInt("orchard.buffedcycles", durationCycles)
		var duration = GameWorld.getTimeBetweenWaves() * durationCycles
		if Data.of("orchard.remainingbuffduration") > 0.0:
			Data.changeByInt("keeper.speedBuff", - addedSpeedBuff)
			Data.changeByInt("keeper.drillbuff", - addedDrillBuff)
		addedSpeedBuff = Data.of("orchard.speedBuff")
		addedDrillBuff = Data.of("orchard.drillbuff")
		Data.changeByInt("keeper.speedBuff", addedSpeedBuff)
		Data.changeByInt("keeper.drillbuff", addedDrillBuff)
		Data.apply("orchard.remainingbuffduration", duration)
		plantReady = false
		Data.apply("orchard.currentgrowth", 0.0)
		$Sprite / Fruit.visible = false
		$Sprite / Fruit.playing = false
		$Timer.stop()
		Backend.event("gadget_used", "orchard")
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
	$Sprite.play("overcharged_" + Level.domeId())
	Data.apply("orchard.remainingovercharged", GameWorld.getTimeBetweenWaves() * Data.of("orchard.overchargeDuration"))
	Data.apply("orchard.overchargedbuff", true)
	Data.apply("orchard.overchargedbattle", true)
	Data.changeByInt("inventory.water", - 1)
	Backend.event("gadget_overcharged", {"gadget": "orchard"})

func canOvercharge()->bool:
	return Data.of("orchard.overchargeDuration") > 0.0 and Data.of("orchard.remainingovercharged") <= 0.0

func createFruit():
	plantReady = true
	producing = false
	$Usable.updateFocus()
	$Sprite.play("fruit_" + Level.domeId())
	$Sprite / Fruit.visible = false
	$Sprite / Fruit.play("shine_" + Level.domeId())
	$Sprite / Fruit.position = FRUIT_OFFSETS.get(Level.domeId(), Vector2.ZERO)
	$Sprite / Fruit.show()
	_on_Timer_timeout()
	$FruitSpawnSound.play()
	$TreeTimer.start()

func _on_Timer_timeout():
	if not GameWorld.softPaused():
		$Sprite / Fruit.play("shine_" + Level.domeId())
		$Sprite / Fruit.frame = 0
	$Timer.wait_time = 2.0 + randf() * 2.0
	$Timer.start()

func _on_TreeTimer_timeout():
	if not $Sprite.animation.begins_with("fruit"):
		return 
	
	if not GameWorld.softPaused():
		$Sprite.frame = 0
	$TreeTimer.wait_time = 4.0 + randf() * 2.0
	$TreeTimer.start()

func deactivate():
	battleAbilityActive = false
	match mode:
		Mode.ROOTS:
			pass
		Mode.SHIELD:
			$ShieldEndSound.play()

func getBattleAbilityName()->String:
	match mode:
		Mode.ROOTS:
			return tr("upgrades.orchardbattlerooting.title")
		Mode.SHIELD:
			return tr("upgrades.orchardbattleshield.title")
	return ""

func executeBattle1()->bool:
	if mode == Mode.NOTHING:
		return false
	elif mode == Mode.ROOTS and Data.of("orchard.battlerootexplosion") > 0:
		var roots = get_tree().get_nodes_in_group("orchard-root")
		var exploded: = false
		for root in roots:
			if root.hasCatch():
				root.explode()
				exploded = true
		if exploded:
			return true
	
	var remainingUses = Data.of("orchard.remainingbattleuses")
	if remainingUses <= 0:
		Audio.sound("gui_err")
		return false
	Data.apply("orchard.remainingbattleuses", remainingUses - 1)
	
	battleAbilityActive = true
	
	match mode:
		Mode.ROOTS:
			$RootingSound.play()
			var delay = 0.01
			var paths: Array = Level.world.getDefensivePaths("walk_medium", "left")
			paths.append_array(Level.world.getDefensivePaths("walk_medium", "right"))
			paths.shuffle()
			for i in range(0, Data.of("orchard.battleroots")):
				var path = paths[i % paths.size()]
				var pos = path.curve.interpolate_baked(path.curve.get_baked_length() * (0.5 + randf() * 0.3)) + path.position
				$Tween.interpolate_callback(self, delay, "spawnRoot", pos)
				delay += 0.2 + randf() * 0.15
			$Tween.start()
		Mode.SHIELD:
			$ShieldSound.play()
			var delay = 0.01
			var offsets = [0.25, 0.5, 0.75]
			offsets.shuffle()
			for offset in offsets:
				var shield = preload("res://content/gadgets/orchard/OrchardShield.tscn").instance()
				var pos = Level.dome.getCupolaPosition(offset)
				shield.position.x = pos.x
				shield.position.y = pos.y
				shield.rotation = pos.z
				Level.dome.add_child(shield)
				shield.init(delay, 30)
				delay += 0.1 + randf() * 0.15
			
			if Data.of("orchard.battleshields") >= 2:
				offsets = [0.2, 0.4, 0.6, 0.8]
				offsets.shuffle()
				for offset in offsets:
					var shield = preload("res://content/gadgets/orchard/OrchardShield.tscn").instance()
					var pos = Level.dome.getCupolaPosition(offset)
					pos.y -= 10
					shield.position.x = pos.x
					shield.position.y = pos.y
					shield.rotation = pos.z
					Level.dome.add_child(shield)
					shield.init(delay, 40)
					delay += 0.1 + randf() * 0.15
			
			$Tween.stop_all()
			$Tween.remove_all()
			$Tween.interpolate_callback(self, Data.of("orchard.battleabilityduration"), "deactivate")
			$Tween.start()
	
	Backend.event("battle_ability_used", {"gadget": "orchard", "ability": Mode.keys()[mode]})
	return true

func spawnRoot(pos: Vector2):
	var root = preload("res://content/gadgets/orchard/OrchardRoot.tscn").instance()
	pos.y += 2
	root.position = pos
	Level.monsters.add_child(root)

func _on_Fruit_frame_changed():
	if ($Sprite / Fruit.animation == "shine_dome1" and $Sprite / Fruit.frame == 3) or \
	($Sprite / Fruit.animation == "shine_dome2" and $Sprite / Fruit.frame == 3):

		pass

func pauseChanged():
	if GameWorld.paused:
		$Tween.stop_all()
	else:
		$Tween.resume_all()
