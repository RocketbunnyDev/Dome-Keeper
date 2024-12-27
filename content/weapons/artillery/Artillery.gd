extends Node2D

const GRENADE: = preload("res://content/weapons/artillery/Grenade.tscn")
const FLAK_SHELL: = preload("res://content/weapons/artillery/FlakShell.tscn")

var move: Vector2
var shotType: String
var shotCooldown: float
var chargeProgression: float
var shotsLeft: int
var interShotCooldown: float
var lastMoveY: float
var grenadeValue: float
var flakValue: float

func _ready():
	$Barrel / Filling.scale.y = 0.0
	$AimLine.visible = Data.of("artillery.aimLine")
	
	Style.init(self)

func init(cupolaPath):
	pass

func move(dir: Vector2, allowMove: bool):
	if GameWorld.paused:
		return 
	
	move = dir

func action(fire: float, special: float, allowShoot: bool):
	grenadeValue = fire
	flakValue = special


func _process(delta):
	$Barrel.rotation = clamp($Barrel.rotation + move.x * delta, - PI * 0.35, PI * 0.35)
	
	updateAimLine()
	
	if shotsLeft > 0:
		interShotCooldown -= delta
		if interShotCooldown < 0.0:
			call("fire" + shotType)
			shotsLeft -= 1
			interShotCooldown += Data.of("artillery.timeBetween" + shotType + "s")
			if shotsLeft == 0:
				chargeProgression = 0.0
				interShotCooldown = 0
		return 
	
	if shotCooldown > 0:
		shotCooldown -= delta
		if shotCooldown > 0:
			$Barrel.modulate = Color(0.7, 0.7, 0.7)
		else:
			$Barrel.modulate = Color.white
		return 
	
	if (grenadeValue or flakValue) and shotCooldown <= 0:
		if lastMoveY == 0.0:
			lastMoveY = flakValue - grenadeValue
			if flakValue - grenadeValue > 0.0:
				$Barrel / Filling.color = Color("8f8ee4")
			else:
				$Barrel / Filling.color = Color("943694")
		elif (flakValue - grenadeValue) != lastMoveY:
			chargeProgression = 0
			$ChargeSound.stop()
		else:
			chargeProgression = clamp(chargeProgression + delta * 1.0, 0.0, 1.0)
			if not $ChargeSound.playing:
				$ChargeSound.play()
			$ChargeSound.pitch_scale = 0.5 + chargeProgression
	
	if (chargeProgression > 0.0 and (flakValue == 0.0 and grenadeValue == 0.0)):
		if lastMoveY > 0.0:
			shotType = "FlakShell"
		else:
			shotType = "Grenade"
		shotsLeft = Data.of("artillery." + shotType + "s")
		$ChargeSound.stop()
		lastMoveY = 0
	
	$Barrel / Filling.scale.y = chargeProgression

func updateAimLine():
	if Data.of("artillery.aimLine") and chargeProgression > 0.0 and (grenadeValue > 0.0 or shotsLeft > 0):
		$AimLine.visible = true
		var velocity = Vector2(0, - (Data.of("artillery.grenadeMinimumVelocity") + chargeProgression * Data.of("artillery.grenadeMaximumChargeVelocity"))).rotated($Barrel.rotation)
		var currentPosition = $Barrel / SpawnPoint.global_position - global_position
		$ShotPredictionPath.curve.clear_points()
		$ShotPredictionPath.curve.add_point(currentPosition)
		while true:
			velocity.y += 0.1 * Data.of("artillery.grenadeGravity")
			currentPosition += 0.1 * velocity
			$ShotPredictionPath.curve.add_point(currentPosition)
			if currentPosition.y > - global_position.y:
				break
		$AimLine.clear_points()
		for p in $ShotPredictionPath.curve.get_baked_points():
			$AimLine.add_point(p)
		
		
		
		var space_state = get_world_2d().direct_space_state
		for n in range($AimLine.get_point_count() - 1):
			var from = to_global($AimLine.position + $AimLine.get_point_position(n))
			var to = to_global($AimLine.position + $AimLine.get_point_position(n + 1))
			var c = space_state.intersect_ray(from, to, [], 128, true, true)
			if c and c.collider and c.collider.is_in_group("monster"):
				c.collider.aim()
				break
	else:
		$AimLine.visible = false

func fireGrenade():
	var grenade = GRENADE.instance()
	grenade.rotation = $Barrel.rotation
	grenade.position = $Barrel / SpawnPoint.global_position
	Level.map.add_child(grenade)
	grenade.fire(Data.of("artillery.grenadeMinimumVelocity") + chargeProgression * Data.of("artillery.grenadeMaximumChargeVelocity"))
	shotCooldown = Data.of("artillery.shotCooldown")
	$ShotSound.play()

func fireFlakShell():
	var shell = FLAK_SHELL.instance()
	shell.rotation = $Barrel.rotation
	
	shell.position = $Barrel / SpawnPoint.global_position
	Level.map.add_child(shell)
	shell.fire(Data.of("artillery.flakshellMinimumVelocity") + chargeProgression * Data.of("artillery.flakshellMaximumChargeVelocity"))
	shotCooldown = Data.of("artillery.shotCooldown")
	$ShotSound.play()

func start():
	pass

func stop():
	pass
	
