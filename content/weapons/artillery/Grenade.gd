extends Area2D











var velocity: Vector2
var exploded: = false
var nodesInExplosionRadius: = []
var aliveTime: = 0.0

func fire(initialVelocity):
	velocity = Vector2(0, - initialVelocity).rotated(rotation)
	$Explosion.visible = false

func _process(delta):
	if GameWorld.paused or exploded:
		return 
	
	velocity.y += delta * Data.of("artillery.grenadeGravity")
	
	position += delta * velocity
	rotation = velocity.angle()
	
	aliveTime += delta
	if aliveTime > 10.0:
		queue_free()

func _on_Grenade_area_entered(area):
	if exploded:
		return 
	
	if area.is_in_group("bouncy"):
		velocity.y *= - 0.6
		velocity.x += rand_range( - 30, 30) * 0.0
		if velocity.length() < 100:
			dud()
	else:
		explode()

func explode():
	exploded = true
	$Explosion.visible = true
	$Sprite.visible = false
	for n in nodesInExplosionRadius:
		if n.is_in_group("monster"):
			n.hit(100, 100)
	$Impact.play()
	$Tween.interpolate_callback(self, 0.1, "set", "visible", false)
	$Tween.start()

func dud():
	queue_free()

func _on_ExplosionArea_area_entered(area):
	nodesInExplosionRadius.append(area)

func _on_ExplosionArea_area_exited(area):
	nodesInExplosionRadius.erase(area)

func _on_Impact_finished():
	queue_free()
