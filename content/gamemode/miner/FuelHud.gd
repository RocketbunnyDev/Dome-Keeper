extends HudElement

var refueling: = false

func init():
	Data.listen(self, "keeper.fuel")
	Data.listen(self, "keeper.insidedome")
	Data.listen(self, "keeper.domefuel")
	Data.apply("keeper.fuel", Data.of("keeper.maxfuel"))

func propertyChanged(property: String, oldValue, newValue):
	match property:
		
		"keeper.fuel":
			updateFuelmeter()
			if newValue <= 0.0:
				Data.apply("keeper.speedlimit", 30)
			else:
				Data.apply("keeper.speedlimit", - 1)
		"keeper.insidedome":
			if newValue:
				refueling = true
			else:
				refueling = false
		"keeper.domefuel":
			if oldValue != null and newValue > oldValue:
				refueling = true

func _process(delta):
	if GameWorld.softPaused():
		return 
	var keeperMove = Level.keeper.moveDirectionInput.length()
	var newFuel = max(0.0, Data.of("keeper.fuel") - keeperMove * delta * 0.2)
	Data.apply("keeper.fuel", newFuel)
	
	if refueling:
		var available = min(1.0, Data.of("keeper.domefuel"))
		var refuelAmount = 2 * delta * min(available, max(0.0, Data.of("keeper.maxfuel") - Data.of("keeper.fuel")))
		if refuelAmount != 0:
			Data.changeByInt("keeper.fuel", refuelAmount)
			Data.changeByInt("keeper.domefuel", - refuelAmount)

func updateFuelmeter():
	$ColorRect2.rect_size.y = 30 * Data.of("keeper.fuel") / Data.of("keeper.maxfuel")
