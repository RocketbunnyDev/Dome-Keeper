extends "res://content/gadgets/CellarGadget.gd"

var producing: = false
var hasMine: = false
var growth: = 0.0
var grownAfter: = 0.0
var timePerFlame: = 0.0

var flameCount: int

func _ready():
	flameCount = $Flames.get_child_count() + 1
	for c in $Flames.get_children():
		c.connect("animation_finished", self, "continueFlameAnimation", [c])
		c.visible = false
	addMine()
	
	Style.init(self)
	
	Level.addTutorial(self, "blastmining")
	
	Achievements.addIfOpen(self, "BLASTMINING_USE")

func serialize()->Dictionary:
	var data = .serialize()
	data["producing"] = producing
	data["hasMine"] = hasMine
	data["growth"] = growth
	data["grownAfter"] = grownAfter
	data["timePerFlame"] = timePerFlame
	data["flameCount"] = flameCount
	return data

func deserialize(data: Dictionary):
	.deserialize(data)
	producing = data["producing"]
	hasMine = data["hasMine"]
	growth = data["growth"]
	grownAfter = data["grownAfter"]
	timePerFlame = data["timePerFlame"]
	flameCount = data["flameCount"]
	
	if hasMine:
		addMine()
	else:
		$Mine.visible = false
		
	if producing:
		$Flames.visible = true
		var flames_to_light = int(growth * flameCount / grownAfter)
		for c in $Flames.get_children():
			if flames_to_light > 0:
				c.visible = true
				c.play("start")
			else:
				c.visible = false
			flames_to_light -= 1

func continueFlameAnimation(f):
	f.play("run")

func _process(delta):
	if GameWorld.softPaused():
		return 
	
	if growth < grownAfter:
		growth += delta
		timePerFlame -= delta
		if timePerFlame <= 0.0:
			timePerFlame = grownAfter / float(flameCount)
			var pitch: = 1.0
			for c in $Flames.get_children():
				if not c.visible:
					c.visible = true
					c.play("start")
					$FlameOn.pitch_scale = pitch
					$FlameOn.play()
					break
				pitch += 0.05
		return 
	
	if producing:
		addMine()
	elif not hasMine:
		producing = true
		growth = 0.0
		grownAfter = GameWorld.getTimeBetweenWaves() * float(Data.of("blastMining.growthTime"))
		$Flames.visible = true
		for c in $Flames.get_children():
			c.visible = false

func addMine():
	$MineReady.play()
	$Mine.visible = true
	$Mine.frame = 0
	$Mine.playing = true
	find_node("Bomb").frame = int(Data.of("blastMining.bombsize"))
	$Flames.visible = false
	producing = false
	hasMine = true

func canFocusUse()->bool:
	return hasMine

func useHold(keeper: Keeper):
	useHit(keeper)

func useHit(keeper: Keeper)->bool:
	if hasMine:
		for _i in Data.of("blastMining.bombs"):
			var mine = preload("res://content/gadgets/blastMining/Mine.tscn").instance()
			mine.position = $MinePosition.global_position
			Level.map.addDrop(mine)
			keeper.attachCarry(mine)
		hasMine = false
		$Mine.visible = false
		$MinePickup.play()
		return true
	return false

func _on_Mine_animation_finished():
	$Usable.updateFocus()


func hasMine():
	return hasMine
