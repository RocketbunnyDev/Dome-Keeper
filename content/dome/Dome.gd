extends Node2D

class_name Dome

onready var ArtifactDropPoint = get_node("ArtifactDropPoint")
onready var RelicDropPoint = get_node("RelicDropPoint")
onready var EggDropPoint = get_node("EggDropPoint")
onready var PiercePoints = get_node("PiercePoints")
onready var MeleeTargets = get_node("MeleeTargets")
onready var ProjectileTargets = get_node("ProjectileTargets")
onready var cracks_overlay = $CracksOverlay

var primaryWeapon: String
export (String) var techId: String
var collapsed: = false
var availableSlots: Array

var trackedDamage: = {}
var damageOnWave: float

var autoRepairAmount: float = 0.0

func _ready():
	Style.init(self)
	
	Level.addTutorial(self, "stationdefend")
	Level.addTutorial(self, "repair1")
	Level.addTutorial(self, "repair2")
	
	Achievements.addIfOpen(self, "RESOURCES_COBALTSTACK")
	Achievements.addIfOpen(self, "RESOURCES_COBALTRESCUE")
	Achievements.addIfOpen(self, "DOME_LOWHEALTH")

func init():
	$CupolaPath.visible = true
	$WeaponContainer.visible = true
	$CracksOverlay.visible = true
	$CollapseSprite.visible = false
	$CollapseParticles.emitting = false
	$Cellar / RelicActivation.play("none")
	$Cellar / SpinningRelic.play("none")
	
	var domeData = Data.gadgets.get(techId)
	for s in domeData.get("slots", []):
		availableSlots.append(s)
	
	primaryWeapon = domeData.get("primaryweapon")
	
	
	for c in $MeleeTargets.get_children():
		for i in range(0, c.curve.get_point_count()):
			c.curve.set_point_position(i, c.curve.get_point_position(i) + global_position)
	
	Data.listen(self, "dome.baserepair")
	Data.listen(self, "dome.healthfractionrepair")
	Data.listen(self, "monsters.wavepresent")

func propertyChanged(property: String, oldValue, newValue):
	match property:
		"dome.baserepair":
			if newValue != 0:
				Data.changeDomeHealth(newValue)
		"dome.healthfractionrepair":
			if newValue != 0:
				Data.changeDomeHealth(newValue * Data.of("dome.maxHealth"))
		"monsters.wavepresent":
			if newValue:
				damageOnWave = 0.0
				trackedDamage.clear()

func _process(delta):
	if autoRepairAmount > 0.0:
		var repair = clamp(100 * delta, 0, autoRepairAmount)
		autoRepairAmount -= repair
		Data.changeDomeHealth(repair)
		
		$HealParticles.emitting = true
	else:
		$HealParticles.emitting = false

func onGameLost():
	if collapsed:
		return 
	
	collapsed = true
	$CollapseSprite.frame = 0
	$CollapseSprite.visible = true
	$CollapseShards.collapse()
	$Tween.interpolate_property($CollapseSprite, "frame", 0, 11, 1.0, Tween.TRANS_LINEAR, Tween.EASE_IN, 0.0)
	$Tween.interpolate_property($CollapseParticles, "emitting", false, true, 0.0, Tween.TRANS_LINEAR, Tween.EASE_IN, 0.0)
	$Tween.start()
	$Background.visible = false
	$Foreground.visible = false
	$Shield.visible = false
	$WartContainer.visible = false
	$Station.visible = false
	$PrimaryGadgetContainer.visible = false
	$Shredder.visible = false
	$CupolaPath.visible = false
	$WeaponContainer.visible = false
	$CracksOverlay.hide()
	
	for pet in get_tree().get_nodes_in_group("pets"):
		pet.visible = false

func getDropTarget(dropType: String):
	match dropType:
		CONST.GADGET:
			return Level.dome.ArtifactDropPoint
		CONST.RELIC:
			return Level.dome.RelicDropPoint
		CONST.EGG:
			return Level.dome.EggDropPoint
		CONST.IRON:
			return $Shredder
		CONST.WATER:
			return $Shredder
		CONST.SAND:
			return $Shredder

func getProjectileTargetProvider():
	return $ProjectileTargets

func getMeleeTarget(variant):
	match variant:
		CONST.LEFT: return $MeleeTargets / Left
		CONST.RIGHT: return $MeleeTargets / Right
		CONST.TOP: return $MeleeTargets / Top
	return null

func getFrontAttackPosition(variant)->Vector2:
	var point: Vector2
	match variant:
		"left": point = $FrontAttackPoints / LeftPoint1.global_position
		"right": point = $FrontAttackPoints / RightPoint1.global_position
		_: point = $FrontAttackPoints / CenterPoint1.global_position
	var offset: = Vector2.RIGHT.rotated(randf() * TAU)
	return point + offset * 16 * randf()


func getCupolaPosition(offset: float)->Vector3:
	var pos = $CupolaPath.curve.interpolate_baked(offset * $CupolaPath.curve.get_baked_length())
	var angle = (pos - pos * $CupolaPath.axisModulation - $CupolaPath.getRotationCenter()).angle() + PI * 0.5
	return Vector3(pos.x, pos.y, angle)

func addWeapon():
	var w = load("res://content/weapons/" + primaryWeapon + "/" + primaryWeapon.capitalize() + ".tscn").instance()
	$WeaponContainer.add_child(w)
	w.init($CupolaPath)

func requestProjectileDamage(rawDamage: int, pos: Vector2, requester):
	var damage = $Shield.absorbDamage(rawDamage, pos)
	if damage > 0.0:
		Data.changeDomeHealth( - damage)
		cracks_overlay.hit(pos, damage)
		handleSustainedDamage(damage)
		requester.domeAcceptsDamage()
	elif damage == 0.0:
		requester.domeAbsorbsDamage()
	else:
		requester.domeReflectsDamage()
	trackedDamage[requester.damageSource] = trackedDamage.get(requester.damageSource, 0) + damage

func requestMeleeDamage(rawDamage: int, pos: Vector2, requester):
	var remainingDamage = $Shield.absorbDamage(rawDamage, pos)
	var damage: float = remainingDamage * (1.0 - Data.of("dome.meleedamageReduction"))
	if remainingDamage > 0.0:
		Data.changeDomeHealth( - damage)
		handleSustainedDamage(damage)
		cracks_overlay.hit(pos, damage)
		requester.domeAcceptsDamage()
	else:
		requester.domeReflectsDamage()
	trackedDamage[requester.damageSource] = trackedDamage.get(requester.damageSource, 0) + damage

func unlockGadget(gadgetData: Dictionary):
	var id = gadgetData.get("id", "")
	match id:
		"repellent":
			var repellent = preload("res://content/gadgets/repellent/Repellent.tscn").instance()
			$PrimaryGadgetContainer.add_child(repellent)
		"orchard":
			var orchard = preload("res://content/gadgets/orchard/Orchard.tscn").instance()
			$PrimaryGadgetContainer.add_child(orchard)
		"stunlaser":
			var laser = preload("res://content/gadgets/stunLaser/StunLaser.tscn").instance()
			$CupolaPath.add_child(laser)
			laser.init($CupolaPath)
		"stunobelisk":
			var obelisk = preload("res://content/gadgets/obelisk/Obelisk.tscn").instance()
			$ObeliskContainer.add_child(obelisk)
		"blastmining":
			var gadget = preload("res://content/gadgets/blastMining/MiningStation.tscn").instance()
			placeInCellar(gadget)
		"probe":
			var gadget = preload("res://content/gadgets/probe/ProbeStation.tscn").instance()
			placeInCellar(gadget)
		"condenser":
			var gadget = preload("res://content/gadgets/condenser/Condenser.tscn").instance()
			placeInCellar(gadget)
		"shield":
			var gadget = preload("res://content/gadgets/shield/ShieldBattery.tscn").instance()
			$PrimaryGadgetContainer.add_child(gadget)
		"teleporter":
			var gadget = preload("res://content/gadgets/teleporter/TeleporterStation.tscn").instance()
			placeInCellar(gadget)
		"drillbot":
			var gadget = preload("res://content/gadgets/drillbot/DrillbotStation.tscn").instance()
			placeInCellar(gadget)
		"converter":
			var gadget = preload("res://content/gadgets/converter/Converter.tscn").instance()
			placeInCellar(gadget)
		"dronehub":
			var gadget = preload("res://content/gadgets/transportdrone/DroneHub.tscn").instance()
			$PrimaryGadgetContainer.add_child(gadget)
	
	var data = Data.gadgets.get(id)
	if data != null and data.has("slot"):
		availableSlots.erase(data.get("slot"))

func handleSustainedDamage(damage: float):
	damageOnWave += damage
	var threshold = Data.of("dome.autohealdamagethreshold")
	if threshold > 0.0:
		if damageOnWave >= threshold:
			autoRepairAmount = Data.of("dome.autohealamount")
			damageOnWave = - INF

func removeGadget(gadgetData: Dictionary):
	var id = gadgetData.get("id", "")
	match id:
		"repellent":
			for c in $PrimaryGadgetContainer.get_children():
				c.queue_free()
		"orchard":
			for c in $PrimaryGadgetContainer.get_children():
				c.queue_free()
		"stunLaser":
			for c in $CupolaPath.get_children():
				c.queue_free()
		"stunObelisk":
			for c in $ObeliskContainer.get_children():
				c.queue_free()
		"blastMining":
			var gadget = preload("res://content/gadgets/blastMining/MiningStation.tscn").instance()
			placeInCellar(gadget)
		"probe":
			var gadget = preload("res://content/gadgets/probe/ProbeStation.tscn").instance()
			placeInCellar(gadget)
		"condenser":
			var gadget = preload("res://content/gadgets/condenser/Condenser.tscn").instance()
			placeInCellar(gadget)
		"shield":
			for c in $PrimaryGadgetContainer.get_children():
				c.queue_free()
			$Shield.visible = false
		"teleporter":
			var gadget = preload("res://content/gadgets/teleporter/TeleporterStation.tscn").instance()
			placeInCellar(gadget)
	
	var data = Data.gadgets.get(id)
	if data != null:
		availableSlots.append(data.get("slot"))

func placeInCellar(gadget):
	var container
	if $Cellar / ContainerLeft.get_child_count() > 0:
		container = $Cellar / ContainerRight
	elif $Cellar / ContainerRight.get_child_count() > 0:
		container = $Cellar / ContainerLeft
	else:
		container = $Cellar / ContainerLeft
	
	
	if container.position.x < 0:
		gadget.flip()
	container.add_child(gadget)

func ambience()->AudioStreamPlayer:
	return $Ambience as AudioStreamPlayer

func uiRender():
	$Cellar.visible = false

func cellarEntranceY()->float:
	return $EntranceCellar.global_position.y

func _on_RelicDropPoint_relic_recovered():
	InputSystem.getCamera().shake(80, 2, 5)
	$Cellar / RelicActivation.play("activate")
	$Cellar / RelicActivation / Inserted.play()

func _on_RelicActivation_animation_finished():
	if $Cellar / RelicActivation.animation == "activate":
		$Cellar / RelicActivation / Ambience.play()
		$Cellar / RelicActivation.play("running")
		$Cellar / SpinningRelic.play("spinning")

func popTrackedDamage()->Dictionary:
	return trackedDamage
