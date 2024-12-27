extends Carryable

var targetPos: = Vector2.ZERO
var gravity: Vector2
var off: = Vector2()
var station
var resourcesInSucker: = []
var currentlySuckedResource
var originalAccel
var originalSpeedClamp
var suckCooldown: = 0.0
var shake: = 0.0
var pullCountdown: = 0.0

var teleporting: = false

func _ready():
	$Sprite.play("ready")
	gravity = ProjectSettings.get_setting("physics/2d/default_gravity") * ProjectSettings.get_setting("physics/2d/default_gravity_vector")
	Data.listen(self, "teleporter.teleportResources")
	Data.listen(self, "teleporter.teleportResourcesArea", true)
	$ResourceSucker / CollisionShape2D.disabled = not Data.of("teleporter.teleportResources")
	$Line2D.visible = false
	$Particles2D.emitting = false
	
	Style.init(self)
	
	Level.addTutorial(self, "teleporter_teleport")
	Level.addTutorial(self, "teleporter_carry")

func serialize()->Dictionary:
	var data = .serialize()
	data["targetPos"] = var2str(targetPos)
	data["pullCountdown"] = pullCountdown
	data["suckCooldown"] = suckCooldown
	return data

func deserialize(data: Dictionary):
	.deserialize(data)
	targetPos = str2var(data["targetPos"])
	pullCountdown = data["pullCountdown"]
	suckCooldown = data["suckCooldown"]
		
func propertyChanged(property: String, oldValue, newValue):
	match property:
		"teleporter.teleportresources":
			$ResourceSucker / CollisionShape2D.disabled = not newValue
		"teleporter.teleportresourcesarea":
			$ResourceSucker / CollisionShape2D.shape.radius = newValue * GameWorld.TILE_SIZE

func onCarried(p: Keeper):
	stopResourceSucking()

func onDropped(keeper: Keeper):
	


	targetPos = keeper.global_position

func _physics_process(delta):
	if isCarried():
		return 
	
	var dist = targetPos - position
	dist -= linear_velocity
	apply_central_impulse((dist * 1).clamped(1.0))
	off.y = sin(0.01 * OS.get_ticks_msec()) * 1.3
	apply_central_impulse(off)



	var drot = 0.0 - rotation
	apply_torque_impulse(drot * 2.0)
	
	if GameWorld.softPaused():
		return 
	
	if $ResourceSucker / CollisionShape2D.disabled:
		return 
		
	if suckCooldown > 0.0:
		suckCooldown -= delta
		return 
	
	$Sprite.play("ready")
	if not currentlySuckedResource:
		var closestD: = 9999.0
		var bestR
		for r in resourcesInSucker:
			if r.isCarried():
				continue
			var d = r.global_position - global_position
			if d.y < 0:
				d.y *= 4
			var thisD = d.length()
			if thisD < closestD:
				closestD = thisD
				bestR = r
		if bestR:
			currentlySuckedResource = bestR
			currentlySuckedResource.setIndependent(true)
			currentlySuckedResource.dropTarget = self
			originalAccel = currentlySuckedResource.independentAcceleration
			originalSpeedClamp = currentlySuckedResource.independentSpeedClamp
			$Line2D.visible = true
			$Particles2D.emitting = true
			shake = 20.0
			pullCountdown = 0.0
			return 
	else:
		if currentlySuckedResource.isCarried():
			
			stopResourceSucking()
			return 
	
	if currentlySuckedResource:
		var suckProgress = clamp(pullCountdown / 12.0, 0.01, 1.0)
		currentlySuckedResource.independentAcceleration = originalAccel * suckProgress * 80
		currentlySuckedResource.independentSpeedClamp = originalSpeedClamp * suckProgress * 80
		$Line2D.set_point_position(1, currentlySuckedResource.global_position - global_position)
		pullCountdown += delta
		if pullCountdown > 16.0:
			stopResourceSucking()

func stopResourceSucking():
	if not currentlySuckedResource:
		return 
	currentlySuckedResource.setIndependent(false)
	currentlySuckedResource.independentAcceleration = originalAccel
	currentlySuckedResource.independentSpeedClamp = originalSpeedClamp
	currentlySuckedResource = null
	$Line2D.visible = false
	$Particles2D.emitting = false

func dropTarget()->Vector2:
	return global_position

func onTeleported():
	animateTeleportation()

func animateTeleportation():
	$Sprite.frame = 0
	$Sprite.play("ready")
	$Particles2D.emitting = true
	$UseParticles.restart()
	$UseParticles.emitting = true
	$AnimationTimer.start(Data.of("teleporter.teleportDuration"))

func canFocusUse()->bool:
	return Data.of("teleporter.teleportBack") and carriedBy.size() == 0

func useHit(keeper: Keeper)->bool:
	if Data.of("teleporter.teleportBack"):
		teleporting = true
		animateTeleportation()
		unfocusCarry(keeper)
		var shrinkTime: = min(2.0, Data.of("teleporter.teleportDuration") * 0.33)
		var transitionTime: float = Data.of("teleporter.teleportDuration") - (2 * shrinkTime)
		keeper.shrink(shrinkTime, $CollisionShape2D.global_position)
		$TeleportationTimer.interpolate_callback(self, shrinkTime, "_on_TeleportationTimer_timeout", shrinkTime, transitionTime)
		$TeleportationTimer.start()
		return true
	else:
		return false

func useHold(keeper: Keeper)->bool:
	return false

func _on_ResourceSucker_body_entered(body):
	if body.canTeleport:
		resourcesInSucker.append(body)

func _on_ResourceSucker_body_exited(body):
	if body.canTeleport:
		resourcesInSucker.erase(body)

func arrived(res):
	if res == currentlySuckedResource:
		res.shrink()
		currentlySuckedResource = null
		suckCooldown = Data.of("teleporter.teleportResourcesCooldown")
		$Line2D.visible = false
		$AnimationTimer.start(0.5)

func pauseChanged():
	.pauseChanged()
	$AnimationTimer.paused = GameWorld.paused
	if GameWorld.paused and not independent:
		$TeleportationTimer.stop_all()
	else:
		$TeleportationTimer.resume_all()

func isTeleporting()->bool:
	return teleporting

func _on_AnimationTimer_timeout():
	shake = 0.0
	$Sprite.offset = Vector2.ZERO
	$Particles2D.emitting = false
	$Sprite.play("cooldown")

func _on_TeleportationTimer_timeout(shrinkTime: float, transitionTime: float):
	Level.keeper.teleport(station.teleportPosition())
	Level.keeper.grow(shrinkTime, transitionTime - 0.2)
	Level.stage.startEffect("dissolveTransition", [transitionTime])
	station.onTeleported()
	$Sprite.play("ready")
	teleporting = false
