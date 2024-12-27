extends PanelContainer

var viewOption: = 2

var monsterColors: = {
	"walker": Color("001219"), 
	"rockman": Color("005f73"), 
	"mucker": Color("0a9396"), 
	"beast": Color("94d2bd"), 
	"worm": Color("e9d8a6"), 
	"tick": Color("31572c"), 
	"bigtick": Color("4f772d"), 
	"driller": Color("90a955"), 
	"flyer": Color("ee9b00"), 
	"bolter": Color("ca6702"), 
	"shifter": Color("bb3e03"), 
	"diver": Color("ae2012"), 
	"butterfly": Color("9b2226"), 
}

var filteredRuns: Array

func updateView(filteredRuns: Array):
	visible = true
	self.filteredRuns = filteredRuns
	
	var damageCount: = []
	var monsterCount: = []
	var wavesCount: = []
	var globalDamage: = 0
	var globalMonsterCount: = 0
	for _i in range(0, 21):
		damageCount.append({})
		monsterCount.append({})
		wavesCount.append(0)
	
	var waveStarted
	for run in filteredRuns:
		for entry in run.get("waves"):
			match entry.type:
				"wave_started":
					waveStarted = entry
				"wave_finished":
					if not waveStarted:
						continue
					var finishedData = entry.get("data", {})
					var startedData = waveStarted.get("data", {})
					var waveIndex = finishedData.get("waveIndex")
					if waveIndex > 20:
						continue
					
					wavesCount[waveIndex] += 1
					
					for waveEntry in startedData.get("wave"):
						var type = waveEntry.substr(0, waveEntry.find("_"))
						if type == "wait":
							continue
						monsterCount[waveIndex][type] = 1 + monsterCount[waveIndex].get(type, 0)
						globalMonsterCount += 1
					
					var damages = finishedData.get("damageBySource")
					for waveEntry in damages:
						var type = waveEntry.to_lower()
						var damage = damages[waveEntry]
						damageCount[waveIndex][type] = damage + damageCount[waveIndex].get(type, 0)
						globalDamage += damage
	
	var mv = find_node("MonsterBarContainer")
	for c in mv.get_children():
		c.queue_free()
	
	var x: = 40
	var xAtStart: = 0
	var accumulatedDamage: = 0.0
	var accumulatedCount: = 0.0
	var accumulatedDamagePerMonster: = {}
	var accumulatedMonsterCount: = {}
	for waveIndex in monsterCount.size():
		if monsterCount[waveIndex].size() == 0:
			break
		
		var runCount = wavesCount[waveIndex]
		
		var totalMonsters: = 0
		var totalDamage: = 0
		for monster in monsterCount[waveIndex]:
			totalMonsters += monsterCount[waveIndex][monster]
			totalDamage += damageCount[waveIndex].get(monster, 0)
		
		xAtStart = x
		for monster in monsterCount[waveIndex]:
			var count: float = monsterCount[waveIndex][monster]
			if count == 0:
				continue
			
			var damage = damageCount[waveIndex].get(monster, 0)
			var line: = Line2D.new()
			line.default_color = monsterColors.get(monster, Color.black)
			line.width = 80
			var damageOut: = 0.0
			var y = 0
			match viewOption:
				0:
					damageOut = damage
					y = 0.05 * damageOut
				1:
					if count > 0:
						damageOut = damage / float(count)
					count /= float(runCount)
					y = 1.6 * damageOut
				2:
					if totalDamage > 0:
						damageOut = damage / float(totalDamage)
					y = 500 * damageOut
				3:
					if count > 0:
						accumulatedDamagePerMonster[monster] = accumulatedDamagePerMonster.get(monster, 0) + damage / float(count)
					damageOut = accumulatedDamagePerMonster[monster]
					y = 0.2 * damageOut
					
					count /= float(runCount)
					accumulatedMonsterCount[monster] = accumulatedMonsterCount.get(monster, 0) + count
					count = accumulatedMonsterCount[monster]
			
			line.add_point(Vector2(x, 740))
			y = 740 - y
			line.add_point(Vector2(x, y))
			mv.add_child(line)
			
			var box = VBoxContainer.new()
			
			var label: = Label.new()
			if viewOption == 2:
				label.text = "%.0f" % (100 * damageOut) + "%"
			else:
				label.text = "~%.0f" % damageOut
			box.add_child(label)
			
			label = Label.new()
			if viewOption == 1 or viewOption == 3:
				label.text = "# %.1f" % count
			else:
				label.text = "# " + str(count)
			box.add_child(label)
			
			label = Label.new()
			label.text = monster
			box.add_child(label)
			
			box.rect_position.x = x + 10 - line.width * 0.5
			box.rect_position.y = 760
			mv.add_child(box)
			
			x += line.width + 10
		
		accumulatedDamage += totalDamage / float(runCount)
		accumulatedCount += totalMonsters / float(runCount)
		
		var monstersOut: = ""
		var damageOut: = ""
		match viewOption:
			0:
				monstersOut = str(totalMonsters)
				damageOut = str(totalDamage)
			1:
				if runCount > 0:
					damageOut = "%.1f" % (totalDamage / float(runCount))
					monstersOut = "%.1f" % (totalMonsters / float(runCount))
			2:
				if globalDamage > 0:
					damageOut = "%.1f" % (totalDamage / float(globalDamage))
				if globalMonsterCount > 0:
					monstersOut = "%.1f" % (totalMonsters / float(globalMonsterCount))
			3:
				monstersOut = "%.1f" % (accumulatedCount)
				damageOut = "%.1f" % (accumulatedDamage)
		
		var box = VBoxContainer.new()
		box.grow_horizontal = Control.GROW_DIRECTION_BOTH
		var label: = Label.new()
		label.align = Label.ALIGN_CENTER
		label.add_font_override("font", preload("res://gui/fonts/FontNormal.tres"))
		label.text = "Wave " + str(waveIndex)
		box.add_child(label)
		label = Label.new()
		label.align = Label.ALIGN_CENTER
		var lastRunCount = wavesCount[waveIndex - 1]
		var s = str(wavesCount[waveIndex])
		if waveIndex > 0:
			s += " (%.0f)" % (runCount - lastRunCount)
		label.text = s + " times"
		box.add_child(label)
		label = Label.new()
		label.align = Label.ALIGN_CENTER
		var lastRunPercentage = 100 * wavesCount[waveIndex - 1] / float(wavesCount[0])
		var thisRunPercentage = 100 * runCount / float(wavesCount[0])
		label.text = "%.0f" % thisRunPercentage + "%" + "(%.1f" % (thisRunPercentage - lastRunPercentage) + "%)"
		box.add_child(label)
		label = Label.new()
		label.align = Label.ALIGN_CENTER
		label.text = "# " + monstersOut + " monsters"
		box.add_child(label)
		label = Label.new()
		label.align = Label.ALIGN_CENTER
		label.text = "~" + damageOut + " damage"
		box.add_child(label)
		
		box.rect_position.x = xAtStart + (x - xAtStart) * 0.5
		box.rect_position.y = 80
		mv.add_child(box)
		
		var line: = Line2D.new()
		line.default_color = Color.white
		line.width = 4
		line.add_point(Vector2(x + 40, 830))
		line.add_point(Vector2(x + 40, 80))
		mv.add_child(line)
		
		x += 100
	
	mv.rect_min_size = Vector2(x, 800)


func _on_TotalDamageButton_pressed():
	viewOption = 0
	updateView(filteredRuns)

func _on_AverageDamageButton_pressed():
	viewOption = 1
	updateView(filteredRuns)

func _on_RelativeDamageButton_pressed():
	viewOption = 2
	updateView(filteredRuns)

func _on_AccumulatedDamageButton_pressed():
	viewOption = 3
	updateView(filteredRuns)
