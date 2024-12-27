extends Stage

func beforeStart():
	self.fadeInTime = 0.0
	self.fadeOutTime = 0.2
	find_node("RawFury").modulate.a = 0.0
	find_node("RawFury").modulate.r = 0.0
	find_node("RawFury").modulate.g = 0.0
	find_node("RawFury").modulate.b = 0.0

func end_animation():
	$Tween.interpolate_property(find_node("RawFury"), "modulate:a", 0.0, 1.0, 0.2)
	$Tween.interpolate_property(find_node("RawFury"), "modulate:r", 0.0, 1.0, 0.2, Tween.TRANS_LINEAR, Tween.EASE_IN, 0.2)
	$Tween.interpolate_property(find_node("RawFury"), "modulate:g", 0.0, 1.0, 0.2, Tween.TRANS_LINEAR, Tween.EASE_IN, 0.2)
	$Tween.interpolate_property(find_node("RawFury"), "modulate:b", 0.0, 1.0, 0.2, Tween.TRANS_LINEAR, Tween.EASE_IN, 0.2)
	$Tween.interpolate_callback(self, 1.5, "finishStage")
	$Tween.start()

func finishStage():
	emit_signal("request_end")
