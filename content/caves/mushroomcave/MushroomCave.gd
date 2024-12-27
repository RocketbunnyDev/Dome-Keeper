extends "res://content/caves/Cave.gd"

var hasMushroom: = true
var timeUntilNewMushroom: = 0.0
var remainingBuffDuration: = 0.0

const speedBuffAmount: = 45.0





func _ready():
	Style.init(find_node("FocusMarker"))
	Level.map.addSpriteToBGAlpha($AlphaMap)

func serialize()->Dictionary:
	var data = .serialize()
	data["hasMushroom"] = hasMushroom
	data["timeUntilNewMushroom"] = timeUntilNewMushroom
	data["remainingBuffDuration"] = remainingBuffDuration
	return data
	
func deserialize(data: Dictionary):
	.deserialize(data)
	hasMushroom = data["hasMushroom"]
	timeUntilNewMushroom = data["timeUntilNewMushroom"]
	remainingBuffDuration = data["remainingBuffDuration"]
	if not hasMushroom:
		find_node("Mushroom").visible = false
	if currentState == State.REVEALED:
		find_node("AmbSound").play()
	
func _process(delta):
	if GameWorld.softPaused():
		return 
	
	if timeUntilNewMushroom > 0.0:
		timeUntilNewMushroom -= delta
		if timeUntilNewMushroom <= 0.0:
			hasMushroom = true
			find_node("Mushroom").visible = true
	
	if remainingBuffDuration > 0.0:
		remainingBuffDuration -= delta
		if remainingBuffDuration <= 0.0:
			Data.changeByInt("keeper.speedbuff", - speedBuffAmount)



func onRevealed():
	find_node("AmbSound").play()

func canFocusUse()->bool:
	return hasMushroom

func useHold(keeper: Keeper):
	return useHit(keeper)

func useHit(keeper: Keeper)->bool:
	if not hasMushroom:
		return false
	
	$MushroomConsumedSound.play()
	find_node("Mushroom").visible = false
	hasMushroom = false
	Data.changeByInt("keeper.speedbuff", speedBuffAmount)


	var cycleTime = GameWorld.getTimeBetweenWaves()
	remainingBuffDuration = cycleTime * 0.6
	timeUntilNewMushroom = cycleTime * 2.0
	return true
