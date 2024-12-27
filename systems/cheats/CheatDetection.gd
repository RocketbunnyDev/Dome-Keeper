extends Node

var isRunning: = false
var lastScore: int
var lastCycle: int
var expectedNextRuntime: float
var prestigeWavesCounted: int

var scoreJump: = false
var timeJump: = false

func start():
	if not isRunning:
		Data.listen(self, "monsters.cycle", true)
	
	isRunning = true
	lastScore = Data.of("prestige.score")
	scoreJump = false
	timeJump = false
	
	lastCycle = Data.of("monsters.cycle")
	prestigeWavesCounted = lastCycle
	expectedNextRuntime = GameWorld.runTime + Data.ofOr("monsters.wavecooldown", GameWorld.getTimeBetweenWaves())

func stop()->int:
	if isRunning:
		Data.unlisten(self, "monsters.cycle")
	isRunning = false
	
	if not GameWorld.runCheatDetection:
		return 0
	
	var currentScore = Data.of("prestige.score")
	var multiplier = Data.of("prestige.multiplier")
	var baseperwave = Data.of("prestige.baseperwave")
	if lastScore != currentScore and lastScore * 2 != currentScore:
		scoreJump = true
	
	var cheatHash: = 0
	
	if scoreJump:
		cheatHash += 1


	
	var cycleCount = Data.of("monsters.cycle")
	if prestigeWavesCounted != cycleCount:
		cheatHash += 4
	
	var sentCobaltUpgrades = Data.of("prestige.sentcobalt")
	if GameWorld.modeVariation != CONST.MODE_PRESTIGE_COUNTDOWN:
		var expectedMultiplier: = 1
		expectedMultiplier += sentCobaltUpgrades
		if expectedMultiplier != multiplier:
			cheatHash += 8
	
	var expectedCobalt = 2 * sentCobaltUpgrades
	var totalSand = Data.of("inventory.totalsand")
	if GameWorld.modeVariation == CONST.MODE_PRESTIGE_COBALT:
		totalSand += 10 * 2
	if expectedCobalt > totalSand:
		cheatHash += 16
	
	if cycleCount > 0 and GameWorld.isUpgradeLimitAvailable("hostile"):
		var timePerBattle = GameWorld.wavePresentTime / float(cycleCount)
		if timePerBattle < 2.0 + 1.5 * sqrt(cycleCount):
			cheatHash += 32
	
	if GameWorld.devModeActivated:
		cheatHash += 64
	
	if currentScore > 90000 + randf() * 10000\
	 or cycleCount > 100 + randf() * 10\
	 or multiplier > 50 + randf() * 10\
	 or baseperwave > 50 + randf() * 10:
		cheatHash += 128
	
	return cheatHash

func resetIfRunning():
	if isRunning:
		start()

func propertyChanged(property: String, oldValue, newValue):
	match property:
		
		"monsters.cycle":
			if GameWorld.runTime < expectedNextRuntime - 10.0:
				timeJump = true
			expectedNextRuntime = GameWorld.runTime + Data.ofOr("monsters.wavecooldown", GameWorld.getTimeBetweenWaves())

func registerPrestige(base: int, multiplier: int, newScore: int):
	if lastScore != Data.of("prestige.score"):
		scoreJump = true
	var add = base * multiplier
	if newScore != lastScore + add:
		scoreJump = true
	lastScore = newScore
	prestigeWavesCounted += 1
