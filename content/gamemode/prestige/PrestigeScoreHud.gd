extends HudElement

func init():
	Data.listen(self, "prestige.score")
	Data.listen(self, "prestige.baseperwave")
	Data.listen(self, "prestige.multiplier")
	Data.listen(self, "upgrade.gameover")
	
	$ScoreLabel.text = str(Data.of("prestige.score"))
	$BasePerWaveLabel.text = str(Data.of("prestige.baseperwave"))
	$MultiplierLabel.text = str(Data.of("prestige.multiplier"))

func propertyChanged(property: String, oldValue, newValue):
	match property:
		"upgrade.gameover":
			Data.unlisten(self, "prestige.score")
		"prestige.baseperwave":
			if not oldValue:
				oldValue = 1
			$BasePerWaveLabel.text = str(newValue)
			if newValue > 1:
				pingLabel($BasePerWaveLabel, newValue - oldValue)
		"prestige.multiplier":
			if not oldValue:
				oldValue = 1
			$MultiplierLabel.text = str(newValue)
			if newValue > 0:
				pingLabel($MultiplierLabel, newValue - oldValue)
		"prestige.score":
			if not oldValue:
				oldValue = 0
			var total: float = newValue - oldValue
			if total == 0:
				$ScoreLabel.text = "%05.0f" % 0.0
				return 
			
			$Tween.stop_all()
			$Tween.remove_all()
			$Tween.interpolate_callback(self, 2.3, "updateToNewScore", total, oldValue, newValue)
			$Tween.start()

func updateToNewScore(total, oldValue, newValue):
	$ScoreLabel.rect_pivot_offset = $ScoreLabel.rect_size * 0.5
	var delay: = 0.0
	for i in 5:
		var baseString: = "%05.0f" % float(oldValue)
		baseString = baseString.substr(i + 1)
		$Tween.interpolate_callback($ScoreLabel, delay, "set", "text", baseString)
		delay += 0.08
	delay += 0.4
	$Tween.interpolate_callback($ScoreLabel, delay, "set", "text", "+" + str(total))
	$Tween.interpolate_property($ScoreLabel, "rect_scale", Vector2.ONE * 1.6, Vector2.ONE, 0.2, Tween.TRANS_QUAD, Tween.EASE_OUT, delay)
	$Tween.interpolate_callback($Kaching, delay, "play")
	delay += 1.6
	$Tween.interpolate_callback($ScoreLabel, delay, "set", "text", "")
	delay += 0.4
	
	for i in 5:
		var baseString: = "%05.0f" % float(oldValue)
		baseString = baseString.substr(4 - i)
		$Tween.interpolate_callback($ScoreLabel, delay, "set", "text", baseString)
		delay += 0.08
	delay += 0.2
	
	var actualDelta: = 0.0
	for i in total:
		var fraction = 1 / float(total - i * 0.99)
		var speed = 1.0 * fraction
		actualDelta += speed
		var intermediateValue = oldValue + i + 1
		if actualDelta > 0.01 and intermediateValue < newValue:
			$Tween.interpolate_callback($ScoreLabel, delay, "set", "text", "%05.0f" % float(oldValue + i + 1))
			$Tween.interpolate_callback($Ping, delay, "play")
			actualDelta = 0
		delay += speed
	$Tween.interpolate_property($ScoreLabel, "rect_scale", Vector2.ONE * 1.6, Vector2.ONE, 0.2, Tween.TRANS_QUAD, Tween.EASE_OUT, delay)
	$Tween.interpolate_callback($Kaching, delay, "play")
	$Tween.interpolate_callback($ScoreLabel, delay, "set", "text", "%05.0f" % float(newValue))
	$Tween.start()

func pingLabel(l: Label, magnitude):
	l.rect_pivot_offset = l.rect_size * 0.5
	l.rect_scale = (1.4 + magnitude * 0.5) * Vector2.ONE
	$Tween.interpolate_property(l, "rect_scale", l.rect_scale, Vector2.ONE, 0.1, Tween.TRANS_QUAD, Tween.EASE_OUT)
	$Tween.start()
