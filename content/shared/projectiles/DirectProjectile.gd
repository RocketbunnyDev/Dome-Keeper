extends Area2D

export (bool) var reflectable: = true
export (float) var rotation_offset: = 1.75

var damageSource: String
var spawnOnFree

var origin: Vector2
var target: Vector2
var damage: int
var speed: float
var flying: = true

func _ready():
	if $Sprite.frames.has_animation("start"):
		$Sprite.play("start")
	else:
		$Sprite.play("flying")
	Style.init(self)

func _physics_process(delta):
	if not flying or GameWorld.paused:
		return 
	
	var d = target - position
	rotation = d.angle() + PI * rotation_offset
	position += (d.normalized() * delta * speed).clamped(d.length())
	
	if d.length() < 2.0:
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
	match $Sprite.animation:
		"hit":
			queue_free()
		"start":
			$Sprite.play("flying")

func spawnExplosionIfAppropriate():
	if spawnOnFree:
		spawnOnFree.rotation = rotation + PI * 0.75
		spawnOnFree.position = position
		get_parent().call_deferred("add_child", spawnOnFree)
		spawnOnFree = null

func domeAbsorbsDamage():
	domeAcceptsDamage()

func domeReflectsDamage(returnedDamage: float = 0.0, returnedSpeed: float = 1.0, damageModifier: float = 2.0):
	$ShieldedSound.play()
	
	if returnedDamage > 0.0:
		deactivate()
		return 
	
	speed *= returnedSpeed
	damage *= damageModifier
	target = origin + (origin - position)
	
	set_collision_layer_bit(CONST.LAYER_MONSTER_PROJECTILES, false)
	set_collision_mask_bit(CONST.LAYER_WEAPONS, true)

func _on_Projectile_area_entered(area: Area2D)->void :
	
	if flying and area.is_in_group("monster"):
		area.hit(damage, 1.0)
		$ImpactSound.play()
		spawnExplosionIfAppropriate()
		deactivate()

func deactivate():
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)
	for c in get_children():
		if c is CollisionShape2D:
			c.disabled = true
	flying = false
	$Sprite.play("hit")
