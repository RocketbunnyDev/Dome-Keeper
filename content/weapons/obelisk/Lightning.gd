extends Node2D


var blockers: = 1



func init():
	$Lightning.visible = true
	$Lightning.connect("animation_finished", self, "decrement_blockers")
	$Lightning.play()
		
	Style.init(self)

func decrement_blockers():
	blockers -= 1
	if blockers <= 0:
		queue_free()

