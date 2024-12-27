extends HudElement

const rectSizes: = [8, 12, 16, 20]
const textures: = [
	preload("res://content/hud/wavemeter/bar0.png"), 
	preload("res://content/hud/wavemeter/bar1.png"), 
	preload("res://content/hud/wavemeter/bar2.png"), 
	preload("res://content/hud/wavemeter/bar3.png"), 
	preload("res://content/hud/wavemeter/bar4.png"), 
]

var delayRectSize: = 0.0
var goalRectSize: = 0.0
const maxSpawnRectSize: = 25.0
var lastWaveDelay: = 0.0
var keeperInStation: = false

onready var MonsterSpawnRect = $BarBackground / MonsterSpawnRect
onready var WaveDelayRect = $BarBackground / WaveDelayRect

const colorKeyInactive: = Color(32.0 / 255.0, 0, 220.0 / 256.0)
const colorKeyInactiveOvercharged: = Color(136.0 / 255.0, 0, 220.0 / 256.0)
const colorKeyActive: = Color(96.0 / 255.0, 0, 220.0 / 256.0)
const colorKeyReady: = Color(80.0 / 255.0, 0, 220.0 / 256.0)

func _ready():
	$BarBackground.visible = false
	MonsterSpawnRect.visible = false
	$Flare.visible = false
	$WaveLabel.visible = false
	
	if not GameWorld.isUpgradeLimitAvailable("hostile"):
		$Normal.texture = preload("res://content/hud/wavemeter/time.png")
		$Flare.texture = preload("res://content/hud/wavemeter/time.png")

func init():
	WaveDelayRect.visible = false
	WaveDelayRect.rect_size.x = 0
	Data.listen(self, "keeper.insidestation")
	Data.listen(self, "monsters.wavecooldown")
	Data.listen(self, "monsters.wavepresent")
	Data.listen(self, "game.over")
	Data.listen(self, "wavemeter.stage", true)
	Data.listen(self, "wavemeter.delayStage", true)
	
func _process(delta):
	var sizeD = goalRectSize - MonsterSpawnRect.rect_size.x
	sizeD += sign(sizeD)
	MonsterSpawnRect.rect_size.x += delta * sizeD
	
	if WaveDelayRect.visible:
		if GameWorld.waveDelay > 0.0:
			if lastWaveDelay == 0.0:
				lastWaveDelay = GameWorld.waveDelay
			MonsterSpawnRect.color = Style.mapColor(colorKeyInactive)
			WaveDelayRect.color = Style.mapColor(colorKeyActive)
			WaveDelayRect.rect_size.x = clamp(GameWorld.waveDelay / lastWaveDelay, 0, 1.0) * delayRectSize
		else:
			lastWaveDelay = 0.0
			MonsterSpawnRect.color = Style.mapColor(colorKeyActive)
			var fill: float = Data.of("repellent.currentgrowth")
			WaveDelayRect.rect_size.x = clamp(fill, 0, 1.0) * delayRectSize
			if fill >= 1.0:
				WaveDelayRect.color = Style.mapColor(colorKeyReady)
			else:
				var overcharged = Data.of("repellent.remainingovercharged") > 0
				if overcharged:
					WaveDelayRect.color = Style.mapColor(colorKeyInactiveOvercharged)
				else:
					WaveDelayRect.color = Style.mapColor(colorKeyInactive)
	
func propertyChanged(property: String, oldValue, newValue):
	match property:
		"monsters.wavecooldown":
			goalRectSize = maxSpawnRectSize * clamp(newValue / Data.of("monsters.timebetweenwaves"), 0.0, 1.0)
		"keeper.insidestation":
			keeperInStation = newValue
			if keeperInStation:
				$Flare.visible = Data.of("monsters.wavepresent")
		"monsters.cycle":
			$WaveLabel.text = str(min(99, newValue + 1))
		"monsters.wavepresent":
			if visible:
				if newValue:
					switchFlare()
				else:
					if GameWorld.isUpgradeLimitAvailable("hostile"):
						$WaveEndSound.playDelayed(1.0)
					stopFlare()
		"wavemeter.stage":
			match int(newValue):
				1, 2:
					size.x = 7
					$BarBackground.visible = true
					MonsterSpawnRect.visible = true
					var delayStage = Data.of("wavemeter.delaystage")
					if delayStage > 0:
						showDelayRect(delayStage)
					continue
				2:
					Data.listen(self, "monsters.cycle", true)
					$WaveLabel.visible = true
					size.x += 2
					$BarBackground.rect_position.x += 12
					$Normal.rect_position.x += 12
					$Flare.rect_position.x += 12
			
			emit_signal("request_rebuild")

		"wavemeter.delaystage":
			if $BarBackground.visible and newValue > 0:
				showDelayRect(newValue)
		"game.over":
			if newValue == "won" or newValue == "lost":
				stopFlare()

func stopFlare():
	$MonsterSpawnTween.stop_all()
	$MonsterSpawnTween.remove_all()
	$Flare.visible = false
	

func showDelayRect(stage: int):
	WaveDelayRect.visible = true
	delayRectSize = rectSizes[stage - 1]
	$BarBackground.texture = textures[stage]
	$BarBackground.rect_position.y = 2

func switchFlare():
	if Data.of("monsters.wavepresent"):
		var delay: float
		if keeperInStation:
			$Flare.visible = true
			delay = 0.3
		else:
			$Flare.visible = not $Flare.visible
			if $Flare.visible:
				Audio.sound("alarm")
				delay = 0.1
			else:
				delay = 0.9
				
			
		$MonsterSpawnTween.interpolate_callback(self, delay, "switchFlare")
		$MonsterSpawnTween.start()
	else:
		$Flare.visible = false

func pauseChanged():
	if GameWorld.paused:
		$MonsterSpawnTween.stop_all()
	else:
		$MonsterSpawnTween.resume_all()
