extends Node2D

signal freed

var hitMonsters: = []
var piercedMonsters: = []
var remainingPierceDamage: float

func _ready():
	set_physics_process(true)
	if Data.of("sword.stabarrowhead"):
		find_node("ArrowLeft", false, false).visible = true
		find_node("ArrowRight", false, false).visible = true

func _process(delta):
	if GameWorld.paused:
		return 
	
	position += Vector2.UP.rotated(rotation) * Data.of("sword.extendSpeed") * Data.of("sword.stabspeed") * delta
	
	if hitMonsters.size() > 0:
		for m in hitMonsters:
			if not piercedMonsters.has(m):
				var dmg = min(remainingPierceDamage, m.currentHealth)
				m.hit(dmg, 5 * dmg)
				piercedMonsters.append(m)
				remainingPierceDamage -= dmg
				if remainingPierceDamage <= 0:
					emit_signal("freed")

func setCollisionShapes(bladeCollisionShape, arrowHead):
	$HitArea / BladeCollisionShape.position = bladeCollisionShape.position
	$HitArea / BladeCollisionShape.shape = bladeCollisionShape.shape
	$HitArea / ArrowHead.position = arrowHead.position
	$HitArea / ArrowHead.shape = arrowHead.shape

func _on_Timer_timeout():
	emit_signal("freed")
	queue_free()

func _on_HitArea_area_entered(area):
	if area.is_in_group("monster"):
		addToHitMonsters(area)

func _on_HitArea_area_exited(area):
	if area.is_in_group("monster"):
		removeFromHitMonsters(area)

func addToHitMonsters(m):
	if not hitMonsters.has(m):
		hitMonsters.append(m)
		if not m.is_connected("died", self, "removeFromHitMonsters"):
			m.connect("died", self, "removeFromHitMonsters", [m])

func removeFromHitMonsters(m):
	if hitMonsters.has(m):
		hitMonsters.erase(m)
		m.disconnect("died", self, "removeFromHitMonsters")
