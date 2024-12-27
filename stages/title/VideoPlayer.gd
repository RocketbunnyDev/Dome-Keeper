extends VideoPlayer

func _ready():
	visible = false

func start():
	modulate.a = 0
	visible = true
	$Tween.remove_all()
	$Tween.interpolate_property(self, "modulate:a", 0.0, 1.0, 0.4)
	$Tween.start()
	play()

func stop():
	.stop()
	$Tween.remove_all()
	$Tween.interpolate_property(self, "modulate:a", modulate.a, 0.0, 0.4)
	$Tween.interpolate_callback(self, 0.4, "set", "visible", "false")
	$Tween.start()
