extends "res://content/gadgets/CellarGadget.gd"

var charging: = false

func _ready():
	Data.apply("probe.chargesRemaining", Data.of("probe.charges"))
	Data.listen(self, "probe.chargesRemaining", true)
	Data.listen(self, "probe.charges")
	
	Style.init(self)
	
	Achievements.addIfOpen(self, "PROBE_USE")

func canFocusUse()->bool:
	return not charging and Data.of("probe.chargesRemaining") < Data.of("probe.charges")

func useHold(keeper: Keeper):
	return useHit(keeper)

func useHit(keeper: Keeper)->bool:
	if charging:
		return 
	keeper.externallyMoved = true
	keeper.move *= 0
	$Tween.interpolate_property(keeper, "position", keeper.position, $KeeperPos.global_position, 0.2, Tween.TRANS_CUBIC, Tween.EASE_IN_OUT)
	$Tween.start()
	yield (get_tree().create_timer(0.3), "timeout")
	var p1 = Vector2($Slider.position.x, - 20)
	var p2 = Vector2($Slider.position.x, - 4)
	$Tween.interpolate_property($Slider, "position", p1, p2, 0.2, Tween.TRANS_CUBIC, Tween.EASE_IN_OUT)
	$Tween.interpolate_property($Slider, "position", p2, p1, 0.2, Tween.TRANS_CUBIC, Tween.EASE_IN_OUT, 0.2)
	$Tween.interpolate_property($Slider, "position", p1, p2, 0.2, Tween.TRANS_CUBIC, Tween.EASE_IN_OUT, 0.4)
	$Tween.interpolate_property($Slider, "position", p2, p1, 0.2, Tween.TRANS_CUBIC, Tween.EASE_IN_OUT, 0.6)
	$Tween.interpolate_property($Slider, "position", p1, p2, 0.2, Tween.TRANS_CUBIC, Tween.EASE_IN_OUT, 0.8)
	$Tween.interpolate_property($Slider, "position", p2, p1, 0.2, Tween.TRANS_CUBIC, Tween.EASE_IN_OUT, 1.0)
	$Tween.start()
	$Tween.interpolate_callback(keeper, 1.2, "set", "externallyMoved", false)
	$Tween.interpolate_callback(Data, 1.2, "apply", "probe.chargesRemaining", Data.of("probe.charges"))
	charging = true
	$ChargeSound.play()
	return true

func propertyChanged(property: String, oldValue, newValue):
	match property:
		"probe.chargesremaining":
			if newValue == Data.of("probe.charges"):
				$Sprite.play("off")
			if newValue == 0:
				$Sprite.play("on")
			charging = false
		"probe.charges":
			Data.apply("probe.chargesRemaining", Data.of("probe.charges"))
