extends Control

func _ready():
	SteamGlobal.init(false)
	GameWorld.version = "v1.1"
	GameWorld.init()
	Backend.init()
	Options.init()
	
	Data.apply("prestige.baseperwave", 10)
	Data.apply("prestige.multiplier", 1)
	Data.apply("monsters.cycle", 1)
	Data.apply("prestige.score", 1)
	Data.apply("prestige.sentcobalt", 1)
	Data.apply("inventory.totalsand", 1)
	
	$RunFinishedPopup.startScoreCount()
