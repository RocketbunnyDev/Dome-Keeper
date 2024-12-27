extends Carryable

class_name Drop

export (String) var type: = ""
export (bool) var stabilizeRotation: = false
export (bool) var hasInterDropCollisionSound: = false
export (bool) var floatUncarried: = false
export (float) var independentSpeedClamp: = 2.0
export (float) var independentAcceleration: = 1.0
export (float) var arrivalDistanceToTarget: = 3.0

var absorbed: = false
var dropTarget
var dropTargetPosition: Vector2
var stabilizationForce: = 1.0
var domeEnterPosition: float
var bounciness: float
var dropSoundCooldown: = 0.0

var lastCollisions: = {}

func _ready():
	if $Sprite.material:
		$Sprite.material = $Sprite.material.duplicate()
	
	if hasInterDropCollisionSound:
		connect("body_entered", self, "_on_Drop_body_entered")
	
	
	bounciness = physics_material_override.bounce
	
	Style.init(self)
	
	Data.changeByInt("inventory.floating" + type, 1)
	Data.changeByInt("inventory.total" + type, 1)

func canFocusCarry()->bool:
	return not independent

func _physics_process(delta):
	if GameWorld.paused and not independent:
		return 
	
	for c in lastCollisions.duplicate():
		var d = lastCollisions[c] - delta
		if d <= 0:
			lastCollisions.erase(c)
		else:
			lastCollisions[c] = d

	if dropSoundCooldown > 0.0:
		dropSoundCooldown -= delta
	
	if not isCarried():
		if independent and dropTarget:
			var dist = independentAcceleration * (dropTarget.dropTarget() - position)
			if dist.length() < arrivalDistanceToTarget and not absorbed:
				dropTarget.arrived(self)
			
			
			apply_central_impulse(Vector2(0, dist.y).clamped(independentSpeedClamp))
			apply_central_impulse(Vector2(dist.x, 0).clamped(independentSpeedClamp))
			if not deactivated:
				deactivate()
		elif floatUncarried and not hasCarryInfluence():
			apply_central_impulse( - linear_velocity.clamped(3.0))
	
	if independent and not dropTarget and not deactivated:
		deactivate()
		gravity_scale = 0.1
	
	if not deactivated and not independent:
		if linear_velocity.length() > 4.0:
			physics_material_override.call_deferred("set_bounce", bounciness)
		else:
			physics_material_override.call_deferred("set_bounce", 0.0)
	
	if stabilizeRotation:
		var drot = 0.0 - rotation
		apply_torque_impulse(drot * stabilizationForce)

func floatToDropTarget(dropTarget):
	self.dropTarget = dropTarget
	setIndependent(true)
	if isCarried():
		for k in carriedBy:
			if k:
				
				k.dropCarry(self)

func deactivate():
	set_collision_layer_bit(CONST.LAYER_USABLES, false)
	set_collision_mask_bit(CONST.LAYER_USABLES, false)
	deactivated = true
	var po = CarryablePhysicsOverride.new()
	po.gravity_scale = 0.0
	po.linear_damp = 2
	po.angular_damp = 2
	addPhysicsOverride(po)
	physics_material_override.call_deferred("set_bounce", 0.0)
	if type == CONST.GADGET and not absorbed:
		Level.stage.startGadgetChoiceInput()
		gravity_scale = 0.0
		remove_from_group("saveable")

func remove():
	if absorbed:
		return 
	
	absorbed = true
	Data.changeByInt("inventory.floating" + type, - 1)
	queue_free()

func shrink():
	if absorbed:
		return 
	
	if dropTarget:
		dropTargetPosition = dropTarget.dropTarget()
		dropTarget = null
	
	absorbed = true
	var outDuration: = 0.6
	linear_damp = 13
	
	$Tween.interpolate_property($Sprite, "scale", Vector2.ONE, Vector2.ZERO, outDuration, Tween.TRANS_CUBIC, Tween.EASE_IN)
	$Tween.interpolate_property(self, "position", position, dropTargetPosition, outDuration - 0.1, Tween.TRANS_CUBIC, Tween.EASE_OUT)

	$Tween.interpolate_callback(Data, outDuration * 0.6, "changeByInt", "inventory." + type, 1)
	$Tween.interpolate_callback(self, outDuration, "queue_free")
	$Tween.start()
	Data.changeByInt("inventory.floating" + type, - 1)
	
	if is_in_group("saveable"):
		remove_from_group("saveable")

func shred():
	if absorbed:
		return 
	
	if dropTarget:
		dropTargetPosition = dropTarget.dropTarget()
		dropTarget = null
	
	absorbed = true
	var outDuration: = 0.6
	var particle_lifetime = 0
	linear_damp = 13
	
	if has_node("ShredParticles"):
		for child in get_node("ShredParticles").get_children():
			particle_lifetime = max(particle_lifetime, child.lifetime)
			child.emitting = true
			$Tween.interpolate_callback(child, outDuration, "set_emitting", false)
		$Tween.interpolate_property($Sprite.material, "shader_param/fade", 0, 1, outDuration, Tween.TRANS_LINEAR)
	else:
		$Tween.interpolate_property($Sprite, "scale", $Sprite.scale, Vector2.ZERO, outDuration, Tween.TRANS_CUBIC, Tween.EASE_IN)
	$Tween.interpolate_callback(Data, outDuration * 0.6, "changeByInt", "inventory." + type, 1)
	Data.changeByInt("inventory.floating" + type, - 1)
	
	
	$Tween.interpolate_callback(self, outDuration + particle_lifetime, "queue_free")
	$Tween.start()
	
	if is_in_group("saveable"):
		remove_from_group("saveable")

func _on_Drop_body_entered(body):
	if lastCollisions.has(body):
		lastCollisions[body] = 1.0
		return 
	
	if dropSoundCooldown > 0.0:
		return 
	
	if $BumpSound.playing:
		return 
	
	var other_velocity = body.get("linear_velocity")
	if other_velocity == null:
		other_velocity = Vector2.ZERO
	var relative_velocity = linear_velocity - other_velocity
	if relative_velocity.length() > 2.0:
		$BumpSound.additionalVolume = - 6 + 6 * min(1.5, relative_velocity.length() / 12.0)

		$BumpSound.play()
		dropSoundCooldown = 0.3
		lastCollisions[body] = 0.4

func moveToPhysicsBackLayer(changeModulate: = true):
	if changeModulate:
		modulate = Color(0.8, 0.8, 0.8, 1)
	gravity_scale = 0.1
	collision_layer = 0
	collision_mask = 0
	set_collision_layer_bit(CONST.LAYER_BACK_LAYER_COLLISIONS, true)
	set_collision_mask_bit(CONST.LAYER_BACK_LAYER_COLLISIONS, true)

func dropTarget():
	return dropTargetPosition
