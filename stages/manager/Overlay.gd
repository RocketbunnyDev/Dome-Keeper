extends ColorRect

func fadeInCallback(fadeTime, object, method: String):
	$Tween.stop_all()
	$Tween.remove_all()
	$Tween.interpolate_property(self, "color", self.color, Color(0, 0, 0, 0), fadeTime, Tween.TRANS_QUAD, Tween.EASE_IN)
	$Tween.interpolate_callback(object, fadeTime, method)
	$Tween.start()

func fadeOutCallback(fadeTime, object, method: String):
	$Tween.stop_all()
	$Tween.remove_all()
	$Tween.interpolate_property(self, "color", self.color, Color(0, 0, 0, 1), fadeTime, Tween.TRANS_LINEAR, Tween.EASE_IN)
	$Tween.interpolate_callback(object, fadeTime + 0.01, method)
	$Tween.start()

func setClear():
	self.color = Color(0, 0, 0, 0)

func setOpaque():
	self.color = Color(0, 0, 0, 1)
