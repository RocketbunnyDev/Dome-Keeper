extends Node2D

enum State{SEARCH, EAT, SCATTER, DIEING}
var state: int = State.SEARCH
var target = null
var target_position: Vector2
var target_origin: Vector2
var starting_position: Vector2
var scared: = false
var tween: Tween = Tween.new()

const MIN_DISTANCE_FROM_KEEPER = 50
const SCATTER_SPEED = 50
const SEARCH_SPEED = 10

var direction: Vector2

func _ready():
	scale = Vector2(0.1, 0.1)
	
	add_child(tween)
	tween.interpolate_property(self, "scale", scale, Vector2(1, 1), 0.5, Tween.TRANS_CUBIC)
	tween.start()
	
	change_state(State.SEARCH)
	
	$deathTimer.wait_time = rand_range(10, 20)
	$deathTimer.start()
	
	Style.init(self)

func goto(t):
	starting_position = global_position
	if is_instance_valid(t):
		target = t
		target_position = target.global_position + Vector2(rand_range(0, 5), 0).rotated(randf() * TAU)
		target_origin = target.global_position
	
func die():
	if state != State.DIEING:
		state = State.DIEING
		tween.interpolate_property(self, "scale", scale, Vector2(0.0, 0.0), 0.2, Tween.TRANS_CUBIC)
		tween.interpolate_callback(self, 0.25, "queue_free")
		tween.start()

func _on_deathTimer_timeout():
	change_state(State.SCATTER)

func _physics_process(delta):
	var distance_to_keeper = Level.keeper.global_position.distance_to(global_position)
	
	if is_instance_valid(target):
		var current_origin = target_origin
		target_position = target.global_position + Vector2(rand_range(0, 5), 0).rotated(randf() * TAU)
		target_origin = target.global_position
		if current_origin.distance_to(target_origin) > 1:
			change_state(State.SCATTER)
	else:
		change_state(State.SCATTER)
	
	match state:
		State.SEARCH:
			if not is_instance_valid(target):
				die()

			direction = (target_position - global_position).rotated(rand_range( - 0.05, 0.05))
			global_position += direction.normalized() * SEARCH_SPEED * delta
			global_rotation = direction.angle()
			
			
			if global_position.distance_to(target_position) < 5:
				change_state(State.EAT)
				
			if distance_to_keeper < MIN_DISTANCE_FROM_KEEPER:
				scared = true
				change_state(State.SCATTER)
		
		State.EAT:
			direction += Vector2(5, 0).rotated(randf() * TAU * 2) * delta
			if global_position.distance_to(target_position) > 5:
				direction = lerp(direction, (target_position - global_position).rotated(rand_range( - 0.1, 0.1)), delta * 5)
			global_position += direction.normalized() * SEARCH_SPEED * delta * 0.5
			global_rotation = direction.angle()
			if distance_to_keeper < MIN_DISTANCE_FROM_KEEPER:
				scared = true
				change_state(State.SCATTER)
		
		State.SCATTER:
			direction = (starting_position - global_position).rotated(rand_range( - 0.1, 0.1))
			var speed = SCATTER_SPEED if scared else SEARCH_SPEED * 2
			global_position += direction.normalized() * speed * delta
			global_rotation = direction.angle()
			if global_position.distance_to(starting_position) < 5:
				die()

func change_state(new_state: int):
	if randf() < 0.3:
		$Nibble.play()
		
	state = new_state
	match state:
		State.SEARCH:
			
			$AnimatedSprite.play("crawl")
			
		State.EAT:
			
			$AnimatedSprite.play("eat")
			
		State.SCATTER:
			$AnimatedSprite.play("crawl")
			$AnimatedSprite.speed_scale = 3.0
