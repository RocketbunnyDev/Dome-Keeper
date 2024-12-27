extends Node

func init():
	Data.apply("prestige.score", 0)
	Data.apply("prestige.baseperwave", 1)
	Data.apply("prestige.multiplier", 1)

	GameWorld.difficulty = 0
	
	Level.world.addBackgroundHub(preload("res://content/gamemode/prestige/rocket/RocketHub.tscn").instance())
	
	if GameWorld.isUpgradeLimitAvailable("fuel"):
		Level.hud.addHudElement({"hud": "content/gamemode/miner/FuelHud.tscn"})
	if GameWorld.isUpgradeLimitAvailable("highscore"):
		Level.hud.addHudElement({"hud": "content/gamemode/prestige/PrestigeScoreHud.tscn"})
		Data.listen(self, "monsters.cycle")
	
	CheatDetection.start()

func propertyChanged(property: String, oldValue, newValue):
	match property:
		"monsters.cycle":
			
			var multiplier = Data.of("prestige.multiplier")
			var base = Data.of("prestige.baseperwave")
			var newScore = int(base * multiplier) + int(Data.of("prestige.score"))
			CheatDetection.registerPrestige(base, multiplier, newScore)
			Data.apply("prestige.score", newScore)
			if newValue == 20 and oldValue != 20:
				$ScriptTween.interpolate_callback(self, 5.0, "finishRunWithContinue")
				$ScriptTween.start()

func finishRunWithContinue():
	Level.stage.stopKeeperInput()
	Audio.startEnding()
	
	yield (get_tree().create_timer(3.0), "timeout")
	var popup = preload("res://content/gamemode/prestige/RunFinishedPopup.tscn").instance()
	Level.stage.showEndingPanel(popup)
	Level.hud.removeHudElement({"hud": "content/gamemode/prestige/PrestigeScoreHud.tscn"})

func addCycleData(data: Dictionary):
	data["prestige.multiplier"] = Data.of("prestige.multiplier")
	data["prestige.baseperwave"] = Data.of("prestige.baseperwave")
	data["prestige.score"] = Data.of("prestige.score")

func getRunWeight()->float:
	return 0.0
