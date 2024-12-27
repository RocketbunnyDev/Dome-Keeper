extends YSort

class_name Monsters

var disabled: = false
var waveTime: = 0.0
var spawnDelayWhileInMine: = 0.0
var timeLeftMidBattle: = 0.0
var timeLeftMidBattleThreshold: = 30.0
var monsterIndex: = 0
var keeperInDomeDuringWave: = false
var finale: = false
var monstersInWave: = []
var currentWave: Wave
var spawnPlan: Array
var monsterCount: = 0

var waveDamageCounter: = 0.0
var lastWaveStrengthModChange: = 0.0


var nextWaveType: = 1

var waveCounter: int
var remainingMonsters: int

func init():
	disabled = GameWorld.devMode
	applyTimeBetweenWaves()
	
	if GameWorld.gameMode == CONST.MODE_RELICHUNT:
		$WaveGenerator.setAllowedMonsters(Level.world.allowedMonsters)
	
	Data.listen(self, "map.tilesdestroyed")
	Data.listen(self, "dome.health")
	Data.listen(self, "inventory.iron")
	Data.listen(self, "shield.health")
	Data.listen(self, "keeper.insidestation")

func propertyChanged(property: String, oldValue, newValue):
	match property:
		"map.tilesdestroyed":
			if newValue >= 8:
				GameWorld.runStarted = true
				Data.unlisten(self, "map.tilesdestroyed")
		"dome.health":
			if newValue < oldValue:
				waveDamageCounter += oldValue - newValue
		"inventory.iron":
			
			if not GameWorld.runStarted:
				GameWorld.runStarted = true
				Data.unlisten(self, "inventory.iron")
		"shield.health":
			var amount = newValue - oldValue
			if amount < 0:
				waveDamageCounter += amount * 0.33
		"keeper.insidestation":
			if not newValue and Data.of("monsters.wavebattle") and not Data.of("monsters.wavepresent"):
				Data.apply("monsters.wavebattle", false)

func horde(i):
	disabled = false





func _process(delta):




	
	if Options.visibleMonsters:
		for m in get_tree().get_nodes_in_group("monster"):
			m.aim(true)
	
	if disabled or GameWorld.paused or not GameWorld.runStarted or GameWorld.lost or GameWorld.won:
		return 
	
	var keeperIsInDome = Data.of("keeper.insidedome")
	if Data.of("monsters.wavepresent"):
		keeperInDomeDuringWave = keeperInDomeDuringWave or keeperIsInDome
		var gracePeriodOver = spawnDelayWhileInMine > 10.0 - GameWorld.difficulty * 2.0
		var maxMonsters = max(2, 2 + GameWorld.difficulty)
		var doSpawn = (keeperInDomeDuringWave or gracePeriodOver)\
		 or monstersInWave.size() < maxMonsters\
		 and getCurrentHeadCount() <= 12 + GameWorld.difficulty
		
		if doSpawn:
			waveTime += delta
			if spawnPlan.size() > monsterIndex + 1:
				var nextMonsterPlan = spawnPlan[monsterIndex + 1]
				if waveTime > nextMonsterPlan.time:
					monsterIndex += 1
					spawnMonster(nextMonsterPlan.breed, nextMonsterPlan.variant)
			elif monstersInWave.size() == 0 and not $SpawnTween.is_active():
				finishWave()
		
		if keeperInDomeDuringWave and not keeperIsInDome:
			timeLeftMidBattle += delta
			if timeLeftMidBattle > timeLeftMidBattleThreshold:
				spawnMonster("walker", "right")
				spawnMonster("walker", "left")
				timeLeftMidBattle = 0.0
				timeLeftMidBattleThreshold = max(3.0, timeLeftMidBattleThreshold * 0.66)
		else:
			spawnDelayWhileInMine += delta
	elif not Data.of("monsters.wavebattle"):
		if GameWorld.waveDelay > 0.0:
			GameWorld.waveDelay -= delta
		else:
			var wcd = Data.of("monsters.waveCooldown")
			wcd -= delta
			if wcd < 10.0 and Data.of("keeper.insidestation"):
				
				wcd -= delta * 1.0
			Data.apply("monsters.waveCooldown", wcd)
		
		if Data.of("monsters.waveCooldown") <= 0.0:
			spawnWave()

func getCurrentHeadCount()->float:
	var count: = 0.0
	for m in get_tree().get_nodes_in_group("monster"):
		count += m.headCount
	return count

func applyTimeBetweenWaves():
	var tbw = GameWorld.getTimeBetweenWaves()
	Data.apply("monsters.timeBetweenWaves", tbw)
	Data.apply("monsters.waveCooldown", tbw)
	Data.apply("monsters.wavepresent", false)

func serialize()->Dictionary:
	var data: = {
		"disabled": disabled, 
		"waveTime": waveTime, 
		"waveCooldown": Data.of("monsters.waveCooldown"), 
		"wavepresent": Data.of("monsters.wavepresent"), 
		"spawnPlan": var2str(spawnPlan), 
		"monsterIndex": monsterIndex, 
		"lastMonsters": var2str($WaveGenerator.lastMonsters)
	}
	return data

func deserialize(data: Dictionary):
	for m in monstersInWave:
		if is_instance_valid(m):
			m.free()
	monstersInWave.clear()
	
	yield (GameWorld, "savegame_loaded")
	
	disabled = data["disabled"]
	waveTime = data["waveTime"]
	spawnPlan = str2var(data["spawnPlan"])
	monsterIndex = data["monsterIndex"]
	if data.has("lastMonsters"):
		$WaveGenerator.lastMonsters = str2var(data["lastMonsters"])
	Data.apply("monsters.waveCooldown", data["waveCooldown"])
	Data.apply("monsters.wavepresent", data["wavepresent"])
	
func spawnWave():
	var currentRunWeight = Level.mode.getRunWeight()
	if currentRunWeight <= 0.0:
		finishWave()
		return 
	
	waveTime = - 2.0
	monsterIndex = - 1
	Data.apply("monsters.wavepresent", true)
	Data.apply("monsters.wavebattle", true)
	keeperInDomeDuringWave = false
	waveDamageCounter = 0
	timeLeftMidBattle = 0.0
	
	var minimumTimingMod = Data.of("monsters.minimumTimingMod")
	minimumTimingMod = clamp(minimumTimingMod - GameWorld.difficulty * 0.1, 0.1, 1.0)
	var runWeightProgression = 1.0 - (currentRunWeight / float(Data.of("monsters.maximumTimingModAtRunWeight")))
	Data.apply("monsters.timingmod", clamp(runWeightProgression, minimumTimingMod, 1.0))
	currentWave = $WaveGenerator.generateWave(currentRunWeight, GameWorld.waveStrengthModifier)
	spawnPlan = currentWave.generateSpawnPlan()
	
	GameWorld.saveGame(0)
	
	var w = {
		"waveIndex": Data.of("monsters.cycle"), 
		"currentRunWeight": currentRunWeight, 
		"waveStrengthModifier": GameWorld.waveStrengthModifier, 
		"wave": currentWave.entries, 
		}
	Backend.event("wave_started", w)

func finishWave():
	applyTimeBetweenWaves()
	$WaveGenerator.waveFinished(currentWave)
	if Data.of("monsters.wavebattle") and not Data.of("keeper.insidestation"):
		Data.apply("monsters.wavebattle", false)
	
	GameWorld.incrementRunStat("waves_survived")
	var cycles = Data.of("monsters.cycle")
	Data.apply("monsters.cycle", cycles + 1)
	spawnDelayWhileInMine = 0.0
	waveCounter += 1
	

	var damageConsideredBad = 200
	var damageConsideredGood = 80

	var mod: float
	if waveDamageCounter > damageConsideredBad:
		mod = - 0.6 * ((waveDamageCounter - damageConsideredBad) / (damageConsideredBad * 3.0))

	elif waveDamageCounter < damageConsideredGood:
		mod = 0.05 + (1.0 - (waveDamageCounter / damageConsideredGood)) * 0.1

	else:
		mod = (1.0 - GameWorld.waveStrengthModifier) * 0.5

	
	lastWaveStrengthModChange = mod
	GameWorld.waveStrengthModifier = clamp(GameWorld.waveStrengthModifier + mod, 0.7 - GameWorld.difficulty * 0.1, 1.3 + GameWorld.difficulty * 0.1)

	
	GameWorld.saveGame(0)
	currentWave = null
	
	Backend.event("wave_finished", {
		"waveIndex": cycles, 
		"waveDamageCounter": waveDamageCounter, 
		"damageBySource": Level.dome.popTrackedDamage(), 
		})

func spawnMonster(breed: String, variant: String, groupSize: = 1):
	var monster
	match breed:
		"walker":
			monster = preload("res://content/monster/walker/Walker.tscn").instance()
			monster.path = Level.world.assignRandomPath(Data.of(breed + ".movetype"), variant, monster)
			monster.meleeTarget = Level.dome.getMeleeTarget(variant)
		"flyer":
			monster = preload("res://content/monster/flyer/Flyer.tscn").instance()
			monster.setProviders(Level.world.getFlyerPathProvider(), Level.dome.getProjectileTargetProvider(), variant)
		"stingray":
			monster = preload("res://content/monster/stingray/Stingray.tscn").instance()
			monster.setProviders(Level.world.getFlyerPathProvider(), Level.dome.getProjectileTargetProvider(), variant)
		"driller":
			monster = preload("res://content/monster/driller/Driller.tscn").instance()
			monster.path = Level.world.assignRandomPath(Data.of(breed + ".movetype"), variant, monster)
			monster.meleeTarget = Level.dome.getMeleeTarget(variant)
		"diver":
			monster = preload("res://content/monster/diver/Diver.tscn").instance()
			var pp = Level.dome.PiercePoints
			monster.domeTarget = pp.get_node("Left").global_position if variant == CONST.LEFT else pp.get_node("Right").global_position
			monster.retreatPosition = $DiverPaths / RetreatLeft if variant == CONST.LEFT else $DiverPaths / RetreatRight
			var path: Path2D = $DiverPaths / StartLeft if variant == CONST.LEFT else $DiverPaths / StartRight
			monster.divePosition = path.curve.interpolate_baked(path.curve.get_baked_length() * randf())
		"tick":
			var amount: int = Data.of("tick.groupsize") + round(randf() * Data.of("tick.grouprandom"))
			var time: = 0.0
			var interspawntime = Data.of("tick.interspawntime")
			for _i in range(0, amount):
				$SpawnTween.interpolate_callback(self, time, "spawnMonster", "tick_single", variant, amount)
				time += interspawntime + randf() * interspawntime
			
			waveTime -= time * 0.75
			$SpawnTween.start()
			return 
		"tick_single":
			monster = preload("res://content/monster/tick/Tick.tscn").instance()
			monster.headCount = 1.0 / float(groupSize)
			monster.path = Level.world.assignRandomPath(Data.of("tick.movetype"), variant, monster)
			monster.target = Level.dome.getFrontAttackPosition(variant)
		"bigtick":
			var amount: int = Data.of("bigtick.groupsize") + round(randf() * Data.of("bigtick.grouprandom"))
			var time: = 0.0
			var interspawntime = Data.of("bigtick.interspawntime")
			for _i in range(0, amount):
				$SpawnTween.interpolate_callback(self, time, "spawnMonster", "bigtick_single", variant, amount)
				time += interspawntime + randf() * interspawntime
			
			waveTime -= time * 0.75
			$SpawnTween.start()
			return 
		"bigtick_single":
			monster = preload("res://content/monster/bigtick/BigTick.tscn").instance()
			monster.headCount = 1.0 / float(groupSize)
			monster.path = Level.world.assignRandomPath(Data.of("bigtick.movetype"), variant, monster)
			monster.target = Level.dome.getFrontAttackPosition(variant)
		"worm":
			monster = preload("res://content/monster/worm/Worm.tscn").instance()
			monster.path = Level.world.assignRandomPath(Data.of(breed + ".movetype"), variant, monster)
			monster.projetileTargetProvider = Level.dome.getProjectileTargetProvider()
		"bolter":
			monster = preload("res://content/monster/bolter/Bolter.tscn").instance()
			monster.setProviders(Level.world.getFlyerPathProvider(), Level.dome.getProjectileTargetProvider(), variant)
		"mucker":
			monster = preload("res://content/monster/mucker/Mucker.tscn").instance()
			monster.path = Level.world.assignRandomPath(Data.of(breed + ".movetype"), variant, monster)
			monster.meleeTarget = Level.dome.getMeleeTarget(variant)
		"shifter":
			monster = preload("res://content/monster/shifter/Shifter.tscn").instance()
			monster.setProviders(Level.world.getFlyerPathProvider(), Level.dome.getProjectileTargetProvider(), variant)
		"butterfly":
			monster = preload("res://content/monster/butterfly/Butterfly.tscn").instance()
			monster.setProviders(Level.world.getFlyerPathProvider(), Level.dome.getProjectileTargetProvider(), variant)
		"beast":
			monster = preload("res://content/monster/Beast/Beast.tscn").instance()
			monster.path = Level.world.assignRandomPath(Data.of(breed + ".movetype"), variant, monster)
			monster.meleeTarget = Level.dome.getMeleeTarget(Data.of(breed + ".meleetarget"))
		"rockman":
			monster = preload("res://content/monster/rock walker/Rockman.tscn").instance()
			monster.path = Level.world.assignRandomPath(Data.of(breed + ".movetype"), variant, monster)
			monster.meleeTarget = Level.dome.getMeleeTarget(variant)
		"scarab":
			monster = preload("res://content/monster/scarab/Scarab.tscn").instance()
			monster.setProviders(Level.world.getFlyerPathProvider(), Level.dome.getProjectileTargetProvider(), variant)
		"stag":
			monster = preload("res://content/monster/stag/Stag.tscn").instance()
			monster.path = Level.world.assignRandomPath(Data.of(breed + ".movetype"), variant, monster)
			monster.projectileTargetProvider = Level.dome.getProjectileTargetProvider()
			monster.meleeTarget = Level.dome.getMeleeTarget(variant)
		_:
			Logger.error("cannot spawn unknown breed", "Monsters.spawnMonster", breed)
			return 
	
	remainingMonsters += 1
	monsterCount += 1
	monster.counter = monsterCount
	monster.connect("died", self, "monsterDied", [monster])
	
	add_child(monster)
	monstersInWave.append(monster)

func registerMonster(monster):
	remainingMonsters += 1
	monsterCount += 1
	monster.counter = monsterCount
	monster.connect("died", self, "monsterDied", [monster])
	add_child(monster)
	monstersInWave.append(monster)

func monsterDied(m):
	monstersInWave.erase(m)
	remainingMonsters -= 1
	if not finale and not m.techId == "tick":
		GameWorld.incrementRunStat("monsters_killed")

func onGameLost():
	disabled = true
	$SpawnTween.remove_all()

func startFinalAct():
	finale = true
	if Data.of("monsters.wavepresent"):
		
		currentWave = null
		spawnPlan.clear()


	waveTime = - 4.0
	monsterIndex = - 1
	Data.apply("monsters.timingmod", 0.3)
	Data.apply("monsters.wavepresent", true)
	Data.apply("monsters.wavebattle", true)
	Data.apply("monsters.waveCooldown", 0)
	GameWorld.waveDelay = 0
	currentWave = $WaveGenerator.generateWave(max(900, Level.mode.getRunWeight() * 3.5), 1.0)
	spawnPlan = currentWave.generateSpawnPlan()

func pauseChanged():
	if GameWorld.paused:
		$SpawnTween.stop_all()
	else:
		$SpawnTween.resume_all()
