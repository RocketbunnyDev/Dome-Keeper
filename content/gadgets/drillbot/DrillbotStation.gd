extends "res://content/gadgets/CellarGadget.gd"

var hasDrillbot: bool
var hasPlant: = false
var plantGrowth: = 0.0
var keeper
var remainingDrillbots: = 0

func _ready():
	Style.init(self)
	Data.listen(self, "drillbot.headcount", true)
	updateStation()
	
	Level.addTutorial(self, "drillbotcarry")

func serialize()->Dictionary:
	var data = .serialize()
	data["hasDrillbot"] = hasDrillbot
	data["hasPlant"] = hasPlant
	data["plantGrowth"] = plantGrowth
	data["remainingDrillbots"] = remainingDrillbots
	return data
	
func deserialize(data: Dictionary):
	.deserialize(data)
	hasDrillbot = data["hasDrillbot"]
	hasPlant = data["hasPlant"]
	plantGrowth = data["plantGrowth"]
	remainingDrillbots = data["remainingDrillbots"]
	updateStation()

func addDrillbot():
	if not hasDrillbot:
		$Sprite.play("open")
		$GlasOverlaySprite.play("open")
		$Sprite.animation = "plant"
		$Sprite.frame = 0
		$Sprite.playing = false

func propertyChanged(property: String, oldValue, newValue):
	var bots = get_tree().get_nodes_in_group("drillbots")

	match property:
		
		"drillbot.headcount":
			remainingDrillbots = newValue - bots.size()
			updateStation()

	for bot in bots:
		bot.station = self
		addDrillbot()

func useHold(keeper: Keeper):
	return useHit(keeper)

func canFocusUse()->bool:
	return hasDrillbot or hasPlant

func _process(delta):
	if hasDrillbot or GameWorld.softPaused():
		return 
	
	var growthTime = Data.of("drillbot.plantgrowthtime") * GameWorld.getTimeBetweenWaves()
	if not hasPlant and growthTime > 0.0:
		plantGrowth += delta
		if plantGrowth >= growthTime:
			growPlant()
		elif plantGrowth >= growthTime * 0.3:
			$Sprite.frame = 1

func growPlant():
	hasPlant = true
	$Sprite.frame = 2
	$FruitReadySound.play()

func useHit(keeper: Keeper)->bool:
	if hasDrillbot:
		$OpeningSound.play()
		hasDrillbot = false
		$Sprite.play("open")
		$GlasOverlaySprite.play("open")
		self.keeper = keeper
		return true
	elif hasPlant:
		hasPlant = false
		$Sprite.frame = 0
		plantGrowth = 0.0
		
		var treat = preload("res://content/drop/treat/Treat.tscn").instance()
		treat.position = $DropPosition.global_position
		Level.map.addDrop(treat)
		keeper.attachCarry(treat)
	return false

func updateStation():
	hasDrillbot = remainingDrillbots > 0
	if hasDrillbot:
		$Sprite.play("idle")
		$GlasOverlaySprite.play("default")
		

func _on_Sprite_animation_finished():
	if keeper and $Sprite.animation == "open":
		var drillbot = preload("res://content/gadgets/drillbot/Drillbot.tscn").instance()
		drillbot.position = $DropPosition.global_position
		Level.map.addDrop(drillbot)
		keeper.attachCarry(drillbot)
		drillbot.setDirection(Vector2.RIGHT if $Sprite.flip_h else Vector2.LEFT)
		$Sprite.animation = "plant"
		$Sprite.frame = 0
		$Sprite.playing = false
		keeper = null
		remainingDrillbots -= 1
		updateStation()
