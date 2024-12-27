extends RigidBody2D

enum State{SEARCH, EAT, SCATTER}
var state: int = State.SEARCH
var tween: Tween = Tween.new()

const MIN_DISTANCE_FROM_KEEPER = 50
const MOVE_SPEED = 30

var direction: Vector2
var tile_normal: Vector2
var wall_normal: Vector2
var touching_wall = false
var touching_floor = false

func _ready():
	add_child(tween)
	Style.init(self)
	$deathTimer.wait_time = rand_range(40, 120)
	$deathTimer.start()
	$AnimatedSprite.play("appear")

func die():
	gravity_scale = 0
	$AnimatedSprite.play("disappear")

func _on_deathTimer_timeout():
	change_state(State.SCATTER)




	
func _physics_process(delta):
	var distance_to_keeper = Level.keeper.global_position.distance_to(global_position)
	var facing = Vector2.ZERO
	facing = linear_velocity if linear_velocity.length() > 1 else Vector2.ZERO
	if facing.length():
		$AnimatedSprite.global_rotation = 0
		$AnimatedSprite.flip_v = false
		$AnimatedSprite.flip_h = false
		
		if facing.x < 0:
			
			$AnimatedSprite.global_rotation = 0
			$AnimatedSprite.flip_v = false
			$AnimatedSprite.flip_h = true
		
		if facing.x >= 0:
			
			$AnimatedSprite.global_rotation = 0
			$AnimatedSprite.flip_v = false
			$AnimatedSprite.flip_h = false
			
		if facing.y <= 0:
			
			if wall_normal.x > 0:
				
				$AnimatedSprite.global_rotation = - PI / 2
				$AnimatedSprite.flip_v = false
				$AnimatedSprite.flip_h = false
			elif wall_normal.x < 0:
				
				$AnimatedSprite.global_rotation = - PI / 2
				$AnimatedSprite.flip_v = true
				$AnimatedSprite.flip_h = false

		if facing.y > 0:
			
			if wall_normal.x > 0:
				
				$AnimatedSprite.global_rotation = - PI / 2
				$AnimatedSprite.flip_v = false
				$AnimatedSprite.flip_h = true
			elif wall_normal.x < 0:
				
				$AnimatedSprite.global_rotation = - PI / 2
				$AnimatedSprite.flip_v = true
				$AnimatedSprite.flip_h = true

	
	if state != State.SCATTER:
		if linear_velocity.length() < 0.1:
			$AnimatedSprite.play("idle")
		else:
			$AnimatedSprite.play("crawl")
		
	match state:
		State.SEARCH:
			if linear_velocity.length() < rand_range(5, 20):
				apply_central_impulse(direction * MOVE_SPEED)
			if touching_wall and distance_to_keeper < MIN_DISTANCE_FROM_KEEPER:
				change_state(State.SCATTER)
		
		State.EAT:
			if touching_wall and distance_to_keeper < MIN_DISTANCE_FROM_KEEPER:
				change_state(State.SCATTER)
		
		State.SCATTER:
			if not $VisibilityNotifier2D.is_on_screen():
				queue_free()
			if touching_wall and linear_velocity.length() < 1:
				die()

func _on_decisionTimer_timeout():
	if state == State.SCATTER:
		return 
	
	change_state(State.SEARCH)
	if wall_normal.y > 0 or tile_normal.y > 0:
		
		if randf() < 0.2:
			change_state(State.EAT)
		elif randf() < 0.5:
			direction = Vector2(1, 0)
		else:
			direction = Vector2( - 1, 0)
	elif wall_normal.y < 0:
		
		direction = Vector2(0, 1)
	else:
		
		direction = Vector2(0, - 1)
		
func _integrate_forces(state):
	
	if state.get_contact_count():
		for i in range(state.get_contact_count()):
			tile_normal = - state.get_contact_local_normal(i)
			if abs(tile_normal.y) == 0:
				break
	else:
		if tile_normal.length():
			apply_central_impulse((tile_normal + Vector2(0, rand_range( - 0.5, 0))) * MOVE_SPEED)
		tile_normal = Vector2.ZERO

	
	var normals: = []
	wall_normal = Vector2.ZERO
	touching_floor = false
	if $RayCastUp.is_colliding():
		touching_wall = false
		direction = Vector2.ZERO
	else:
		if $RayCastRight.is_colliding():
			touching_wall = true
			normals.append(Vector2(1, 0))
		if $RayCastLeft.is_colliding():
			touching_wall = true
			normals.append(Vector2( - 1, 0))
		if $RayCastFloor.is_colliding():
			touching_wall = true
			touching_floor = true
			normals.append(Vector2(0, 1))

	if normals.size() and touching_wall:
		normals.shuffle()
		wall_normal = normals[0]
	else:
		touching_wall = false
		wall_normal = Vector2.ZERO

	if tile_normal.length() == 0 and wall_normal.length() == 0:
		direction = Vector2.ZERO
		
func _on_Rat_body_entered(body):
	if state == State.SCATTER:
		
		die()

func change_state(new_state: int):
	if randf() < 0.3:
		$Squeal.play()
		
	state = new_state
	match state:
		State.SEARCH:
			
			$AnimatedSprite.play("crawl")
			
		State.EAT:
			
			$AnimatedSprite.play("idle")
			
		State.SCATTER:
			$AnimatedSprite.play("idle")


func _on_AnimatedSprite_animation_finished():
	if $AnimatedSprite.animation == "appear":
		change_state(State.SEARCH)

	if $AnimatedSprite.animation == "disappear":
		queue_free()

