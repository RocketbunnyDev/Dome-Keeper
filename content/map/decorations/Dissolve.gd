extends Node2D

var _texture: Texture

func _ready():
	$Particles2D.emitting = true
	$Timer.wait_time = $Particles2D.lifetime
	$Timer.start()

func set_texture(value: Texture, flipped: bool, hframes: int, frame: int):
	_texture = value
	if _texture == null:
		return 
		
	
	var pixels: PoolVector2Array = []
	var colors: PoolColorArray = []
	
	var image = _texture.get_data()
	var width = _texture.get_width() / hframes
	var startX = frame * width
	var height = _texture.get_height()
	image.lock()
	for x in range(width):
		for y in range(height):
			var c = image.get_pixel(startX + x, y)
			var v = Vector2(x - width / 2, y - height / 2)
			if flipped:
				v.x = - v.x
			if c.a > 0:
				pixels.append(v)
				colors.append(c)
	image.unlock()
	
	
	$Particles2D.emission_points = pixels
	$Particles2D.emission_colors = colors
	$Particles2D.amount = pixels.size()
	
func get_texture()->Texture:
	return _texture

func _on_Timer_timeout():
	queue_free()
