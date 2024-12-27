extends Container

class_name Tutorial

export (bool) var isFullscreen: = false

var id: String
var tutorialParent

var isIn: = false
var isOut: = false

var triggered: = false
var confirmed: = false

export (float) var moveOutAfter: = 30.0
const moveTime: = 0.3
export (float) var moveInDelay: = 2.0
export (float) var listeningDelay: = 0.0
export (bool) var triggerDuringWave: = false
export (float) var minTimeToWave: = 20.0

const introDelay: = 1.0

var listeningTo: = []

var tween

func _ready():
	tween = Tween.new()
	add_child(tween)
	grow_horizontal = Control.GROW_DIRECTION_BEGIN
	grow_vertical = Control.GROW_DIRECTION_END
	rect_position.y = get_viewport_rect().size.y
	Options.setActionIcons(self)
	
	add_to_group("pauseL")
	visible = false
	
	Style.init(self)

func process_trigger(delta: float)->bool:
	return triggered

func process_confirm(delta: float):
	pass

func listen(property: String, immediateCallback: = false):
	Data.listen(self, property, immediateCallback)
	listeningTo.append(property)

func unlisten(property: String):
	Data.unlisten(self, property)
	listeningTo.erase(property)

func moveIn():
	if isIn or isOut:
		return 
	
	beforeMoveIn()
	
	visible = true
	isIn = true
	
	tween.stop_all()
	tween.remove_all()
	
	tween.interpolate_callback(self, moveTime + moveInDelay, "onMovedIn")
	tween.interpolate_callback(Audio, moveTime * 0.65 + moveInDelay, "sound", "gui_tutorial_in")
	
	if isFullscreen:
		moveInFullscreen()
		if not Options.useGamepad:
			GameWorld.setShowMouse(true)
	else:
		moveInSide()

func onMovedIn():
	pass

func moveInSide():
	var inGoal = 1080 - rect_size.y
	tween.interpolate_property(self, "rect_position:y", rect_position.y, inGoal, moveTime, Tween.TRANS_CUBIC, Tween.EASE_OUT, moveInDelay)
	tween.start()

var popupInput
func moveInFullscreen():
	var inGoal = (1080 - rect_size.y) * 0.5
	
	rect_position.x = (rect_size.x - get_viewport_rect().size.x) * 0.5
	tween.interpolate_property(self, "rect_position:y", rect_position.y, inGoal, moveTime, Tween.TRANS_CUBIC, Tween.EASE_OUT, moveInDelay)
	tween.start()

	Level.stage.pause(true)

func moveOut():
	if isOut:
		return 
	
	for p in listeningTo:
		Data.unlisten(self, p)
	
	tween.stop_all()
	tween.remove_all()
	
	isOut = true
	var outGoal = get_viewport_rect().size.y
	tween.interpolate_property(self, "rect_position:y", rect_position.y, outGoal, moveTime, Tween.TRANS_CUBIC, Tween.EASE_IN)
	tween.interpolate_callback(self, moveTime + 0.2, "queue_free")
	tween.start()
	
	if isFullscreen:
		Level.stage.unpause()
		GameWorld.setShowMouse(false)
		popupInput.desintegrate()

func beforeMoveIn():
	pass

func pauseChanged():
	if isFullscreen:
		
		return 
	
	if GameWorld.paused:
		tween.stop_all()
	else:
		tween.resume_all()

func confirm():
	confirmed = true

func trigger():
	triggered = true

func splitTutorialText(id, label1, label2):
	var s = tr(id)
	var parts = s.split("|")
	if parts.size() != 2:
		Logger.error("tutorial string is not formatted as expected", name + ".splitTutorialText", s)
		return 
	find_node(label1).text = parts[0]
	find_node(label2).text = parts[1]
