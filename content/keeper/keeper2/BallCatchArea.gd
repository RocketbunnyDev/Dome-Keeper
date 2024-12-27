extends StaticBody2D

var approachingSpheres: = []
var handledSpheres: = []

var catching: = false

func _ready():
	Data.listen(self, "keeper2.spheresplit", true)
	$AnimatedSprite.visible = false

func propertyChanged(property: String, oldValue, newValue):
	match property:
		
		"keeper2.spheresplit":
			$BallCatchCollision.disabled = not newValue
			set_physics_process(newValue)

func sphereApproaching(sphere):
	if not approachingSpheres.has(sphere):
		approachingSpheres.append(sphere)

func spherePassed(sphere):
	if approachingSpheres.has(sphere):
		approachingSpheres.erase(sphere)

func _physics_process(delta):
	if catching:
		for sphere in approachingSpheres:
			if not handledSpheres.has(sphere):
				sphere.catch()
				handledSpheres.append(sphere)
				
				var keeper = get_parent()
				var sphere1 = preload("res://content/keeper/keeper2/Pinball.tscn").instance()
				sphere1.size = sphere.size * 0.75
				sphere1.position = sphere.position
				keeper.get_parent().add_child(sphere1)
				sphere1.apply_central_impulse(100 * sphere.linear_velocity.rotated(PI * 0.5).normalized())
				sphere1.lifeTime *= 0.75
				
				var sphere2 = preload("res://content/keeper/keeper2/Pinball.tscn").instance()
				sphere2.size = sphere.size * 0.75
				sphere2.position = sphere.position
				keeper.get_parent().add_child(sphere2)
				sphere2.apply_central_impulse(100 * sphere.linear_velocity.rotated( - PI * 0.5).normalized())
				sphere2.lifeTime *= 0.75
				
				keeper.ballActionCooldown = 7.5
				InputSystem.getCamera().shake(100, 0.2)
				
				stopCatching()
	
	var reflected = get_parent().getBallActionCooldown() > 0.0
	var hasapproachingSpheres = approachingSpheres.size() > 0
	if reflected and catching:
		$AnimatedSprite.play("reflect")
		$AnimatedSprite.modulate.a += (1.0 - $AnimatedSprite.modulate.a) * delta * 10
	elif hasapproachingSpheres:
		$AnimatedSprite.play("approach")
		$AnimatedSprite.modulate.a += (1.0 - $AnimatedSprite.modulate.a) * delta * 10
	else:
		$AnimatedSprite.play("active")
		$AnimatedSprite.modulate.a += (0.5 - $AnimatedSprite.modulate.a) * delta * 10
		
	$AnimatedSprite.visible = reflected or hasapproachingSpheres or catching
	if not $AnimatedSprite.visible:
		$AnimatedSprite.modulate.a = - $AnimatedSprite.modulate.a * delta * 10
	$AnimatedSprite.rotation = randf() * TAU

func catch():
	catching = true

func stopCatching():
	catching = false
	handledSpheres.clear()
