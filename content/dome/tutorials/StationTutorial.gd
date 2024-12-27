extends Tutorial

func _ready():
	listen("keeper.insidestation")
	listen("monsters.wavepresent")
	
	splitTutorialText("level.tutorial.station.popup_2", "Label1", "Label2")
	splitTutorialText("level.tutorial.station.popup_4", "Label3", "Label4")

func propertyChanged(property: String, oldValue, newValue):
	match property:
		"keeper.insidestation":
			if newValue:
				confirm()
		"monsters.wavepresent":
			if newValue:
				trigger()

func process_trigger(delta: float)->bool:
	return Data.of("monsters.wavepresent")

func beforeMoveIn():
	find_node("Station").texture = load("res://content/dome/" + Level.domeId() + "/station/single.png")
	find_node("Station").rect_min_size = find_node("Station").texture.get_size() * 2
