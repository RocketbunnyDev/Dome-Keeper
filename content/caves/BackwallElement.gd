extends Node2D

export (Vector2) var size: = Vector2(1, 1)
var coord: Vector2
var tilesToGo: int
var texture: Texture

func _ready():
	if texture:
		$Background.texture = texture

func place(coord: Vector2):
	self.coord = coord
	tilesToGo = size.x * size.y
	hide()

func tileDestroyed(tileCoord: Vector2):
	tilesToGo -= 1
	if tilesToGo <= 0:
		if size.x * size.y <= 2:
			
			var start = Color(1, 1, 1, 0)
			var end = Color(1, 1, 1, 1)
			var duration = 0.5
			var t = Tween.new()
			add_child(t)
			t.interpolate_property(self, "modulate", start, end, duration, Tween.TRANS_CUBIC, Tween.EASE_IN)
			t.interpolate_callback(t, duration, "queue_free")
			t.start()
			show()
		else:
			
			var v = VisibilityNotifier2D.new()
			add_child(v)
			v.connect("screen_exited", self, "show")
			v.connect("screen_exited", v, "queue_free")
