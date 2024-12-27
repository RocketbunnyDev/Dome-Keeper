extends Node2D

var tween: Tween = Tween.new()
var tile = null

const MIN_DISTANCE_FROM_KEEPER = 50

func _ready():
	add_child(tween)
	$AnimatedSprite.play("appear")
	
	$deathTimer.wait_time = rand_range(5, 20)
	$deathTimer.start()
	
	Style.init(self)
	$Spawn.play()

func die():
	$AnimatedSprite.play("disappear")
	$Despawn.play()

func _on_deathTimer_timeout():
	die()

func _physics_process(delta):
	var distance_to_keeper = Level.keeper.global_position.distance_to(global_position)
	if distance_to_keeper < MIN_DISTANCE_FROM_KEEPER:
		die()
		
	if not is_instance_valid(tile):
		die()

func _on_AnimatedSprite_animation_finished():
	if $AnimatedSprite.animation == "appear":
		$AnimatedSprite.play("idle")
		$AnimatedSprite.frame = randi() % 8
		
	if $AnimatedSprite.animation == "disappear":
		queue_free()
