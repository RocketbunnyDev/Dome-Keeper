extends Control

const tutorialScenes: = {
	"sword_intro": preload("res://content/weapons/sword/tutorial/SwordTutorial.tscn"), 
	"repair1": preload("res://content/dome/tutorials/RepairTutorial1.tscn"), 
	"repair2": preload("res://content/dome/tutorials/RepairTutorial2.tscn"), 
	"stationdefend": preload("res://content/dome/tutorials/StationTutorial.tscn"), 
	"keeper1_pickup": preload("res://content/keeper/keeper1/Keeper1PickupTutorial.tscn"), 
	"keeper1_drop": preload("res://content/keeper/keeper1/Keeper1DropTutorial.tscn"), 
	"orchard": preload("res://content/gadgets/orchard/FruitTutorial.tscn"), 
	"repellent": preload("res://content/gadgets/repellent/RepellentTutorial.tscn"), 
	"probe": preload("res://content/gadgets/probe/ProbeTutorial.tscn"), 
	"teleporter_take": preload("res://content/gadgets/teleporter/TeleporterTakeTutorial.tscn"), 
	"teleporter_teleport": preload("res://content/gadgets/teleporter/TeleporterTeleportTutorial.tscn"), 
	"teleporter_carry": preload("res://content/gadgets/teleporter/TeleporterCarryTutorial.tscn"), 
	"blastmining": preload("res://content/gadgets/blastMining/BlastMiningTutorial.tscn"), 
	"onewayteleporter": preload("res://content/caves/teleportcave/OneWayTeleporterTutorial.tscn"), 
	"drillbotcarry": preload("res://content/gadgets/drillbot/DrillbotCarryTutorial.tscn"), 
	"drillbothandling": preload("res://content/gadgets/drillbot/DrillbotHandlingTutorial.tscn"), 
	"drillbotsleeping": preload("res://content/gadgets/drillbot/DrillbotSleepingTutorial.tscn"), 
	"mineraltree": preload("res://content/caves/seedcave/MineralTreeTutorial.tscn"), 
	"assessor_intro": preload("res://content/keeper/keeper2/tutorial/AssessorTutorial.tscn"), 
	"assessor_reflect": preload("res://content/keeper/keeper2/tutorial/AssessorReflectTutorial.tscn"), 
	"assessor_bundle": preload("res://content/keeper/keeper2/tutorial/AssessorBundleTutorial.tscn"), 
}

var tutorials: = {}
var currentTutorial: Tutorial = null
var active: = false

func clear():
	for c in get_children():
		c.queue_free()
	currentTutorial = null
	tutorials.clear()
	
func addIfOpen(tutorialParent, id: String):
	if not tutorialScenes.has(id):
		Logger.error("tutorial id is unknown", "Tutorials.addIfOpen", id)
		return 
	
	if GameWorld.tutorialStages.get(id, 0) < CONST.TUTORIAL_TIMEDOUT:
		addTutorial(tutorialParent, id)
		
func addTutorial(tutorialParent, id):
	Logger.info("adding tutorial " + id)
	GameWorld.tutorialStages[id] = CONST.TUTORIAL_LISTENING
	var tut = tutorialScenes.get(id).instance()
	tut.id = id
	tut.tutorialParent = tutorialParent
	tutorials[id] = tut
	add_child(tut)

func _process(delta):
	if not active:
		return 
	
	var wave = Data.of("monsters.wavepresent")
	var waveCooldown = Data.of("monsters.waveCooldown")
	if currentTutorial == null:
		if GameWorld.paused:
			return 
		for tutId in tutorials.duplicate():



			
			var tut = tutorials[tutId]
			if not tut.triggerDuringWave and wave:
				continue
			
			if tut.listeningDelay >= 0.0:
				tut.listeningDelay -= delta
				continue
			
			if tut.minTimeToWave > 0 and tut.minTimeToWave > waveCooldown:
				continue
			
			tut.process_confirm(delta)
			if tut.confirmed:
				Logger.info("confirmed tutorial before appearing " + tut.id)
				GameWorld.tutorialStages[tut.id] = CONST.TUTORIAL_CONFIRMED
				GameWorld.persistTutorialStages()
				tutorials.erase(tut.id)
				tut.queue_free()
			else:
				if tut.triggered or tut.process_trigger(delta):
					Logger.info("triggered tutorial " + tut.id)
					tut.moveIn()
					currentTutorial = tut
					
					
					tutorials.erase(currentTutorial.id)
					GameWorld.tutorialStages[tut.id] = CONST.TUTORIAL_DISPLAYING
					return 
	else:
		if currentTutorial.isFullscreen:
			if currentTutorial.confirmed:
				currentTutorialConfirmed()
		elif not GameWorld.paused:
			if currentTutorial.moveOutAfter > 0.0:
				currentTutorial.moveOutAfter -= delta
				if currentTutorial.confirmed:
					currentTutorialConfirmed()
				else:
					currentTutorial.process_confirm(delta)
			elif not currentTutorial.isFullscreen:
				Logger.info("timed out tutorial " + currentTutorial.id)
				currentTutorial.moveOut()
				GameWorld.tutorialStages[currentTutorial.id] = CONST.TUTORIAL_TIMEDOUT
				GameWorld.persistTutorialStages()
				currentTutorial = null

func currentTutorialConfirmed():
	Logger.info("confirmed tutorial " + currentTutorial.id)
	currentTutorial.moveOut()
	GameWorld.tutorialStages[currentTutorial.id] = CONST.TUTORIAL_CONFIRMED
	GameWorld.persistTutorialStages()
	currentTutorial = null

func activate():
	active = true

func deactivate():
	active = false
	if currentTutorial:
		currentTutorial.moveOut()
