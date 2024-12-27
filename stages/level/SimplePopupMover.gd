extends Container

var isIn: = false

func _ready():
	rect_position.y += rect_size.y

func moveIn(moveOutAfter: = 0.0):
	if isIn:
		return 
	
	visible = true
	isIn = true
	if moveOutAfter > 0.0:
		$Tween.interpolate_callback(self, moveOutAfter, "moveOut")
		
	$Tween.interpolate_property(self, "rect_position:y", rect_position.y, get_viewport_rect().size.y - rect_size.y, 0.3, Tween.TRANS_CUBIC, Tween.EASE_OUT, 2.0)
	$Tween.start()
	
func moveOut():
	if not isIn:
		return 
	
	isIn = false
	$Tween.interpolate_property(self, "rect_position:y", rect_position.y, get_viewport_rect().size.y, 0.3, Tween.TRANS_CUBIC, Tween.EASE_IN)
	$Tween.interpolate_callback(self, 0.5, "queue_free")
	$Tween.start()
