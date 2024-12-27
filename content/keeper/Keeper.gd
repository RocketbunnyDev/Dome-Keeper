extends KinematicBody2D

class_name Keeper

export (String) var techId: = ""

var disabled: = false

var usables: = []
var carryables: = []
var focussedUsable
var focussedCarryable

var moveDirectionInput: = Vector2()
var move: = Vector2()
var externallyMoved: = false
var pickupType: = ""

var animationSuffix: = ""

var carriedCarryables: = []

func _ready():
	Achievements.addIfOpen(self, "KEEPER_BOTTOM")
	Achievements.addIfOpen(self, "KEEPER_TIMELY")
	Achievements.addIfOpen(self, "KEEPER_MARATHON")
	
	if GameWorld.keeperSkinId != "":
		setSkin(GameWorld.keeperSkinId)

func setSkin(skinId: String):

	$Sprite.frames = load("res://content/keeper/" + techId + "/spriteframes-" + skinId + ".tres")

func exitStation():
	if not GameWorld.lost:
		
		
		
		visible = true
	Data.apply("keeper.insidestation", false)
	$Trail.visible = true
	$Sprite.visible = true
	enableEffects()

func enterStation():
	$Sprite.visible = false
	$Trail.restart()
	$Trail.visible = false
	disableEffects()
	move *= 0.0
	position = focussedUsable.get_parent().getKeeperPosition() + Vector2(0.5, 0)
	Data.apply("keeper.insidestation", true)
	
	for c in carriedCarryables.duplicate():
		if not c.get_collision_layer_bit(CONST.LAYER_DOME_EXTERNAL):
			
			
			c.setIndependent(true)
			c.dropTarget = Level.dome.getDropTarget(c.type)
		dropCarry(c)

func _on_CarryArea_body_entered(carryable):
	if carryables.has(carryable):
		return 
	
	carryables.append(carryable)

func _on_CarryArea_body_exited(carryable):
	carryables.erase(carryable)

func _on_UseArea_usable_entered(usable):
	if usables.has(usable):
		return 
	
	usables.append(usable)

func _on_UseArea_usable_exited(usable):
	usables.erase(usable)

func dropCarry(body):
	pass

func updateInteractables():
	updateUsables()
	updateCarryables()

func updateUsables():
	if not is_instance_valid(focussedUsable):
		focussedUsable = null
	
	if focussedUsable:
		if usables.has(focussedUsable):
			if not focussedUsable.canFocusUse():
				focussedUsable.unfocusUse(self)
				focussedUsable = null
			else:
				return 
		else:
			focussedUsable.unfocusUse(self)
			focussedUsable = null
	else:
		for usable in usables:
			if usable.canFocusUse():
				focussedUsable = usable
				usable.focusUse(self)

func updateCarryables():
	pass

func sortByDistance(b1, b2):
	return (b1.global_position - global_position).length() < (b2.global_position - global_position).length()

func useHit()->bool:
	if Data.of("keeper.insidestation") or disabled:
		return false
	
	if focussedUsable and is_instance_valid(focussedUsable):
		var handled = focussedUsable.useHit(self)
		if handled:
			return true
	
	return false

func useHold():
	if Data.of("keeper.insidestation") or disabled:
		return false
	
	if focussedUsable:
		focussedUsable.useHold(self)

func onGameLost():
	$UseArea.monitoring = false
	if focussedUsable:
		focussedUsable.unfocusUse(self)
		focussedUsable = null
	if focussedCarryable:
		focussedCarryable.unfocusCarry(self)
		focussedCarryable = null
	disabled = true
	
	visible = false

func teleport(pos: Vector2):
	if focussedUsable:
		focussedUsable.unfocusUse(self)
		focussedUsable = null
	move *= 0.0
	moveDirectionInput *= 0.0
	position = pos

func shrink(duration: float, goalPos: Vector2):
	$TeleportInit.play()
	for c in carriedCarryables.duplicate():
		dropCarry(c)
	disabled = true
	
	disableEffects()
	$Sprite.play("default" + animationSuffix)
	$Tween.interpolate_property($Sprite, "scale", Vector2.ONE, Vector2.ZERO, duration, Tween.TRANS_CUBIC, Tween.EASE_IN)
	$Tween.interpolate_property(self, "position", position, goalPos, duration - 0.1, Tween.TRANS_CUBIC, Tween.EASE_OUT)
	$Tween.start()

func grow(duration: float, delay: = 0.0):
	$TeleportDone.play()
	$Tween.interpolate_property($Sprite, "scale", Vector2.ZERO, Vector2.ONE, duration, Tween.TRANS_CUBIC, Tween.EASE_IN_OUT, delay)

	$Tween.interpolate_callback(self, duration + delay - 0.1, "set", "disabled", false)
	$Tween.interpolate_callback(self, duration + delay - 0.1, "enableEffects")
	$Tween.start()

func disableEffects():
	pass

func enableEffects():
	pass

func unlockGadget(gadgetData: Dictionary):
	var id = gadgetData.get("id", "")
	match id:
		"probe":
			var p = preload("res://content/gadgets/probe/Probe.tscn").instance()
			add_child(p)

func pauseChanged():
	if GameWorld.paused:
		$Tween.stop_all()
	else:
		$Tween.resume_all()

func remove():
	disableEffects()
	visible = false
