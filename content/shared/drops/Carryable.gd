extends RigidBody2D

class_name Carryable


export  var additionalSlowdown: = 0.0

export (String) var carryableType: = ""
export (bool) var canTeleport: = false
var carriedBy: = []
var inFocusArea: = []
var focussed: = false
var deactivated: = false
var independent: = false
var isAutoTransported: = false

var physicsOverrides: = []
var carryInfluence
export (float, 1.0, 5.0) var carryInfluenceSize: = 1.0

func _ready():
	var originalPhysics = CarryablePhysicsOverride.new()
	originalPhysics.linear_damp = linear_damp
	originalPhysics.angular_damp = angular_damp
	originalPhysics.gravity_scale = gravity_scale
	physicsOverrides.append(originalPhysics)
	
	$FocusSprite.visible = false
	$CarrySprite.visible = false
	
	add_to_group("pauseL")

var oldVelocity = Vector2()
func pauseChanged():
	if GameWorld.paused and not independent:
		oldVelocity = linear_velocity
		set_axis_velocity(Vector2.ZERO)
		mode = RigidBody2D.MODE_STATIC
	else:
		mode = RigidBody2D.MODE_RIGID
		set_axis_velocity(oldVelocity)

func serialize()->Dictionary:
	var data = {}

	data["carriedBy"] = []
	for carrier in carriedBy:
		if carrier:
			data["carriedBy"].append(carrier.name)

	data["meta.priority"] = 100
	data["meta.kind"] = "generic"

	return data

func deserialize(data: Dictionary):
	for carrier in data["carriedBy"]:
		if carrier == "Keeper":
			Level.keeper.attachCarry(self)

func setIndependent(b: bool):
	independent = b
	pause_mode = Node.PAUSE_MODE_PROCESS if independent else Node.PAUSE_MODE_INHERIT
	if independent:
		$FocusSprite.visible = false

func focusCarry(p: Keeper):
	inFocusArea.append(p)
	updateFocus()

func unfocusCarry(p: Keeper):
	inFocusArea.erase(p)
	updateFocus()

func updateFocus():
	if canFocusCarry() and inFocusArea.size() > 0:
		focussed = true
		get_node("FocusSprite").visible = true
	else:
		focussed = false
		get_node("FocusSprite").visible = false

func isCarried()->bool:
	return carriedBy.size() > 0

func canFocusCarry()->bool:
	return true

func setCarriedBy(p: Keeper):
	$CarrySprite.visible = true
	carriedBy.append(p)
	if carriedBy.size() == 1:
		onCarried(p)

func freeCarry(p: Keeper):
	popPhysicsOverride()
	carriedBy.erase(p)
	if carriedBy.size() == 0:
		$CarrySprite.visible = false
		onDropped(p)

func onCarried(p: Keeper):
	pass

func onDropped(p: Keeper):
	pass

func carrierCount()->int:
	return carriedBy.size()

func getOrCreateCarryInfluence():
	if carryInfluence == null:
		carryInfluence = load("res://content/shared/drops/CarryInfluence.tscn").instance()
		carryInfluence.set_size(carryInfluenceSize)
		add_child(carryInfluence)
	return carryInfluence

func removeCarryInfluence():
	if carryInfluence:
		remove_child(carryInfluence)
		carryInfluence = null
		popPhysicsOverride()
	else:
		Logger.error("carryable does not have a carry influence", "Carryable.removeCarryInfluence", {"drop": name})

func hasCarryInfluence()->bool:
	return carryInfluence != null

func getCarryInfluence():
	return carryInfluence

func addPhysicsOverride(physics: CarryablePhysicsOverride):
	physicsOverrides.append(physics)
	_updatePhysicsOverrides()

func popPhysicsOverride():
	if physicsOverrides.size() > 1:
		physicsOverrides.pop_back()
		_updatePhysicsOverrides()






func _updatePhysicsOverrides():

	for p in physicsOverrides:
		p.apply(self)
