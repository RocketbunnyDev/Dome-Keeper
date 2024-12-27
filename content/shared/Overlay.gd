extends ColorRect

var tween: Tween

func _ready():
	tween = Tween.new()
	add_child(tween)
	visible = false

func showOverlay():
	color = Style.OVERLAY_COLOR_OUT
	visible = true
	tween.interpolate_property(self, "color", color, Style.OVERLAY_COLOR_IN, 0.3)
	tween.start()

func hideOverlay():
	color = Style.OVERLAY_COLOR_IN
	tween.interpolate_property(self, "color", color, Style.OVERLAY_COLOR_OUT, 0.3)
	tween.interpolate_callback(self, 0.3, "set", "visible", false)
	tween.start()
