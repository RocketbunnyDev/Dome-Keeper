extends "res://content/monster/Monster.gd"

var goalPos: Vector2
var variant: String
var path: Path2D
var progress
var speed: float
var delay: = 0.2

func start(side: String, path: Path2D):
	self.variant = side
	self.path = path
	$Sprite.play(side)
	progress = rand_range(150, 250)
	self.goalPos = path.curve.interpolate_baked(progress) + path.global_position + Vector2(0, - 10)
	speed = Data.of("scarabarm.speed") * rand_range(0.85, 1.15)

func _physics_process(delta):
	if GameWorld.paused:
		return 
	
	if delay > 0.0:
		delay -= delta
		return 
	
	var d = goalPos - position
	if d.length() < 3.0:
		grow()


		InputSystem.getCamera().shake(80, 0.2, 8)
		set_physics_process(false)
		rotation = 0
		position += Vector2( - 5, - 5)
		$ImpactSound.play()
	else:
		var angle = d.angle()
		if angle > 0:
			rotation = d.angle() + PI * 1.6
		else:
			rotation = d.angle() - PI * 1.6
		position += (d.normalized() * delta * speed).clamped(d.length())

func grow():
	$Sprite.play("grow")
	$GrowAndBurstSound.play()

func _on_Sprite_frame_changed():
	if $Sprite.animation == "grow" and $Sprite.frame == 13:
		var walker = preload("res://content/monster/mucker/Mucker.tscn").instance()
		walker.path = path
		Level.world.assignPathOccupation(Data.of("mucker.movetype"), path, walker)
		walker.meleeTarget = Level.dome.getMeleeTarget(variant)
		walker.progress = progress
		Level.monsters.registerMonster(walker)
		emit_signal("died")

func _on_Sprite_animation_finished():
	if $Sprite.animation == "grow":
		queue_free()
