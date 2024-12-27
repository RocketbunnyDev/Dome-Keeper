class_name HitMaskSprite
extends Sprite


onready var opacity = modulate.a
const THRESHOLD = 0.1


func shrink_mask(amount: float):
	modulate.a *= 1 - amount
	if modulate.a <= THRESHOLD:
		queue_free()
