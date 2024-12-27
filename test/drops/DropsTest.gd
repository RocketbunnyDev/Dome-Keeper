extends Node

func _ready():
	GameWorld.prepareCleanData()
	var i = preload("res://content/keeper/KeeperInputProcessor.gd").new()
	i.keeper = $Keeper
	i.integrate(self)
	Level.keeper = $Keeper
	Style.setPalette("1_1")
	Style.init(self)
	
func _process(delta):
	if Input.is_action_pressed("f4"):
		var d = preload("res://content/drop/iron/IronDrop.tscn").instance()
		d.position.x = rand_range( - 50, 50)
		d.position.y = rand_range( - 50, 50)
		add_child(d)
