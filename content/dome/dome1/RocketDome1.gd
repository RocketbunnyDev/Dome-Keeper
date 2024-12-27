extends Node2D


func start():
	$Sprite.play("start")

func _on_AnimatedSprite_animation_finished()->void :
	if $Sprite.animation == "start":
		$Sprite.play("launch")
	elif $Sprite.animation == "launch":
		$Sprite.play("fly")
		$Tween.interpolate_property(self, "position:y", position.y, position.y - 500, 3.0, Tween.TRANS_QUAD, Tween.EASE_IN)
		$Tween.start()
