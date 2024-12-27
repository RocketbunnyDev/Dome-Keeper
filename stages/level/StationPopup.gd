extends Container

export (int) var basePos: = 0
var isIn: = false
var outLeft: = false
var outRight: = false


var tween2: Tween

func _ready():
	if basePos == 0:
		rect_position.y += rect_size.y
	elif basePos == - 1:
		rect_position.x = - rect_size.x
	elif basePos == 1:
		rect_position.x = get_viewport_rect().size.x + rect_size.x
	Options.setActionIcons(self)
	tween2 = Tween.new()
	add_child(tween2)

func moveIn(delay: = false):
	if isIn:
		return 
	
	isIn = true
	tween2.stop_all()
	tween2.remove_all()
	var s = get_viewport_rect().size
	$Tween.interpolate_property(self, "rect_position", rect_position, Vector2(s.x * anchor_left - rect_size.x * 0.5, s.y - rect_size.y), 0.3, Tween.TRANS_CUBIC, Tween.EASE_OUT, 0.3 if delay else 0.0)
	$Tween.start()
	
func moveOut(dir: = 0):
	if not isIn:
		return 
	
	isIn = false
	$Tween.stop_all()
	$Tween.remove_all()
	var s = get_viewport_rect().size
	if dir == 0:
		tween2.interpolate_property(self, "rect_position:y", rect_position.y, s.y, 0.3, Tween.TRANS_CUBIC, Tween.EASE_IN)
	elif dir == - 1:
		tween2.interpolate_property(self, "rect_position:x", rect_position.x, - rect_size.x, 0.45, Tween.TRANS_CUBIC, Tween.EASE_IN)
	elif dir == 1:
		tween2.interpolate_property(self, "rect_position:x", rect_position.x, s.x, 0.45, Tween.TRANS_CUBIC, Tween.EASE_IN)
	
	tween2.start()
