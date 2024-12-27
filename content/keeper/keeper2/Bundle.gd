extends Node2D

var direction: Vector2
var carryInfluences: Array
var goalSpeed: float
var currentGoalPosition: Vector2
var lastCenterPos: Vector2

func _ready():
	Achievements.addIfOpen(self, "KEEPER2_BIGBUNDLE")

func start(direction: Vector2, goalSpeed: float, bundledCarryables: Array):
	self.direction = direction
	self.goalSpeed = goalSpeed
	self.carryInfluences = []
	
	$BundleCenter / Amb.play()
	







	for carryable in bundledCarryables:
		var influence = carryable.getOrCreateCarryInfluence()
		carryInfluences.append(influence)
		influence.strength = 1.0
		influence.bundle(self)

func _physics_process(delta):
	if carryInfluences.size() == 0:
		queue_free()
	
	var center = Vector2()
	
	for influence in carryInfluences:
		if not is_instance_valid(influence):
			Logger.error("carry influence instance is not valid anymore")
			continue
		center += influence.getCarryable().global_position
	center /= float(carryInfluences.size())
	$BundleCenter.position = center - global_position
	
	var goalMovement = direction * goalSpeed
	if goalMovement.length() == 0:
		for influence in carryInfluences:
			var carryable = influence.getCarryable()
			var impulse = center - carryable.global_position
			if impulse.length() > 120.0:
				influence.exitBundle()
				continue
			carryable.apply_central_impulse(impulse.clamped(2))
			
			
			
			if (influence.global_position - center).length() > 40:
				influence.exitBundle()
	else:



		
		var centerLocked: = false
		if Data.of("keeper2.bundlestopcenter") and abs(center.x) <= GameWorld.TILE_SIZE * 0.5 and not startedInCenter():
			goalMovement = Vector2( - center.x, 0)
			centerLocked = true

		if goalMovement.length() > 0:
			for influence in carryInfluences:
				var carryable = influence.getCarryable()
				var move = center - carryable.global_position
				if move.length() > 120.0:
					influence.exitBundle()
					continue
				var localCarryablePosition = carryable.global_position - global_position
				
				if not centerLocked:
					var bundleProgress = localCarryablePosition.project(goalMovement)
					move += bundleProgress - localCarryablePosition
	
	
				var impulse = (move + goalMovement).clamped(3)
				carryable.apply_central_impulse(impulse)

func removeCarryInfluence(carryInfluence):
	if carryInfluences.has(carryInfluence):
		carryInfluences.erase(carryInfluence)

func getBundledInfluences()->Array:
	return carryInfluences.duplicate()

func startedInCenter()->bool:
	return abs(global_position.x) <= GameWorld.TILE_SIZE * 0.5
