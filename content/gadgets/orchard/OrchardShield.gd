extends Area2D

signal exhausted

var done: = false
var remainingHp: int

func init(delay, offsetY):
	var oldPos = position
	position += Vector2.DOWN.rotated(rotation) * offsetY
	var duration = 0.6 + randf() * 0.4
	remainingHp = Data.of("orchard.battleshieldhp")
	$Sprite.frame = 0
	$Tween.interpolate_property(self, "position", position, oldPos, duration, Tween.TRANS_QUAD, Tween.EASE_OUT, delay)
	$Tween.interpolate_callback(self, Data.of("orchard.battleabilityduration") + duration + delay, "dissolve")
	$Tween.interpolate_callback($Sprite, delay, "play", "default")
	$Tween.start()
	
	Style.init(self)

func _on_Shield_area_entered(area):
	if done:
		return 
	

	
	area.domeAbsorbsDamage()
	


	remainingHp -= area.damage
	if remainingHp <= 0:
		dissolve()

func dissolve(delay: = 0.0):
	if delay > 0.0:
		$Tween.interpolate_callback(self, delay, "dissolve")
		$Tween.start()
		return 
	
	if done:
		return 
	
	done = true
	emit_signal("exhausted")
	
	var dissolve = preload("res://content/map/decorations/Dissolve.tscn").instance()
	dissolve.position = position
	dissolve.z_index = z_index
	dissolve.position += Vector2.DOWN.rotated(rotation) * 8
	dissolve.global_rotation = global_rotation
	dissolve.set_texture(preload("res://content/gadgets/orchard/shreelds_sheet.png"), false, 9, $Sprite.frame)
	get_parent().add_child(dissolve)
	queue_free()

func pauseChanged():
	if GameWorld.paused:
		$Tween.stop_all()
	else:
		$Tween.resume_all()
