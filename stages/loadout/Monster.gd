extends "res://content/monster/Monster.gd"

func _ready():
	if GameWorld.isHalloween:
		$Sprite.play("halloween")
	else:
		$Sprite.play("default")
	
	Style.init(self)
