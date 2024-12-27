extends Node2D

signal on_show

var center: Vector2
var sound
var tileCoord: Vector2

func _ready():
	hide()
	$Sprite.speed_scale = max(0.1, 5.0 / Data.of("probe.markerRetention"))
	var distance = position.distance_to(center)
	$Timer.wait_time = distance / Data.of("probe.impulseSpeed")
	$Timer.start()
	
	Level.map.addTileRevealedListener(self, tileCoord)
	
	Style.init($Sprite)

func _on_Timer_timeout():
	if visible:
		remove()
	else:
		show()
		$Sprite.play("ping")
		if sound:
			sound.play()
		$Timer.wait_time = Data.of("probe.markerRetention")
		$Timer.start()

func refresh():
	$Timer.start(0)

func remove():
	Level.map.removeTileRevealedListener(self, tileCoord)
	queue_free()

func tileRevealed(tileCoord: Vector2):
	remove()
