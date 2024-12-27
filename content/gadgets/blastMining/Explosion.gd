extends AnimatedSprite

var fin: = 0

func _ready():
	playing = true
	$Bang.play()
	if Level.keeper:
		var d = Level.keeper.global_position - global_position
		InputSystem.getCamera().shake(max(0, 200 - d.length()), 0.5, 8)
	Style.init(self)

func finished():
	fin += 1
	if fin == 2:
		queue_free()
