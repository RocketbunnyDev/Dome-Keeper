extends Area2D

export (bool) var reflectable: = true
export (float) var rotation_offset: = 1.75

var damageSource: String
var spawnOnFree

var path: Curve2D
var damage: int
var speed: float
var flying: = false
var pathProgress: float
var tween: Tween
var direction: Vector2

func _ready():
	$Sprite.play("flying")
	Style.init(self)
	tween = Tween.new()
	add_child(tween)
	add_to_group("pauseL")

func start(path, interpolation: int, easing: int):
	self.path = path
	var pathLength = path.get_baked_length()
	var time = pathLength / speed
	position = path.interpolate_baked(pathProgress)
	tween.interpolate_property(self, "pathProgress", 0, pathLength, time, interpolation, easing)
	tween.interpolate_callback(self, time, "onTravelFinished")
	tween.start()
	flying = true

func _physics_process(delta):
	if not flying or GameWorld.paused:
		return 
	
	position = path.interpolate_baked(pathProgress)
	direction = path.interpolate_baked(pathProgress + 5.0) - position
	rotation = direction.angle() + rotation_offset

func onTravelFinished():
	if get_collision_layer_bit(CONST.LAYER_MONSTER_PROJECTILES):
		Level.dome.requestProjectileDamage(damage, global_position, self)
		InputSystem.getCamera().shake(min(100, damage), 0.2, 10)
	else:
		flying = false
		queue_free()

func domeAcceptsDamage():
	$ImpactSound.play()
	spawnExplosionIfAppropriate()
	deactivate()

func _on_Sprite_animation_finished():
	if $Sprite.animation == "hit":
		queue_free()

func spawnExplosionIfAppropriate():
	if spawnOnFree:
		spawnOnFree.rotation = rotation + PI * 0.75
		spawnOnFree.position = position
		get_parent().call_deferred("add_child", spawnOnFree)
		spawnOnFree = null

func domeAbsorbsDamage():
	if flying:
		$ShieldedSound.play()
		deactivate()

func domeReflectsDamage(returnedDamage: float = 0.0, returnedSpeed: float = 1.0, damageModifier: float = 2.0):
	$ShieldedSound.play()
	
	if returnedDamage > 0.0:
		deactivate()
		return 
	
	speed *= returnedSpeed
	damage *= damageModifier
	
	path.clear_points()
	path.add_point(position)
	path.add_point(position - direction * 1000)
	var pathLength = path.get_baked_length()
	var time = pathLength / speed
	pathProgress = 0
	tween.stop_all()
	tween.remove_all()
	tween.interpolate_property(self, "pathProgress", 0, pathLength, time, Tween.TRANS_LINEAR, Tween.EASE_IN)
	tween.start()
	
	
	set_collision_layer_bit(CONST.LAYER_MONSTER_PROJECTILES, false)
	set_collision_mask_bit(CONST.LAYER_WEAPONS, true)

func _on_Projectile_area_entered(area: Area2D)->void :
	if flying and area.is_in_group("monster"):
		area.hit(damage, 1.0)
		spawnExplosionIfAppropriate()
		$ImpactSound.play()
		deactivate()

func deactivate():
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)
	for c in get_children():
		if c is CollisionShape2D:
			c.disabled = true
	tween.stop_all()
	tween.remove_all()
	flying = false
	$Sprite.play("hit")

func pauseChanged():
	if GameWorld.paused:
		tween.stop_all()
	else:
		tween.resume_all()
