extends "res://content/gadgets/CellarGadget.gd"

var producing: = false
var resourceCount: = 0
var inTransition: = false
var growth: = 0.0
var grownAfter: = 0.0
var additionalGrownAfter: = 0.0
var particleCooldown: = 0.0

var CondensingParticles

func _ready():
	$ResourcePosition / FinishedParticles.emitting = false
	if $Sprite.flip_h:
		CondensingParticles = preload("res://content/gadgets/condenser/CondensingParticlesLeft.tscn").instance()
		add_child(CondensingParticles)
	else:
		CondensingParticles = preload("res://content/gadgets/condenser/CondensingParticlesRight.tscn").instance()
		add_child(CondensingParticles)
	finishProduction()
	
	$Amb.play()
	
	Style.init(self)
	
	Achievements.addIfOpen(self, "CONDENSER_USE")

func serialize()->Dictionary:
	var data = .serialize()
	data["producing"] = producing
	data["resourceCount"] = resourceCount
	data["inTransition"] = inTransition
	data["growth"] = growth
	data["grownAfter"] = grownAfter
	data["additionalGrownAfter"] = additionalGrownAfter
	data["particleCooldown"] = particleCooldown
	return data

func deserialize(data: Dictionary):
	.deserialize(data)
	producing = data["producing"]
	resourceCount = data["resourceCount"]
	inTransition = data["inTransition"]
	growth = data["growth"]
	grownAfter = data["grownAfter"]
	additionalGrownAfter = data["additionalGrownAfter"]
	particleCooldown = data["particleCooldown"]

	if inTransition:
		$Sprite.play("release")
		addWater()
	
	if resourceCount == 0:
		$ResourcePosition / FinishedParticles.emitting = false
		CondensingParticles.emitting = true
		$Sprite.play("active")
	
func _process(delta):
	if GameWorld.softPaused():
		return 
	


	
	if producing:
		if additionalGrownAfter > 0.0:
			additionalGrownAfter -= delta
		elif growth < grownAfter:
			growth += delta
		else:
			finishProduction()
			return 
	elif resourceCount < Data.of("condenser.waterstorage"):
		$Active.play()
		producing = true
		growth = 0.0
		grownAfter = GameWorld.getTimeBetweenWaves() * float(Data.of("condenser.growthTime"))
		CondensingParticles.emitting = true
	
	if Data.of("condenser.autoovercharge"):
		for o in get_tree().get_nodes_in_group("overchargable"):
			if o.canOvercharge():
				
				Data.changeByInt("inventory.water", 1)
				o.overcharge()
				additionalGrownAfter = Data.of("condenser.overchargeDelay") * GameWorld.getTimeBetweenWaves()
				return 

func finishProduction():
	resourceCount += 1
	CondensingParticles.emitting = false
	producing = false
	inTransition = true
	$Sprite.play("release_" + str(resourceCount))
	$WaterSpawn.play()
	$Active.stop()
	addWater()

func canFocusUse()->bool:
	return resourceCount >= 1

func useHold(keeper: Keeper):
	useHit(keeper)

func useHit(keeper: Keeper)->bool:
	if resourceCount >= 1:
		for _i in range(0, resourceCount):
			var res = Data.DROP_SCENES.get(CONST.WATER).instance()
			res.type = CONST.WATER
			res.position = $ResourcePosition.global_position
			Level.map.addDrop(res)
			keeper.attachCarry(res)
		resourceCount = 0
		$ResourcePosition / FinishedParticles.emitting = false
		$Sprite.play("active")
		$WaterPickup.play()
		Backend.event("gadget_used", {"gadget": "condenser"})
		return true
	return false

func addWater():
	inTransition = false
	if Data.of("condenser.autoCollect") and resourceCount > 0:
		Data.changeByInt("inventory.water", resourceCount)
		Data.changeByInt("inventory.totalwater", 1)
		resourceCount = 0
		$Sprite.play("active")
		$WaterPickup.play()
	else:
		$ResourcePosition / FinishedParticles.emitting = true
		$Usable.updateFocus()
