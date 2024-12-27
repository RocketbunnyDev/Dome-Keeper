extends HudElement

var stage: int
var maxFilling: int
var shieldStrength: float
var maxShieldStrength: float
var pxFromShieldStrength: float
var pxFromCharges: float

func init():
	Data.listen(self, "shield.remainingbattleuses", true)
	Data.listen(self, "shield.battleuses", true)
	Data.listen(self, "shield.stage", true)
	Data.listen(self, "shield.maxstrength", true)
	Data.listen(self, "shield.strength", true)
	
	$Bar.visible = true
	$Bar / ShieldFilling.visible = true
	

func propertyChanged(property: String, oldValue, newValue):
	match property:
		"shield.remainingbattleuses":
			updateCharges(newValue)
		"shield.battleuses":
			updateSlots(newValue)
		"shield.stage":
			setStage(newValue)
		"shield.strength":
			shieldStrength = newValue
			updateFilling()
		"shield.maxstrength":
			maxShieldStrength = newValue
			updateFilling()
			
func updateFilling():
	var fill = maxFilling * (shieldStrength / maxShieldStrength)
	$Bar / ShieldFilling.rect_size.y = fill

func setStage(stage: int):
	self.stage = stage
	match int(stage):
		1:
			$Bar.texture = preload("res://content/gadgets/shield/hud/bar1.png")
			maxFilling = 4
			pxFromShieldStrength = 8
		2:
			$Bar.texture = preload("res://content/gadgets/shield/hud/bar2.png")
			maxFilling = 8
			pxFromShieldStrength = 12
		3:
			$Bar.texture = preload("res://content/gadgets/shield/hud/bar3.png")
			maxFilling = 12
			pxFromShieldStrength = 16
		4:
			$Bar.texture = preload("res://content/gadgets/shield/hud/bar4.png")
			maxFilling = 16
			pxFromShieldStrength = 20
	$Bar / ShieldFilling.rect_position.y = 1 + maxFilling
	
	
	var sy = (pxFromCharges + pxFromShieldStrength) / 6.0
	var rest = sy - floor(sy)
	if sy - floor(sy) < 0.2:
		sy = floor(sy)
		rest = 0
	else:
		sy = ceil(sy)
	size.y = sy
	
	$Bar.rect_position.y = pxFromCharges + 1 + rest * 1.5
	
	emit_signal("request_rebuild")

func updateSlots(amount: int):
	for i in range(1, 4):
		get_node("Slot" + str(i)).visible = amount >= i
	match int(amount):
		1:
			pxFromCharges = 5
		2:
			pxFromCharges = 8
		3:
			pxFromCharges = 11
	
	setStage(stage)

func updateCharges(charges):
	for i in range(1, 4):
		find_node("Charge" + str(i)).visible = charges >= i
