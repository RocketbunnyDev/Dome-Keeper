extends Label

const sizeOffset: = Vector2(0, - 34)
const posOffset: = Vector2(0, 14)

var dieAt: = 1000
var dead: = false

func _ready():
	if text == " ":
		$HitArea / CollisionShape2D.disabled = true
	var size = rect_size + sizeOffset
	$HitArea.position = posOffset + size * 0.5
	$HitArea / CollisionShape2D.shape.radius = size.x * 0.5
	$HitArea / CollisionShape2D.shape.height = size.y - size.x
	$VisibleLetter.text = text

func die():
	dead = true
	var l = preload("res://stages/loadout/PhysicsLetter.tscn").instance()
	l.init(text, $HitArea / CollisionShape2D.shape)
	l.position = rect_global_position + rect_size * 0.5 * 0.333333
	get_parent().get_parent().add_child(l)
	l.apply_central_impulse(Vector2(50, - 30))
	$VisibleLetter.visible = false
	$HitArea / CollisionShape2D.disabled = true


const SHAKE_NOISE_SCROLL_SPEED: float = 1000.0
var shake_noise = preload("res://content/shared/opensimplexnoise.tres")
var shake_noise_offset: float = 0

func _process(delta):
	if $HitArea.damage <= 0 or dead:
		return 
	
	if $HitArea.damage >= dieAt:
		die()
	
	shake_noise_offset += delta * SHAKE_NOISE_SCROLL_SPEED
	$VisibleLetter.rect_position = $HitArea.damage * 2.0 * Vector2(
		2 * shake_noise.get_noise_2d(shake_noise_offset, 0) - 1, 
		2 * shake_noise.get_noise_2d(0, shake_noise_offset) - 1
	)
	
	$HitArea.damage = max($HitArea.damage - delta * 6.0, 0)
	var dmg = ($HitArea.damage / $HitArea.threshold)
	$VisibleLetter.modulate = Color.white + Color("#FFAA5E") * 3.0 * dmg
	$VisibleLetter.rect_scale = Vector2.ONE * (1 + dmg * 0.2)
