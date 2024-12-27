extends VBoxContainer

const titles: = {
	"waves_survived": "level.gameover.stats.wavessurvived", 
	"monsters_killed": "level.gameover.stats.monsterskilled", 
	"time": "level.gameover.stats.timeplayed", 
	"tiles_destroyed": "level.gameover.stats.destroyedblocks", 
	"travelled_distance": "level.gameover.stats.distancetravelled", 
	"resources_mined": "level.gameover.stats.resourcesmined", 
	"difficulty": "level.gameover.stats.difficulty", 
	"mapsize": "level.gameover.stats.mapsize", 
	"additionalgadget": "level.gameover.stats.additionalgadget", 


}

func init(showDifficulty: = true):
	GameWorld.runStats["time"] = ("%.0f" % (GameWorld.runTime / 60)) + tr("level.gameover.stats.timeplayed.unit")
	GameWorld.runStats["travelled_distance"] = ("%.1f" % (GameWorld.travelledDistance * CONST.PixelPerKilometer)) + "km"
	
	if showDifficulty:
		var diffStr: = ""
		match int(GameWorld.difficulty):
			2: diffStr = "loadout.difficulty.hard"
			0: diffStr = "loadout.difficulty.medium"
			- 1: diffStr = "loadout.difficulty.easy"
			- 2: diffStr = "loadout.difficulty.veryeasy"
		GameWorld.runStats["difficulty"] = diffStr
	else:
		titles.erase("difficulty")
	
	if GameWorld.gameMode == CONST.MODE_RELICHUNT:
		var sizeStr: = ""
		match GameWorld.lastMapSize:
			CONST.MAP_SMALL: sizeStr = "loadout.mapsize.small"
			CONST.MAP_MEDIUM: sizeStr = "loadout.mapsize.medium"
			CONST.MAP_LARGE: sizeStr = "loadout.mapsize.large"
			CONST.MAP_HUGE: sizeStr = "loadout.mapsize.huge"
		GameWorld.runStats["mapsize"] = sizeStr
	else:
		titles.erase("mapsize")
	
	if GameWorld.gadgetToKeep == "" or GameWorld.gameMode == CONST.MODE_PRESTIGE:
		titles.erase("additionalgadget")
	else:
		GameWorld.runStats["additionalgadget"] = "upgrades." + GameWorld.gadgetToKeep + ".title"
	
	for key in titles:
		var box = HBoxContainer.new()
		var value = GameWorld.runStats.get(key, 0)
		var l = Label.new()
		l.text = tr(titles[key]) + ": "
		box.add_child(l)
		l = Label.new()
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		l.align = Label.ALIGN_RIGHT
		l.text = str(value)
		box.add_child(l)
		$StatContainer.add_child(box)
