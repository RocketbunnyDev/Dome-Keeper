extends HudElement

var maxCooldown: float
var cooldown: = 0.0
var ready: = false
var teleporting: = false
var placedEye

func init():
	maxCooldown = Data.of("caveteleporter.cooldown") * GameWorld.getTimeBetweenWaves()
	if placedEye:
		$Eye.play("portal_placed")
	elif cooldown > 0:
		$Eye.animation = "cooldown"
		$Eye.frame = 0
		$Eye.playing = false
	else:
		$Eye.play("ready_to_use")
		ready = true
	
	Level.addTutorial(self, "onewayteleporter")

func serialize()->Dictionary:
	var data = {
		"maxCooldown": maxCooldown, 
		"cooldown": cooldown, 
		"ready": ready, 
		"teleporting": teleporting
	}
	return data
	
func deserialize(data: Dictionary):
	maxCooldown = data["maxCooldown"]
	cooldown = data["cooldown"]
	ready = data["ready"]
	teleporting = data["teleporting"]

	yield (GameWorld, "savegame_loaded")
	
	var eye = Level.map.find_node("TeleporterEye", true, false)
	if eye:
		placedEye = eye
		$Eye.play("portal_placed")
		if teleporting:
			teleporting = false
			executeSpecial2()
	elif cooldown > 0.0:
		$Eye.animation = "cooldown"
		$Eye.frame = 0
		$Eye.playing = false
	else:
		$Eye.play("cooldown_finished")

func _process(delta):
	if GameWorld.softPaused():
		return 
	
	if cooldown > 0.0:
		cooldown -= delta
		if cooldown <= 0.0:
			ready = true
			$ReadySound.play()
			$Eye.play("cooldown_finished")
		else:
			$Eye.frame = 24.0 * (1.0 - cooldown / maxCooldown)

func _on_Eye_animation_finished():
	if $Eye.animation == "cooldown_finished":
		$Eye.play("ready_to_use")

func executeSpecial2()->bool:
	if teleporting or GameWorld.paused:
		return false
	
	if placedEye:
		teleporting = true
		var shrinkTime: = 0.5
		var transitionTime: float = 0.5
		Level.keeper.shrink(shrinkTime, Level.keeper.position)
		yield (get_tree().create_timer(shrinkTime), "timeout")
		Level.keeper.teleport(placedEye.position)
		Level.keeper.grow(shrinkTime, transitionTime - 0.2)
		Data.apply("keeper.insidedome", false)
		Level.stage.startEffect("dissolveTransition", [transitionTime])
		$Eye.animation = "cooldown"
		$Eye.frame = 0
		$Eye.playing = false
		maxCooldown = Data.of("caveteleporter.cooldown") * GameWorld.getTimeBetweenWaves()
		cooldown = maxCooldown
		ready = false
		placedEye.onUsed()
		placedEye = null
		teleporting = false
		return true
	elif ready and not Data.of("keeper.insidedome"):
		placedEye = preload("res://content/caves/teleportcave/TeleporterEye.tscn").instance()
		placedEye.position = Level.keeper.position
		$Eye.play("portal_placed")
		Level.map.add_child(placedEye)
		return true
	return false
