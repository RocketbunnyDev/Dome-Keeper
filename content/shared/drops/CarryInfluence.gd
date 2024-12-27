extends Node2D

var lastStrength: = 0.0
var strength: = 0.0
var bundle
var cooldown: = 0.0
var beingPulled: = false
var duration: = 5.0

func _ready():
	$Outline.emitting = true
	var po = CarryablePhysicsOverride.new()
	po.gravity_scale = 0.0
	po.linear_damp = 0.0
	po.angular_damp = 0.0
	getCarryable().addPhysicsOverride(po)

func _physics_process(delta):
	var carryable = getCarryable()
	if carryable.isAutoTransported and not beingPulled and not (bundle and bundle.startedInCenter()):
		dissolve()
		return 
	
	if carryable.isCarried() or carryable.independent:
		exitBundle()
		strength = 0
		return 
	
	if strength <= 0.0 or carryable.deactivated:
		dissolve()
		return 
	
	if strength < 2.0 / duration:
		$Outline.emitting = false
	else:
		$Outline.emitting = true
	
	if bundle:
		if cooldown > 0.0:
			cooldown -= delta
			return 
	
	lastStrength = strength

func set_size(value: float):
	var vel = 16.0 * value
	$Outline.process_material = $Outline.process_material.duplicate()
	$Outline.amount *= value
	$Outline.process_material.initial_velocity = vel
	$Outline.process_material.damping = 0.8 * vel
	$Outline.emitting = true

func bundle(bundle):
	self.bundle = bundle
	var carryable = getCarryable()
	var po = CarryablePhysicsOverride.new()
	po.gravity_scale = 0.0
	po.linear_damp = 4.0
	po.angular_damp = 1.0
	carryable.addPhysicsOverride(po)
	duration = float(Data.of("keeper2.bundleduration"))

func isBundled()->bool:
	return bundle != null

func getBundle():
	return bundle

func exitBundle():
	if bundle:
		var carryable = getCarryable()
		carryable.popPhysicsOverride()
		bundle.removeCarryInfluence(self)
		bundle = null

func getCarryable():
	return get_parent()

func dissolve():
	exitBundle()
	var carryable = getCarryable()
	carryable.removeCarryInfluence()
	queue_free()
