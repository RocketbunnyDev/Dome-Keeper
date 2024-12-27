extends "res://content/monster/Monster.gd"

const reflectable: = false
var target: Vector2
var damage: float

func init():
	damage = Data.of("rock.damage")
	var peakY = (target.y + position.y) * 0.5 - 80 + randf() * 40
	var halfTime: = 1.0
	var delay: = 0.0
	$Sprite.play("flying")
	updateHitboxState()
	moveTween.interpolate_property(self, "position:x", position.x, target.x, halfTime * 2, Tween.TRANS_LINEAR, Tween.EASE_IN, delay)
	moveTween.interpolate_property(self, "position:y", position.y, peakY, halfTime, Tween.TRANS_QUAD, Tween.EASE_OUT, delay)
	moveTween.interpolate_property(self, "position:y", peakY, target.y, halfTime, Tween.TRANS_QUAD, Tween.EASE_IN, delay + halfTime)
	moveTween.interpolate_callback(self, delay + 2 * halfTime, "hitDome")
	moveTween.start()

func hitDome():
	Level.dome.requestProjectileDamage(damage * damageModifier, global_position, self)
	InputSystem.getCamera().shake(60, 0.4, 8)
	animation("hit")
	$DieSoundImpact.play()
	die()

func domeAcceptsDamage():
	pass

func domeReflectsDamage(returnedDamage: float = 0.0, returnedSpeed: float = 1.0, damageModifier: float = 2.0):
	receiveDamage = returnedDamage

func onGameLost():
	if currentHealth > 0:
		die()
		animateDeath()

func animateDeath():
	animation("destroyed")
	$DieSoundDestroyed.play()

func _on_Sprite_animation_finished():
	if $Sprite.animation == "hit" or $Sprite.animation == "destroyed":
		.removeFreeBlocker()

func _on_Rock_area_entered(area):
	if hittable:
		if area.is_in_group("monster"):
			area.hit(damage, 1.0)
		$DieSoundDestroyed.play()
		
		setHittable((false))
		$Sprite.play("hit")
		moveTween.stop_all()
		moveTween.remove_all()
