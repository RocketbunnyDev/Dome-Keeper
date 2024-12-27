extends Node2D

var rocketDelay: = 0.0
var cargo: = []
var amount: = []

func _ready():
	$Back.play("back")
	$Sprite.play("empty")
	$Front.play("front")
	Data.listen(self, "prestige.sentiron")
	Data.listen(self, "prestige.sentwater")
	Data.listen(self, "prestige.sentcobalt")
	
	Style.init(self)

func propertyChanged(property: String, oldValue, newValue):
	if GameWorld.currentLoadingSavegame:
		return 
	
	if not oldValue:
		oldValue = 0
	
	if newValue > oldValue:
		match property:
			
			"prestige.sentiron":
				queueRocket("iron", oldValue)
			"prestige.sentwater":
				queueRocket("water", oldValue)
			"prestige.sentcobalt":
				queueRocket("cobalt", oldValue)

func _process(delta):
	if GameWorld.paused:
		return 
	
	if rocketDelay > 0.0:
		rocketDelay -= delta
	else:
		if cargo.size() > 0:
			$Sprite.play("emerge")
			rocketDelay += 6.0

func queueRocket(type: String, a: int):
	cargo.append(type)
	amount.append(a)

func _on_Sprite_animation_finished():
	if $Sprite.animation == "emerge":
		$Sprite.play("empty")
		
		var rocket = preload("res://content/gamemode/prestige/rocket/Rocket.tscn").instance()
		rocket.position = $RocketPosition.position
		add_child(rocket)
		rocket.setCargo(cargo.pop_front(), amount.pop_front())
		$Tween.interpolate_callback(self, 1.0, "launchRocket", rocket)
		$Tween.start()

func launchRocket(rocket):
	$Front.frame = 0
	$Front.play("start")
	rocket.launch()
	$RocketLaunch.play()

func _on_Front_animation_finished():
	$Front.play("front")

func pauseChanged():
	if GameWorld.paused:
		$Tween.stop_all()
		$Sprite.speed_scale = 0.0
	else:
		$Sprite.speed_scale = 1.0
		$Tween.resume_all()
