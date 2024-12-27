extends RigidBody2D

var tex_iron = preload("res://content/map/tile/tile-break-dirt-particle_iron.png")
var tex_water = preload("res://content/map/tile/tile-break-dirt-particle_water.png")
var tex_sand = preload("res://content/map/tile/tile-break-dirt-particle_sand.png")

var type: String = "default"

func _ready():
	var sprite = $Sprite
	if type != "default" and randf() > 0.7:
		sprite.scale = Vector2.ONE * 0.7
		match type:
			CONST.SAND:
				sprite.texture = tex_sand
				Style.init(sprite)
			CONST.IRON:
				sprite.texture = tex_iron
				Style.init(sprite)
			CONST.WATER:
				sprite.texture = tex_water
				Style.init(sprite)
	sprite.frame = randi() % (sprite.hframes * sprite.vframes)
	sprite.modulate = Color.white * rand_range(0.7, 1.5)
	sprite.modulate.a = 1.0
	sprite.scale = Vector2.ONE * (ease(randf() * 0.7, 1.5) + 0.7)
	
	$AnimationPlayer.playback_speed = rand_range(0.8, 1.2)
	$AnimationPlayer.play("start")
	
