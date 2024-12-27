extends HudElement

const rectSizes: = [21, 27, 33]
const inventorySizes: = [6, 7, 8]
const textures: = [
	preload("res://content/hud/healthmeter/background1.png"), 
	preload("res://content/hud/healthmeter/background2.png"), 
	preload("res://content/hud/healthmeter/background3.png"), 
]

var maxSize: int
var potentialRepair: float

func init():
	Data.listen(self, "dome.health")
	Data.listen(self, "dome.potentialrepair")
	Data.listen(self, "dome.healthbar", true)
	$RepairRect.rect_size.x = 0

func propertyChanged(property: String, oldValue, newValue):
	match property:
		"dome.health":
			updateRects(Data.of("dome.health"), Data.of("dome.potentialrepair"))
			if newValue < oldValue:
				flash()
		"dome.healthbar":
			$Background.texture = textures[int(newValue)]
			maxSize = rectSizes[int(newValue)]
			size.x = inventorySizes[int(newValue)]
			updateRects(Data.of("dome.health"), Data.of("dome.potentialrepair"))
			emit_signal("request_rebuild")
		"dome.potentialrepair":
			updateRects(Data.of("dome.health"), Data.of("dome.potentialrepair"))

func flash():
	$Tween.interpolate_property(self, "modulate", Color(10, 10, 10, 1), Color(1, 1, 1, 1), 0.2, Tween.TRANS_CUBIC, Tween.EASE_OUT)
	$Tween.start()

func updateRects(newHealth, newRepair: = 0.0):
	var mx = Data.of("dome.maxHealth")

	$HealthRect.rect_size.x = (maxSize * (newHealth / float(mx)))
	var fraction = (newHealth + newRepair) / float(mx)
	$RepairRect.rect_size.x = (maxSize * min(1.0, fraction))
	$BadRepairRect.rect_size.x = (maxSize * max(0.0, fraction - 1.0))
	$BadRepairRect.rect_position.x = $RepairRect.rect_position.x + $RepairRect.rect_size.x
	
	if newRepair > 0.0:
		if not $Tween.is_active():
			_on_Tween_tween_all_completed()
	else:
		$Tween.stop_all()
		$Tween.remove_all()
		$RepairRect.modulate = Color.white
		$BadRepairRect.modulate = Color.white

const color_light_flash: = Color(1.3, 1.3, 1.3)
const color_darken: = Color(0.5, 0.5, 0.5)
const color_flash: = Color(1.5, 1.5, 1.5)
func _on_Tween_tween_all_completed():
	$Tween.interpolate_property($RepairRect, "modulate", Color.white, Color.white * 1.3, 0.1, Tween.TRANS_SINE, Tween.EASE_OUT_IN)
	$Tween.interpolate_property($RepairRect, "modulate", Color.white * 1.3, Color.white, 0.4, Tween.TRANS_SINE, Tween.EASE_IN_OUT, 0.1)
	
	$Tween.interpolate_property($BadRepairRect, "modulate", $BadRepairRect.modulate, color_flash, 0.05, Tween.TRANS_SINE, Tween.EASE_OUT_IN)
	$Tween.interpolate_property($BadRepairRect, "modulate", color_flash, color_darken, 0.2, Tween.TRANS_SINE, Tween.EASE_IN_OUT, 0.05)
	$Tween.interpolate_property($BadRepairRect, "modulate", color_darken, color_flash, 0.05, Tween.TRANS_SINE, Tween.EASE_OUT_IN, 0.25)
	$Tween.interpolate_property($BadRepairRect, "modulate", color_flash, color_darken, 0.2, Tween.TRANS_SINE, Tween.EASE_IN_OUT, 0.3)
	$Tween.start()
