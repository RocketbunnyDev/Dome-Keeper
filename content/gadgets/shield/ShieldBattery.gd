extends Node2D

var stage: int
var fillingHeight: int

var currentFilling: float
var goalFilling: float
var offY: = 0

var maxCharge: float

func _ready():
	Data.listen(self, "shield.stage", true)
	Data.listen(self, "shield.maxstrength", true)
	Data.apply("shield.overcharged", false)
	Data.listen(self, "shield.overcharged")
	







			
	
	Style.init(self)
	$Overcharge.visible = false

func serialize()->Dictionary:
	var data = {}
	data["meta.priority"] = 200
	data["meta.kind"] = "station"
	data["stage"] = stage
	data["fillingHeight"] = fillingHeight
	data["currentFilling"] = currentFilling
	data["goalFilling"] = goalFilling
	data["offY"] = offY
	data["maxCharge"] = maxCharge
	return data

func deserialize(data: Dictionary):
	stage = data["stage"]
	fillingHeight = data["fillingHeight"]
	currentFilling = data["currentFilling"]
	goalFilling = data["goalFilling"]
	offY = data["offY"]
	maxCharge = data["maxCharge"]
	
	setStage(stage)

func propertyChanged(property: String, oldValue, newValue):
	match property:
		"shield.maxstrength":
			maxCharge = newValue
		"shield.stage":
			setStage(newValue)
		"shield.overcharged":
			$Overcharge.visible = newValue
			if newValue:
				$OverchargeAmbienceSound.play()
			else:
				$OverchargeAmbienceSound.stop()

func _process(delta: float)->void :
	var currentShieldStrength = Data.of("shield.strength")
	var maxShieldStrength = Data.of("shield.maxStrength")
	
	var filling: float = currentShieldStrength / maxShieldStrength
	var d = filling - currentFilling
	currentFilling = clamp(currentFilling + sign(d) * delta * 0.5, 0.0, 1.0)
	
	var pixel = round(currentFilling * fillingHeight)
	$Clipper.rect_size.y = pixel
	$Clipper.rect_position.y = - pixel + offY
	$Clipper / Filling.position.y = - 14 + pixel
	
func setStage(stage: int):
	self.stage = stage
	if stage == 4:
		
		stage = 3
	
	$Background.frame = stage - 1
	$Clipper / Filling.frame = 3 + (stage - 1)
	$Overcharge.play(str(stage))
	match int(stage):
		1:
			fillingHeight = 9
			offY = 1
		2:
			fillingHeight = 12
			offY = 1
		3:
			fillingHeight = 20
			offY = 1

func canFocusUse()->bool:
	return canOvercharge()

func useHold(keeper: Keeper):
	return false

func useHit(keeper: Keeper)->bool:
	if Data.of("inventory.water") <= 0:
		$NoOverchargeSound.play()
		return false
	else:
		overcharge()
		return true

func overcharge():
	$OverchargeSound.play()
	Data.apply("shield.overcharged", true)
	Data.changeByInt("inventory.water", - 1)
	Backend.event("gadget_overcharged", {"gadget": "shield"})

func canOvercharge()->bool:
	return not Data.of("shield.overcharged") and Data.of("shield.overchargestrength") > 0
