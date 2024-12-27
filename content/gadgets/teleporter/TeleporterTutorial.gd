extends Tutorial

var lastKnownPos = null

func _ready():
	lastKnownPos = Level.keeper.global_position

func process_trigger(delta: float)->bool:
	return Data.of("keeper.insidedome") and not Data.of("keeper.insidestation")

func process_confirm(delta: float):
	if not lastKnownPos:
		lastKnownPos = Level.keeper.global_position
	var d = (Level.keeper.global_position - lastKnownPos).length()
	if d > 50.0:
		confirm()
	lastKnownPos = Level.keeper.global_position
