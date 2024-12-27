extends Node2D

var rechargeTimer: float
var timeToRechargeFully: float

func _ready():
	Level.addTutorial(self, "probe")

func serialize()->Dictionary:
	var data = {
		"rechargeTimer": rechargeTimer, 
		"timeToRechargeFully": timeToRechargeFully
	}
	data["meta.priority"] = 200
	data["meta.kind"] = "station"
	return data

func deserialize(data: Dictionary):
	rechargeTimer = data["rechargeTimer"]
	timeToRechargeFully = data["timeToRechargeFully"]
	
func _process(delta):
	if timeToRechargeFully == 0.0:
		return 
	
	var maxCharges = Data.of("probe.charges")
	var chargesRemaining = Data.of("probe.chargesRemaining")
	if chargesRemaining >= maxCharges:
		return 
	
	rechargeTimer += delta
	if rechargeTimer >= timeToRechargeFully / maxCharges:
		Data.apply("probe.chargesRemaining", chargesRemaining + 1)
		rechargeTimer = 0
		
func executeSpecial1()->bool:
	if Data.of("keeper.insidedome") or GameWorld.paused:
		return false

	var chargesRemaining = Data.of("probe.chargesRemaining")
	if chargesRemaining > 0:
		Data.apply("probe.chargesRemaining", chargesRemaining - 1)
		var probe = load("res://content/gadgets/probe/ProbeImpulse.tscn").instance()
		probe.position = global_position
		Level.map.addTileOverlay(probe)
		timeToRechargeFully = GameWorld.getTimeBetweenWaves() * Data.of("probe.rechargetime")
		return true
	else:
		return false
		
