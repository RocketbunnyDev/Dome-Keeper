extends PathFollow2D

var move: Vector2
var speed: = 0.25
var dps: = 10
var fireCoolDown: = 0.0

func _ready():
	unit_offset = 0.5

func move(dir: Vector2):
	move = dir
	if dir.y < 0:
		if fireCoolDown <= 0:
			var bullet = preload("res://content/weapons/Bullet.tscn").instance()
			bullet.connect("area_entered", self, "bulletHit", [bullet])
			bullet.rotation = rotation
			bullet.position = position + 5 * Vector2.UP.rotated(rotation)
			get_parent().add_child(bullet)
			fireCoolDown = 0.65
			$Tween.interpolate_callback(bullet, 1.0, "queue_free")
			$Tween.start()

func bulletHit(area, bullet):
	area.hit(dps)
	bullet.queue_free()

func _process(delta):
	if fireCoolDown > 0.0:
		fireCoolDown -= delta
	
	if move.x == 0:
		$MoveSound.stop()
	elif not $MoveSound.playing:
		$MoveSound.play()
	unit_offset = clamp(unit_offset + delta * move.x * speed, 0.001, 0.99)

func start():
	$Sprite.play("out")

func stop():
	$Sprite.play("in")
