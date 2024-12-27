extends HudElement

enum State{EMPTY, GROWING, READY, CONSUMING}

const PLANT_SIZE: = 14.0
const PLANT_POSY: = - 7

var buffed: bool
var buffDuration: float
var maxBuffDuration: float
var growth: float
var currentState = - 1

onready var PlantGrowing = $Background / PlantGrowing
onready var PlantEating = $Background / PlantEating

func init():
	Data.listen(self, "orchard.remainingbuffduration", true)
	Data.listen(self, "orchard.currentgrowth", true)
	Data.listen(self, "orchard.battleabilityuses", true)
	Data.listen(self, "orchard.remainingbattleuses", true)
	update()

func propertyChanged(property: String, oldValue, newValue):
	match property:
		"orchard.battleabilityuses":
			if oldValue != newValue and newValue == 1:
				$Slot1.visible = true
				size.y += 1
				$Background.position.y += 5
				emit_signal("request_rebuild")
			else:
				$Slot1.visible = false
		"orchard.remainingbattleuses":
			$Slot1 / Charge1.visible = newValue == 1
		"orchard.currentgrowth":
			growth = newValue
		"orchard.remainingbuffduration":
			buffed = newValue > 0.0
			if buffDuration < newValue:
				maxBuffDuration = newValue
			buffDuration = newValue
	update()

func update():
	var state: = - 1
	if buffed:
		state = State.CONSUMING
	else:
		if growth > 0.0:
			if growth >= 1.0:
				state = State.READY
			else:
				state = State.GROWING
		else:
			state = State.EMPTY
			
	
	if state != currentState:
		match state:
			State.EMPTY:
				PlantEating.visible = false
				PlantGrowing.visible = false
				$Background.play("empty")
			State.GROWING:
				$Background.play("producing")
				PlantGrowing.visible = true
				PlantEating.visible = false
				PlantGrowing.position.y = PLANT_POSY
				PlantGrowing.region_rect.position.y = 0
				PlantGrowing.region_rect.size.y = PLANT_SIZE
			State.READY:
				$Background.play("ready")
				PlantGrowing.visible = true
				PlantEating.visible = false
				PlantGrowing.position.y = PLANT_POSY
				PlantGrowing.region_rect.position.y = 0
				PlantGrowing.region_rect.size.y = PLANT_SIZE
			State.CONSUMING:
				$Background.play("consuming")
				PlantGrowing.visible = false
				PlantEating.visible = true
				PlantEating.position.y = PLANT_POSY
				PlantEating.region_rect.position.y = 0
				PlantEating.region_rect.size.y = PLANT_SIZE
	
	currentState = state
	
	match currentState:
		State.GROWING:
			var rel = PLANT_SIZE * growth
			PlantGrowing.region_rect.size.y = rel
			PlantGrowing.region_rect.position.y = PLANT_SIZE - rel
			PlantGrowing.position.y = PLANT_POSY + PlantGrowing.region_rect.position.y
		State.CONSUMING:
			var rel = PLANT_SIZE * buffDuration / maxBuffDuration
			PlantEating.region_rect.size.y = rel
			PlantEating.region_rect.position.y = PLANT_SIZE - rel
			PlantEating.position.y = PLANT_POSY + PlantEating.region_rect.position.y
	

