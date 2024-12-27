extends Node2D

enum State{HIDE, GROW, IDLE, WALK, DIE}
var state: int = State.GROW

var cooldown: = 0.0
var walktime: = 0.0

func _ready():
	Style.init(self)

func start(startTile):
	$Tween.interpolate_callback(self, 60 + 60 * randf(), "die")
	$Tween.start()

func _physics_process(delta):
	if not $GroundDetector.is_colliding():
		die()
		return 
	
	if shouldShrink():
		shrink()
	
	if cooldown > 0.0:
		cooldown -= delta
		return 
	
	match state:
		State.HIDE:
			var distanceToKeeper = global_position - Level.keeper.global_position
			if distanceToKeeper.length() > GameWorld.TILE_SIZE * 4.5:
				state = State.GROW
			cooldown = 1.0
		State.GROW:
			$Sprite.play("grow")
			cooldown = 1.0
			state = State.IDLE
		State.WALK:
			if not $Sprite.animation.begins_with("walk_"):
				$Sprite.play("walk_left" if $EdgeDetector.position.x < 0 else "walk_right")
			if $EdgeDetector.is_colliding() and not $WallDetector.is_colliding():
				position.x += $EdgeDetector.position.x * delta * 5
				walktime += delta
				if walktime > 2.0 and randf() > 0.9:
					state = State.IDLE
					$Sprite.play("idle")
			else:
				state = State.IDLE
				$Sprite.play("idle")
		State.IDLE:
			cooldown = 1.5 + randf() * 3.0
			if randf() > 0.5:
				flip()
			state = State.WALK
			walktime = 0.0

func shouldShrink():
	var distanceToKeeper = global_position - Level.keeper.global_position
	return distanceToKeeper.length() < GameWorld.TILE_SIZE * 2.4

func shrink():
	if state != State.HIDE:
		state = State.HIDE
		$Sprite.play("shrink")

func flip():
	$EdgeDetector.position.x = - $EdgeDetector.position.x
	$WallDetector.rotation += PI

func _on_Sprite_animation_finished():
	$Sprite.speed_scale = 1.0
	match $Sprite.animation:
		"shrink":
			if state == State.DIE:
				queue_free()
			else:
				animateShrunken()
		"hidden":
			animateShrunken()
		"twinkle":
			animateShrunken()
		"grow":
			$Sprite.play("idle")

func animateShrunken():
	var distanceToKeeper = global_position - Level.keeper.global_position
	if distanceToKeeper.length() > GameWorld.TILE_SIZE * 2:
		$Sprite.play("twinkle")
		$Sprite.speed_scale = 0.5 + 0.5 * randf()
	else:
		$Sprite.play("hidden")

func die():
	if state != State.DIE:
		state = State.DIE
		$Sprite.play("shrink")
