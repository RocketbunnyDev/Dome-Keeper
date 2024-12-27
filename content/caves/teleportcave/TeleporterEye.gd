extends Node2D

func _ready():
	Style.init($Sprite)
	$Sprite.playing = true
	$PlacedSound.play()

func onUsed():
	$Tween.interpolate_property($Sprite, "scale", $Sprite.scale, Vector2.ZERO, 1.0, Tween.TRANS_QUAD)
	$Tween.interpolate_callback(self, 1.0, "queue_free")
	$Tween.start()

func serialize()->Dictionary:
	var data = {}
	data["meta.priority"] = 200
	data["meta.kind"] = "generic"
	return data
	
func deserialize(data: Dictionary):
	pass
