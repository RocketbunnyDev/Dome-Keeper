extends Node2D

var monsters = {}

const Hit = preload("res://content/gadgets/cobaltbomb/CobaltHit.tscn")
const Flash = preload("res://content/gadgets/cobaltbomb/CobaltFlash.tscn")
const GroundBurst = preload("res://content/gadgets/cobaltbomb/GroundBurst.tscn")

func _ready():
	
	$AnimationPlayer.play("boom")
	$sfxBomb.play()
	Style.init(self)

func _process(delta):
	
	for monster in monsters.keys():
		var line = monsters[monster]["line"] as Line2D
		var flash = monsters[monster]["flash"] as Node2D
		if not is_instance_valid($Orbs):
			line.hide()
			continue
		if not is_instance_valid(monster):
			line.hide()
			continue
		var direction = (monster.global_position - $Orbs.position).normalized()
		line.set_point_position(0, $Orbs.position)
		
		line.set_point_position(1, monster.global_position)
		flash.global_position = to_global(monster.global_position)
		flash.rotation = direction.angle()
		if line.default_color == Color("#ffffff"):
			line.width = 2
			line.default_color = Color("#804B6B")
		else:
			line.width = 4
			line.default_color = Color("#ffffff")
		monster.hit(0.001 * delta, 10)

func explode():
	
	InputSystem.getCamera().shake(400, 10, 8)
	
	
	for monster in monsters.keys():
		var line = monsters[monster]["line"] as Line2D
		line.hide()
				
		if not is_instance_valid(monster):
			continue
			
		var hit = Hit.instance()
		hit.global_position = monster.global_position
		
		var delay = rand_range(0.2, 1.0)
		$Tween.interpolate_callback(self, delay - 0.1, "add_child", hit)
		$Tween.interpolate_callback(self, delay, "kill_monster", monster)
		
	$Tween.start()
	$monsterScanTimer.stop()


func ground_bursts():
	for n in range(5):
		var delay = n * 0.1
		var burst1 = GroundBurst.instance()
		burst1.position = n * Vector2(80, 0) + Vector2(75, - 64)
		var burst2 = GroundBurst.instance()
		burst2.position = n * Vector2( - 80, 0) + Vector2( - 75, - 64)
		$Tween.interpolate_callback(self, delay, "add_child", burst1)
		$Tween.interpolate_callback(self, delay, "add_child", burst2)

	$Tween.start()
		
func kill_monster(monster):
	if not is_instance_valid(monster):
		return 
	
	monster.hit(100000, 100000)
	
	
	var line = monsters[monster]["line"]
	line.hide()

	
	for p in get_tree().get_nodes_in_group("projectile"):
		p.queue_free()

func _on_AnimationPlayer_animation_finished(anim_name):
	queue_free()

func start_monster_scan():
	$monsterScanTimer.start()
	


func _on_monsterScanTimer_timeout():
	for monster in get_tree().get_nodes_in_group("monster"):
		if monsters.has(monster):
			continue
		var line = Line2D.new()
		line.add_point($Orbs.position)
		line.add_point(monster.position)
		add_child(line)
		var flash = Flash.instance()
		line.add_child(flash)
		monsters[monster] = {"line": line, "flash": flash}
		Style.init(line)
