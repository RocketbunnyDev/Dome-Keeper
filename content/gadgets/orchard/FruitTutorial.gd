extends Tutorial

func _ready():
	listen("orchard.remainingbuffduration")
	splitTutorialText("level.tutorial.fruit.popup_2", "Label1", "Label2")

func beforeMoveIn():
	find_node("OrchardImage").texture = load("res://content/gadgets/orchard/" + Level.domeId() + "/orchard_tutpic.png")
	find_node("OrchardImage").rect_min_size = find_node("OrchardImage").texture.get_size() * 2

func propertyChanged(property: String, oldValue, newValue):
	match property:
		
		"orchard.remainingbuffduration":
			if newValue > 0.0:
				confirm()

func process_trigger(delta: float)->bool:
	return Data.of("keeper.insidedome") and not Data.of("keeper.insidestation") and Data.of("orchard.currentgrowth") >= 1.0
