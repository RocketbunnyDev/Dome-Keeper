extends Keeper


signal tileHit

var knockbackDirection: = Vector2()
var rising: = false
var falling: = true
var jumpStrengthLeft: = 0.0

const maxCarryLineLength: = 150.0

func _ready():
	Data.listen(self, "keeper.buffed")
	GameWorld.levelTechs.append(techId)
	
	Style.init(self)

func propertyChanged(property: String, oldValue, newValue):
	match property:
		"keeper.buffed":
			animationSuffix = "_buffed" if newValue else ""

func _physics_process(delta):
	
	if position.y < 0:
		$Light.hide()
	else:
		$Light.show()
		
	if not $Light / Tween.is_active():
		var s: float = rand_range(1.0, 1.05)
		$Light / Tween.interpolate_property($Light, "scale", $Light.scale, Vector2(s, s), 0.08, Tween.TRANS_CUBIC)
		$Light / Tween.start()
	
	if Data.of("keeper.insidestation") or GameWorld.paused or disabled:
		$MoveSound.stop()
		$CarryLoadSound.stop()
		return 
	
	move.x *= (1.0 - delta * 20)
	move.x += delta * moveDirectionInput.x * 200
	
	if moveDirectionInput.y == - 1 and not falling and not rising:
		rising = true
		jumpStrengthLeft = 3.0
	
	if rising:
		jumpStrengthLeft -= delta * 5
		if moveDirectionInput.y != - 1:
			jumpStrengthLeft = 0
		if jumpStrengthLeft <= 0.0:
			rising = false
			falling = true
	
	if rising or falling:
		move.y -= jumpStrengthLeft * delta * 10
		move.y = min(move.y + delta * 5, 10)
	
	var s = move_and_slide_with_snap(move * 10, Vector2.DOWN * 10, Vector2.ZERO if rising else Vector2.UP)
	if is_on_floor() and falling:
		falling = false
		move.y = 0.0
	elif not rising and not falling and not is_on_floor():
		falling = true
	
	
	
	updateInteractables()

func currentSpeed()->float:
	var s = Data.of("keeper5.maxSpeed") + Data.of("keeper.additionalmaxspeed")
	if Data.of("keeper.buffed"):
		s += Data.of("keeper.speedBuff")
	return s

func pickupHit():
	pass

func pickupHold():
	pass

func pickupHoldStopped():
	pass

func dropHit():
	pass

func dropHold():
	pass
