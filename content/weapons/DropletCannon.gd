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
			var bullet = preload("res://content/cannon/Droplet.tscn").instance()

			bullet.rotation = rotation
			bullet.position = position
			get_parent().add_child(bullet)
			bullet.apply_central_impulse(Vector2(0, - 100).rotated(rotation))
			fireCoolDown = 0.05
			$Tween.interpolate_callback(bullet, 3.0, "kill")
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
