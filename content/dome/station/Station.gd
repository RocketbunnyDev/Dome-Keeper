extends Node2D

var keeperInStation: = false

func _ready():
	$Sprite.play("default")
	Data.listen(self, "keeper.insidestation")
	Data.listen(self, "monsters.wavepresent")
	$WaveAlarm.visible = false

func propertyChanged(property: String, oldValue, newValue):
	match property:
		"keeper.insidestation":
			keeperInStation = newValue
			if newValue:
				$Sprite.play("on_" + Level.keeperId())
				$Usable.updateFocus()
				$WaveAlarm.visible = false
			else:
				$Sprite.play("off")
				$Usable.updateFocus()
				if Data.of("monsters.wavepresent"):
					$WaveAlarm.visible = true
					$Sprite.play("attack")
		"monsters.wavepresent":
			if newValue and not keeperInStation:
				$Sprite.play("attack")
				$WaveAlarm.visible = true
				$WaveAlarm.frame = 0
				$WaveAlarm.playing = true
			else:
				$WaveAlarm.visible = false

func canFocusUse()->bool:
	return not keeperInStation

func dropTarget()->Vector2:
	return global_position

func useHold(keeper: Keeper):
	useHit(keeper)

func useHit(keeper: Keeper)->bool:
	keeper.enterStation()
	return true

func _on_Sprite_animation_finished():
	if $Sprite.animation.begins_with("on"):
		$Sprite.play("running_" + Level.keeperId())
	elif $Sprite.animation == "off":
		$Sprite.play("idle")

func getKeeperPosition()->Vector2:
	return $KeeperPosition.global_position
