extends Node2D

var origin = Vector2.ZERO

var fade_time = 0.0
var ammo_index: = 0

func _ready()->void :
	origin = position

func set_radius(value: float):
	$Sprite.position.y = value * - 0.5

func init(maxAmmo):
	fade_time = Data.of("obelisk.shootDelay") * 0.18
	


	
	if maxAmmo > 25:
		$Sprite.texture = load("res://content/weapons/obelisk/ammo25.png")
	elif maxAmmo >= 15:
		$Sprite.texture = load("res://content/weapons/obelisk/ammo15.png")
	elif maxAmmo >= 9:
		$Sprite.texture = load("res://content/weapons/obelisk/ammo9.png")
	elif maxAmmo >= 5:
		$Sprite.texture = load("res://content/weapons/obelisk/ammo5.png")
	elif maxAmmo >= 3:
		$Sprite.texture = load("res://content/weapons/obelisk/ammo3.png")
	elif maxAmmo >= 2:
		$Sprite.texture = load("res://content/weapons/obelisk/ammo2.png")
	else:
		$Sprite.texture = load("res://content/weapons/obelisk/ammo1.png")
	
	Style.init(self)
	appear()

func vanish():
	if $Sprite.modulate.a != 0.0:
		$Tween.interpolate_property($Sprite, "modulate:a", $Sprite.modulate.a, 0.0, fade_time, Tween.TRANS_BACK)
		
		$Tween.start()

func appear():
	if $Sprite.modulate.a != 1.0:
		$Tween.interpolate_property($Sprite, "modulate:a", $Sprite.modulate.a, 1.0, fade_time, Tween.TRANS_BACK)
		
		$Tween.start()
