extends Sprite

enum Mode{NOTHING, BLAST, REFLECT, INVULNERABLE}
var mode: int = Mode.NOTHING

var monstersInBlastArea: = []
var projectilesInReflectArea: = []

var active: = false
var maxAdditionalCharge: = 0.0
var chargedAfter: float = 1.0
var blastSpriteFrame: float

const DESTRUCTION_PREVENTION_COOLDOWN: = 3
const Splash = preload("res://content/gadgets/shield/Splash.tscn")

func _ready():
	$Blast.visible = false
	$Reflect.visible = false
	$Invulnerable.visible = false
	$OverchargeShield.visible = false
	$Reflect.monitoring = false
	$Reflect / CollisionPolygon2D.disabled = true
	$Blast.monitoring = false
	$Blast / CollisionPolygon2D.disabled = true
	
	visible = false
	set_process(false)
	Data.listen(self, "shield.stage", true)
	Data.listen(self, "shield.overchargestrength", true)
	Data.apply("shield.strength", 0)
	Data.apply("shield.additionalstrength", 0)
	Data.apply("shield.remainingbattleuses", 0)
	Data.apply("shield.remainingabilityduration", 0)
	Data.apply("shield.dorecharge", true)
	
	Achievements.addIfOpen(self, "SHIELD_STRONG")

func propertyChanged(property: String, oldValue, newValue):
	match property:
		
		"shield.overchargestrength":
			maxAdditionalCharge = newValue
		"monsters.wavepresent":
			if newValue == oldValue:
				
				chargedAfter = GameWorld.getTimeBetweenWaves() * float(Data.of("shield.growthTime"))
				return 
			
			if newValue:
				Data.apply("shield.remainingbattleuses", Data.of("shield.battleuses"))
			else:
				Data.apply("shield.overcharged", false)
				Data.apply("shield.additionalstrength", 0.0)
				
				chargedAfter = GameWorld.getTimeBetweenWaves() * float(Data.of("shield.growthTime"))
				var currentCooldown = Data.of("shield.battlepreventioncooldown")
				if currentCooldown == DESTRUCTION_PREVENTION_COOLDOWN:
					Data.apply("shield.dorecharge", false)
				else:
					Data.apply("shield.dorecharge", true)
				if currentCooldown > 0:
					Data.apply("shield.battlepreventioncooldown", max(0, currentCooldown - 1))
		"shield.overcharged":
			if newValue:
				Data.apply("shield.additionalstrength", maxAdditionalCharge)
				$OverchargeShield.visible = true
		"shield.battlereflect":
			if mode == Mode.NOTHING and newValue:
				add_to_group("battle1")
				$Reflect.monitoring = true
				$Reflect / CollisionPolygon2D.disabled = false
				mode = Mode.REFLECT
				$Blast.queue_free()
				$Invulnerable.queue_free()
		"shield.battleblast":
			if mode == Mode.NOTHING and newValue:
				add_to_group("battle1")
				$Blast.monitoring = true
				$Blast / CollisionPolygon2D.disabled = false
				mode = Mode.BLAST
				$Reflect.queue_free()
				$Invulnerable.queue_free()
		"shield.battleinvulnerable":
			if mode == Mode.NOTHING and newValue:
				add_to_group("battle1")
				mode = Mode.INVULNERABLE
				$Reflect.queue_free()
				$Blast.queue_free()
		"shield.stage":
			if newValue > 0:
				if not visible:
					visible = true
					self_modulate.a = 0.0
					set_process(true)
					Data.listen(self, "shield.battlereflect")
					Data.listen(self, "shield.battleblast")
					Data.listen(self, "shield.battleinvulnerable")
					Data.listen(self, "monsters.wavepresent")
					Data.listen(self, "shield.overcharged")
					Data.apply("shield.battlepreventioncooldown", 0)
			else:
				visible = false
				set_process(false)
				
func spawnSplash(pos):
	var splash = Splash.instance()
	add_child(splash)
	splash.global_position = pos

func absorbDamage(rawDamage, pos: Vector2)->float:
	if not visible:
		return rawDamage

	if Data.of("shield.overcharged"):
		spawnSplash(pos)
			
	if active and mode == Mode.INVULNERABLE:
		return 0.0

	var add = Data.of("shield.additionalstrength")
	var remainingAfterAdditional = max(0, rawDamage - add)
	add = max(add - rawDamage, 0)
	Data.apply("shield.additionalstrength", add)
	if add <= 0.0:
		Data.apply("shield.overcharged", false)
	
	var s = Data.of("shield.strength")
	var remaining = max(0.0, remainingAfterAdditional - s)
	var newS = max(s - remainingAfterAdditional, 0)
	Data.apply("shield.strength", newS)
	
	
	if newS == 0.0 and s > 0.0 and Data.of("shield.battleactivateondepletion"):
		if active:
			var duration = getBattleAbilityDuration()
			duration += duration - $Tween.tell()
			active = true
			$Tween.stop_all()
			$Tween.remove_all()
			$Tween.interpolate_callback(self, duration, "deactivate")
			$Tween.start()
		else:
			executeBattle1(0, false)
			if active and mode == Mode.INVULNERABLE:
				return 0.0
	
	
	var preventionTime = Data.of("shield.battledestructionprevention")
	if preventionTime > 0 and remaining + 1.0 > Data.of("dome.health") and Data.of("shield.battlepreventioncooldown") == 0:
		executeBattle1(preventionTime, false)
		Data.apply("shield.battlepreventioncooldown", DESTRUCTION_PREVENTION_COOLDOWN)
		Data.apply("dome.health", 1.0)
		Data.changeByInt("shield.absorbeddamage", rawDamage)
		return 0.0
	if s > 0.0:
		Data.changeByInt("shield.absorbeddamage", remaining * 0.5)
		return remaining * 0.5
	else:
		Data.changeByInt("shield.absorbeddamage", remaining)
		return remaining

func _process(delta):
	if GameWorld.paused:
		return 
	
	var currentShieldStrength = Data.of("shield.strength")
	var maxShieldStrength = Data.of("shield.maxStrength")
	var filling: float = currentShieldStrength / maxShieldStrength
	self_modulate.a = min(filling, 1.0)
	if $OverchargeShield.visible:
		$OverchargeShield.modulate.a = Data.of("shield.additionalstrength") / float(maxAdditionalCharge)
	
	if not GameWorld.softPaused() and Data.of("shield.dorecharge"):
		var rechargeRate = maxShieldStrength / chargedAfter
		currentShieldStrength = min(currentShieldStrength + delta * rechargeRate, maxShieldStrength)
		
		Data.apply("shield.strength", currentShieldStrength)
	
	if active:
		Data.apply("shield.remainingabilityduration", $Tween.get_runtime() - $Tween.tell())
		match mode:
			Mode.BLAST:
				var dmg = Data.of("shield.battleblastdamage") * delta
				var stun = Data.of("shield.battleblaststun")
				for area in monstersInBlastArea.duplicate():
					area.hit(dmg, stun)
				blastSpriteFrame += delta * 10
				if blastSpriteFrame >= 75:
					blastSpriteFrame = 50
				$Blast / BlastSprite.frame = int(blastSpriteFrame)
			Mode.INVULNERABLE:
				pass
			Mode.REFLECT:
				for area in projectilesInReflectArea:
					area.domeReflectsDamage(0.0, Data.of("shield.battlereflectspeedup"))
					$Reflect / ReflectProjectileSound2.play()
					
					
					$Reflect / Tween.remove_all()
					$Reflect / ReflectSprite.modulate = Color(1, 1, 1, 1)
					$Reflect / Tween.interpolate_property($Reflect / ReflectSprite, "scale", Vector2(1.05, 1.05), Vector2(1, 1), 0.5, Tween.TRANS_ELASTIC, Tween.EASE_OUT)
					$Reflect / Tween.start()
					
				projectilesInReflectArea.clear()
				
func _on_BlastArea_area_entered(area):
	if area.is_in_group("monster") and not monstersInBlastArea.has(area):
		monstersInBlastArea.append(area)
		area.connect("died", self, "monsterDied", [area])

func monsterDied(monster):
	monstersInBlastArea.erase(monster)

func _on_BlastArea_area_exited(area):
	if area.is_in_group("monster"):
		monstersInBlastArea.erase(area)
		area.disconnect("died", self, "monsterDied")

func _on_ReflectArea_area_entered(area):
	if area.is_in_group("projectile"):
		projectilesInReflectArea.append(area)

func _on_ReflectArea_area_exited(area):
	if area.is_in_group("projectile"):
		projectilesInReflectArea.erase(area)

func executeBattle1(extraTime: = 0.0, useCharge: = true)->bool:
	if mode == Mode.NOTHING:
		return false
	
	if active:
		return false
	
	if useCharge:
		var remainingUses = Data.of("shield.remainingbattleuses")
		if remainingUses <= 0:
			Audio.sound("gui_err")
			return false
		Data.apply("shield.remainingbattleuses", remainingUses - 1)
	
	var duration = getBattleAbilityDuration() + extraTime
	
	active = true
	Audio.sound("gui_toggle")
	
	$Tween.stop_all()
	$Tween.remove_all()
	$Tween.interpolate_callback(self, duration, "deactivate")
	$Tween.start()
	
	match mode:
		Mode.BLAST:
			$Blast.visible = true
			blastSpriteFrame = 49.0
			$Blast / BlastSound.play()
			$Blast / BlastLoopSound.play()
		Mode.INVULNERABLE:
			$Invulnerable / InvulnerableSprite.modulate = Color(1, 1, 1, 1)
			$Invulnerable.visible = true
			$Invulnerable / InvulnerableSound.play()
		Mode.REFLECT:
			$Reflect / Tween.remove_all()
			$Reflect.visible = true
			$Reflect / ReflectSprite.modulate = Color(1, 1, 1, 1)
			$Reflect / ReflectSprite.scale = Vector2(1, 1)
			$Reflect / ReflectSound.play()
			$Reflect / InitiateReflectSound.play()
	Backend.event("battle_ability_used", {"gadget": "shield", "ability": Mode.keys()[mode]})
	return true

func getBattleAbilityName()->String:
	match mode:
		Mode.BLAST:
			return tr("upgrades.shieldbattleelectroblast.title")
		Mode.INVULNERABLE:
			return tr("upgrades.shieldbattleinvulnerable.title")
		Mode.REFLECT:
			return tr("upgrades.shieldbattlereflect.title")
	return ""

func getBattleAbilityDuration()->float:
	var duration = Data.of("shield.battleabilityduration")
	if Data.of("shield.overcharged"):
		duration += duration * Data.of("shield.overchargebattleabilityduration")
	if Data.of("shield.strength") <= 0.0:
		duration += Data.of("shield.battleadditionalabilitydurationafterdepletion")
	return duration

func deactivate():
	active = false
	match mode:
			Mode.BLAST:
				$Blast.visible = false
				$Blast / BlastLoopSound.stop()
				$Blast / BlastEndSound.play()
			Mode.INVULNERABLE:
				var duration = 0.15
				$Tween.remove_all()
				$Tween.interpolate_property($Invulnerable / InvulnerableSprite, "modulate", Color(1, 1, 1, 1), Color(1, 1, 1, 0), duration, Tween.TRANS_LINEAR)
				$Tween.start()
			Mode.REFLECT:
				var duration = 0.15
				$Reflect / Tween.remove_all()
				$Reflect / ReflectSprite.scale = Vector2(1, 1)
				$Reflect / Tween.interpolate_property($Reflect / ReflectSprite, "modulate", Color(1, 1, 1, 1), Color(1, 1, 1, 0), duration, Tween.TRANS_LINEAR)
				$Reflect / Tween.interpolate_callback($Reflect, duration, "hide")
				$Reflect / Tween.start()
	
	Data.apply("shield.remainingabilityduration", 0.0)

func pauseChanged():
	if GameWorld.paused:
		$Tween.stop_all()
	else:
		$Tween.resume_all()
