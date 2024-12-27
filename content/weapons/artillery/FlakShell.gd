extends Area2D

var velocity: Vector2
var exploded: = false
var nodesInExplosionRadius: = []
var remainingAliveTime: = 0.0

func fire(initialVelocity: float):
	velocity = Vector2(0, - initialVelocity).rotated(rotation)
	remainingAliveTime = 1.0
	$Explosion.visible = false
	var r = Data.of("artillery.flakExplosionRadius")
	$ExplosionArea / CollisionShape2D.shape.radius = r
	$Explosion.scale = Vector2.ONE * (r / 25.0)

func _process(delta):
	if GameWorld.paused or exploded:
		return 
	
	velocity.y += delta * Data.of("artillery.flakShellGravity")
	
	position += delta * velocity
	rotation = velocity.angle()
	
	remainingAliveTime -= delta
	if remainingAliveTime <= 0.0:
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

func _on_ExplosionArea_area_entered(area):
	nodesInExplosionRadius.append(area)

func _on_ExplosionArea_area_exited(area):
	nodesInExplosionRadius.erase(area)

func _on_Impact_finished():
	queue_free()

func _on_FlakShell_area_entered(area):
	explode()
