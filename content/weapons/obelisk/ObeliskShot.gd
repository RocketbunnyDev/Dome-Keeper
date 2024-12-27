extends Node2D

var hitMonsters: = []
var cur_explosionDelay = 0.0
var explosionDelay = 0.0
var radius = 0
var damage = 0
var damageMult = 0.0
var stun = 0.0
var has_exploded = false
var first_frame = true
const EXPLOSION_GROUND = preload("res://content/shared/explosions/Explosion98.tscn")
const EXPLOSION_AIR = preload("res://content/shared/explosions/Explosion97.tscn")
const EXPLOSION_STUN = preload("res://content/shared/explosions/Explosion96.tscn")
const LIGHTNING_DOWN = preload("res://content/weapons/obelisk/LightningDown.tscn")

var physics_passed: = false
const EXPLOSION_HOLD_FRAMES: = 3
var cur_hold_frames: = 0

var reticle = null
var obelisk = null

func init():
	damage = Data.of("obelisk.damage")
	damageMult = Data.of("obelisk.damageMult")
	stun = Data.of("obelisk.stun")
	set_radius(Data.of("obelisk.radius"))
	explosionDelay = Data.of("obelisk.explosionDelay") + 0.1
	
	reticle = Level.dome.find_node("WeaponContainer").get_node("Obelisk/Reticle")
	obelisk = Level.dome.find_node("WeaponContainer").get_node("Obelisk")
	
	Style.init(self)

func set_radius(value: float):
	radius = value
	$HitArea / CollisionShape2D.shape.radius = value
	


func _process(delta: float)->void :
	if GameWorld.paused:
		return 
	
	if not has_exploded:
		
		if cur_explosionDelay >= explosionDelay and not first_frame and physics_passed:
			if cur_hold_frames >= EXPLOSION_HOLD_FRAMES:
				explode()
			
		else:
			cur_explosionDelay += delta
	
	first_frame = false

func _physics_process(delta: float)->void :
	if not physics_passed:
		if cur_hold_frames >= EXPLOSION_HOLD_FRAMES:
			physics_passed = true
			set_physics_process(false)
		else:
			cur_hold_frames += 1


func explode():
	print("explode")
	$Anticipation.visible = false
	has_exploded = true
	var expl
	if position.y >= - 35:
		expl = EXPLOSION_GROUND.instance()
	else:
		expl = EXPLOSION_AIR.instance()
	expl.damage = 0
	expl.get_node("Area2D").set_collision_mask_bit(7, false)
	expl.global_position = global_position
	Level.stage.add_child(expl)
	expl.connect("remove", self, "queue_free")
	expl.connect("explosion_disabled", $HitArea, "set_collision_mask_bit", [7, false])
	Style.init(expl)
	var s = radius
	s /= 70 / 2
	expl.scale = Vector2(s, s)
	
	var stun_rad = Data.of("obelisk.radiusStun")
	var expl_stun
	if stun_rad > radius:
		expl_stun = EXPLOSION_STUN.instance()
		expl_stun.damage = 0
		
		expl_stun.global_position = global_position
		Level.stage.add_child(expl_stun)
		expl_stun.connect("remove", self, "queue_free")
		expl_stun.stun_override = 30
		
		Style.init(expl_stun)
		var s2 = stun_rad
		s2 /= 256.0 / 2.0
		expl_stun.scale = Vector2(s2, s2)
	
	
	
	if hitMonsters.size() > 0:
		expl.get_node("Sprite").z_index = 200
		if expl_stun != null:
			expl_stun.get_node("Sprite").z_index = 200
	else:
		expl.get_node("Sprite").z_index = - 1
		if expl_stun != null:
			expl_stun.get_node("Sprite").z_index = - 1
	
	if hitMonsters.size() > 0:
		reticle.hit_marker()
		
	
	
	var d = LIGHTNING_DOWN.instance()
	d.init()
	d.global_position = global_position
	Level.stage.add_child(d)
	
	var x = Data.of("obelisk.lightningXRatio")
	var y = Data.of("obelisk.lightningYTarget")
	d.look_at(Vector2(global_position.x * (1.0 - x), global_position.y + y))
	
	
	for m in hitMonsters:
		m.hit(damage * damageMult, stun)
	
	
	var t = Data.of("obelisk.shootDelay")
	InputSystem.getCamera().shake((900 - abs(global_position.length())) * 0.07000000000000001, t * 0.5)
	
	
	
	if obelisk.cur_ammo == 0:
		$LastShot.play(0.1)
	elif obelisk.cur_ammo > 0 and obelisk.cur_ammo <= obelisk.maxAmmo * 0.25:
		$AmmoLowShot.play()
	else:
		$LightningDown.play(0.3)


func _on_HitArea_area_entered(area: Area2D)->void :
	if area.is_in_group("monster"):
		addToHitMonsters(area)

func _on_HitArea_area_exited(area: Area2D)->void :
	if area.is_in_group("monster"):
		removeFromHitMonsters(area)

func addToHitMonsters(m):
	if not hitMonsters.has(m):
		print("addToHitMonsters")
		hitMonsters.append(m)
		if not m.is_connected("died", self, "removeFromHitMonsters"):
			m.connect("died", self, "removeFromHitMonsters", [m])

func removeFromHitMonsters(m):
	if hitMonsters.has(m):
		if not m.alive():
			reticle.kill_marker()
		hitMonsters.erase(m)
		m.disconnect("died", self, "removeFromHitMonsters")
