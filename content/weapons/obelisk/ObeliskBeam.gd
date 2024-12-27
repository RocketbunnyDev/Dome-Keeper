extends Area2D

var dps: = 0.0
var sps: = 0.0
var width: = 0.0

var is_active: = false
var reticle = null
var hitMonsters: = []

var hm_delay = 0.1
var cur_hm_delay = 0.0


func init():
	Data.listen(self, "obelisk.beamDPS", true)
	Data.listen(self, "obelisk.beamSPS", true)
	Data.listen(self, "obelisk.beamWidth", true)
	
	dps = Data.of("obelisk.beamDPS")
	sps = Data.of("obelisk.beamSPS")
	width = Data.of("obelisk.beamWidth")
	$CollisionShape2D.shape.extents.x = width
	
	reticle = Level.dome.find_node("WeaponContainer").get_node("Obelisk/Reticle")
	
	set_is_active(false)
	
	Style.init(self)


func propertyChanged(property: String, oldValue, newValue):
	match property:
		"obelisk.beamdps":
			dps = newValue
		"obelisk.beamsps":
			sps = newValue
		"obelisk.beamwidth":
			width = newValue
			$CollisionShape2D.shape.extents.x = width
			$AnimatedSprite.scale.y = width / 10.0



func _process(delta: float)->void :
	global_position.y = - 14
	if hitMonsters.size() > 0 and is_active:
		if cur_hm_delay < hm_delay:
			cur_hm_delay += delta
		else:
			reticle.hit_marker()
			cur_hm_delay = 0.0
	
	for m in hitMonsters:
		if is_active:
			m.hit(dps * delta, sps * delta)


func set_is_active(value: bool):
	if not is_active and value:
		$StartSFX.play()
	if is_active and not value:
		$EndSFX.play()
	
	is_active = value
	$AnimatedSprite.visible = is_active
	$AnimatedSprite.playing = is_active
	if $SustainSFX.playing and not is_active:
		$SustainSFX.stop()
	elif not $SustainSFX.playing and is_active:
		$SustainSFX.play(0.0)
	

func addToHitMonsters(m):
	if not hitMonsters.has(m):
		hitMonsters.append(m)
		if not m.is_connected("died", self, "removeFromHitMonsters"):
			m.connect("died", self, "removeFromHitMonsters", [m])

func removeFromHitMonsters(m):
	if hitMonsters.has(m):
		if m.has_method("alive"):
			if not m.alive():
				reticle.kill_marker()
		hitMonsters.erase(m)
		m.disconnect("died", self, "removeFromHitMonsters")


func _on_ObeliskBeam_area_entered(area: Area2D)->void :
	if area.is_in_group("monster"):
		addToHitMonsters(area)


func _on_ObeliskBeam_area_exited(area: Area2D)->void :
	if area.is_in_group("monster"):
		removeFromHitMonsters(area)
