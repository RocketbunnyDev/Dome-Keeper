extends Node2D

func _ready():
	Style.setPalette("1_1")
	GameWorld.initUpgrades()
	GameWorld.reset()
	GameWorld.playerMaxSpeed *= 3
	GameWorld.playerSpeedLossPerCarry *= 0.1
	var i = preload("res://content/keeper/KeeperInputProcessor.gd").new()
	i.name = "KeeperInputProcessor"
	i.keeper = find_node("Keeper")
	i.integrate(self)
