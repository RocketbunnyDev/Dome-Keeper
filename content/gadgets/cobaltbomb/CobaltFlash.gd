extends Node2D

func _ready():
	$AnimatedSprite.play("flash")
	Style.init(self)
