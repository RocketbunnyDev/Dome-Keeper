extends Node

func init():
	Data.apply("prestige.score", 0)
	if GameWorld.modeVariation == CONST.MODE_PRESTIGE_COUNTDOWN:
		Data.apply("prestige.multiplier", 20)
	else:
		Data.apply("prestige.multiplier", 1)
	
	match GameWorld.modeVariation:
		CONST.MODE_PRESTIGE_MINER:
			Data.listen(self, "keeper.insidedome")
		"":
			Achievements.addIfOpen(self, "PRESTIGE_MULTIPLIER")
	
	Data.apply("prestige.baseperwave", 1)

	Data.listen(self, "monsters.cycle")
	Data.listen(self, "dome.health")
	Data.listen(self, "upgrade.gameover")
	GameWorld.difficulty = 0
	
	Achievements.addIfOpen(self, "PRESTIGE_CHUNK")
	Achievements.addIfOpen(self, "PRESTIGE_WIN")
	
	Level.world.addBackgroundHub(preload("res://content/gamemode/prestige/rocket/RocketHub.tscn").instance())
	
	CheatDetection.start()


func propertyChanged(property: String, oldValue, newValue):
	match property:
		"keeper.insidedome":
			if not newValue:
				GameWorld.runStarted = true
				Data.apply("wavemeter.stage", 2)
				Data.unlisten(self, "keeper.insidedome")
		"upgrade.gameover":


			if Data.of("keeper.insidestation"):
				Level.keeper.exitStation()
			Level.stage.stopKeeperInput()
			Level.hud.moveOut()
			GameWorld.handleGameWon({"prestigeScore": Data.of("prestige.score")})
			Level.monsters.disabled = true
			Data.unlisten(self, "dome.health")
			
			if Data.of("monsters.wavepresent"):
				Data.apply("monsters.wavepresent", false)
			
			for m in get_tree().get_nodes_in_group("monster"):
				m.onGameLost()
			
			Audio.stopBattleMusic()
			yield (get_tree().create_timer(0.2), "timeout")
			Audio.startEnding()
			yield (get_tree().create_timer(4.0), "timeout")
			

			
			var popup = preload("res://content/gamemode/prestige/RunFinishedPopup.tscn").instance()
			Level.stage.showEndingPanel(popup)
		"monsters.cycle":
			var multiplier = Data.of("prestige.multiplier")
			var base = Data.of("prestige.baseperwave")
			var newScore = int(base * multiplier) + int(Data.of("prestige.score"))
			CheatDetection.registerPrestige(base, multiplier, newScore)
			Data.apply("prestige.score", newScore)
			match GameWorld.modeVariation:
				CONST.MODE_PRESTIGE_COUNTDOWN:
					Data.apply("prestige.multiplier", multiplier - 1)
				CONST.MODE_PRESTIGE_MINER:
					if newValue == 20:
						Level.stage.stopKeeperInput()
						Audio.startEnding()
						
						yield (get_tree().create_timer(3.0), "timeout")
						GameWorld.handleGameWon({"prestigeScore": newScore})
						var popup = preload("res://content/gamemode/prestige/RunFinishedPopup.tscn").instance()
						Level.stage.showEndingPanel(popup)
		"dome.health":
			if newValue <= 0 and not GameWorld.lost:
				Level.hud.moveOut()
				GameWorld.lost = true
				Data.apply("monsters.wavepresent", false)
				
				var delay = Level.stage.playGameLostAnimation()
				yield (get_tree().create_timer(delay), "timeout")
				Audio.sound("lose")
				yield (get_tree().create_timer(0.2), "timeout")
				GameWorld.handleGameLost({"prestigeScore": Data.of("prestige.score")})
				
				Audio.startGameOver(1.0)
				yield (get_tree().create_timer(5.0), "timeout")
				
				var popup = preload("res://content/gamemode/prestige/RunFinishedPopup.tscn").instance()
				Level.stage.showEndingPanel(popup)

func addCycleData(data: Dictionary):
	data["prestige.multiplier"] = Data.of("prestige.multiplier")
	data["prestige.baseperwave"] = Data.of("prestige.baseperwave")
	data["prestige.score"] = Data.of("prestige.score")

func getRunWeight()->float:
	if GameWorld.modeVariation == CONST.MODE_PRESTIGE_MINER:
		return 0.0
	
	var weight: = 0.0
	weight += Data.of("inventory.totaliron") * 0.7
	weight += Data.of("inventory.totalsand") * 3
	weight += Data.of("inventory.totalwater") * 1.5
	weight += Data.of("inventory.gadget") * 10
	var cycle = Data.of("monsters.cycle")
	weight += round(pow(cycle, (1.0 + cycle * 0.015)) * 4.1 + 8)


	weight += GameWorld.additionalRunWeight
	return max(15, weight)
