extends Area2D

var catch
var done: = false

var monstersInArea: = []

func _ready():
	Style.init(self)
	$Sprite.play("grow")
	
	$Tween.interpolate_callback(self, Data.of("orchard.battleabilityduration"), "dissolve")
	$Tween.start()

func _physics_process(delta):
	if catch:
		var d = global_position - catch.global_position
		if d.length() > 1.0:
			catch.position += d * delta * 5.0
	else:
		for mon in monstersInArea:
			if mon.stunLevel() > 0.0:
				$RootingEnemySound.play()
				catch = mon
				catch.sustainStun(10000, $Tween.get_runtime())
				catch.connect("died", self, "monsterDied", [mon])
				$Sprite.play("catch")
				$Tween.seek(0)
				$Tween.start()

func _on_OrchardRoot_area_entered(area):
	if catch or done:
		return 
	
	var mon = area.get_parent()
	if mon.is_in_group("monster") and mon.size == CONST.MONSTER_MEDIUM:
		monstersInArea.append(mon)

func dissolve(delay: = 0.0):
	if delay > 0.0:
		$Tween.interpolate_callback(self, delay, "dissolve")
		$Tween.start()
		return 
	
	$Sprite.play("shrink")
	done = true
	monstersInArea.clear()
	
	$RootsBreakSound.play()
	
	if catch:
		catch.clearStun()
		catch = null

func hasCatch()->bool:
	return catch != null

func explode():
	if catch:
		var e = load("res://content/shared/explosions/Explosion3.tscn").instance()
		e.damage = Data.of("orchard.battlerootexplosion")
		e.position = position
		get_parent().add_child(e)
	queue_free()

func _on_Sprite_animation_finished():
	if $Sprite.animation == "shrink":
		queue_free()

func _on_OrchardRoot_area_exited(area):
	if catch or done:
		return 
	if monstersInArea.has(area.get_parent()):
		monstersInArea.erase(area.get_parent())

func monsterDied(mon):
	if catch == mon:
		dissolve()
	elif monstersInArea.has(mon):
		monstersInArea.erase(mon)

func pauseChanged():
	if GameWorld.paused:
		$Tween.stop_all()
	else:
		$Tween.resume_all()
