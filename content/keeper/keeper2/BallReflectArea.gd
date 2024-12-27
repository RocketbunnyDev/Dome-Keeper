extends StaticBody2D

var approachingSpheres: = []
var reflectedSpheres: = []

var reflecting: = false

func _ready():
	Data.listen(self, "keeper2.reflectsphere", true)
	$AnimatedSprite.visible = false

func propertyChanged(property: String, oldValue, newValue):
	match property:
		
		"keeper2.reflectsphere":
			$BallReflectCollision.disabled = not newValue
			set_physics_process(newValue)

func sphereApproaching(sphere):
	if not approachingSpheres.has(sphere):
		approachingSpheres.append(sphere)

func spherePassed(sphere):
	if approachingSpheres.has(sphere):
		approachingSpheres.erase(sphere)

func _physics_process(delta):
	if reflecting:
		for sphere in approachingSpheres:
			if not reflectedSpheres.has(sphere):
				sphere.reflect()
				reflectedSpheres.append(sphere)
	
	var reflected = get_parent().getBallActionCooldown() > 0.0
	var hasapproachingSpheres = approachingSpheres.size() > 0
	if reflected and reflecting:
		$AnimatedSprite.play("reflect")
		$AnimatedSprite.modulate.a += (1.0 - $AnimatedSprite.modulate.a) * delta * 10
	elif hasapproachingSpheres:
		$AnimatedSprite.play("approach")
		$AnimatedSprite.modulate.a = (1.0 - $AnimatedSprite.modulate.a) * delta * 10
	else:
		$AnimatedSprite.play("active")
		$AnimatedSprite.modulate.a = (0.5 - $AnimatedSprite.modulate.a) * delta * 10
	
	$AnimatedSprite.visible = reflected or hasapproachingSpheres or reflecting
	if not $AnimatedSprite.visible:
		$AnimatedSprite.modulate.a = - $AnimatedSprite.modulate.a * delta * 10
	$AnimatedSprite.rotation = randf() * TAU

func reflect():
	reflecting = true

func stopReflect():
	reflecting = false
	reflectedSpheres.clear()
