extends CenterContainer

signal proceed

var isIn: = false
var backgroundHide

func _ready():
	Style.init(self)
	
	var sb = find_node("StartButton")
	sb.connect("pressed", self, "emit_signal", ["proceed"])

func moveIn():
	if isIn:
		return 
	
	InputSystem.grabFocus(find_node("StartButton"))
	
	isIn = true
	$Tween.stop_all()
	$Tween.remove_all()
	
	$Tween.interpolate_property(backgroundHide, "modulate:a", 0.0, 1.0, 0.3)
	$Tween.interpolate_property(self, "rect_position:y", rect_position.y, get_viewport_rect().size.y * 0.5 - rect_size.y * 0.5, 0.6, Tween.TRANS_CUBIC, Tween.EASE_OUT)
	$Tween.start()
	
func moveOut():
	if not isIn or not is_inside_tree():
		return 
	
	isIn = false
	$Tween.stop_all()
	$Tween.remove_all()
	$Tween.interpolate_property(backgroundHide, "modulate:a", 1.0, 0.0, 0.3)
	$Tween.interpolate_property(self, "rect_position:y", rect_position.y, get_viewport_rect().size.y, 0.3, Tween.TRANS_CUBIC, Tween.EASE_IN)
	$Tween.start()
