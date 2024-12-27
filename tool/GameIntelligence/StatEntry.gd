extends VBoxContainer

signal pin(filteredRuns, filter)

func updateStats(filteredRuns: Array, filter: Dictionary):
	visible = true
	
	var wins: = 0
	var losses: = 0
	var unfinished: = 0
	var battleAbilityUses: = []
	var runtimes: = []
	var durations: = []
	for run in filteredRuns:
		var state = run.get("state", "")
		match state:
			"won": wins += 1
			"lost": losses += 1
			_:
				unfinished += 1
				continue
		
		if run.has("cycles"):
			var cycles = run.get("cycles")
			if cycles.size() > 0:
				runtimes.append(cycles.back().get("data", {}).get("runtime", 0))
		durations.append(run.get("duration", 0))
		
		if run.has("battleAbility"):
			battleAbilityUses.append(run.get("battleAbility").size())
	
	battleAbilityUses.sort()
	runtimes.sort()
	durations.sort()
	
	find_node("SessionCountLabel").text = "%.0f / %.0f" % [unfinished + wins + losses, wins + losses]
	find_node("WonCountLabel").text = "%.0f / %.0f" % [wins, losses]
	if wins > 0 or losses > 0:
		find_node("WinrateLabel").text = "%.0f" % (100 * wins / float(wins + losses)) + "%"
		find_node("FinishRateLabel").text = "%.0f" % (100 * (wins + losses) / float(unfinished + wins + losses)) + "%"
	else:
		find_node("WinrateLabel").text = "-"
		find_node("FinishRateLabel").text = "-"
	
	var medianRunLength = runtimes[runtimes.size() / 2]
	var averageRunLength: = 0.0
	for runtime in runtimes:
		averageRunLength += runtime
	averageRunLength /= float(runtimes.size())
	find_node("AverageRunLengthLabel").text = "%02.0f:%02.f" % [averageRunLength / 60, fmod(averageRunLength, 60)]
	find_node("MedianRunLengthLabel").text = "%02.0f:%02.f" % [medianRunLength / 60, fmod(medianRunLength, 60)]

	var medianSessionLength = durations[durations.size() / 2] * 0.001
	var averageSessionLength: = 0.0
	for runtime in durations:
		averageSessionLength += runtime * 0.001
	averageSessionLength /= float(durations.size())
	find_node("AverageSessionLengthLabel").text = "%02.0f:%02.f" % [averageSessionLength / 60, fmod(averageSessionLength, 60)]
	find_node("MedianSessionLengthLabel").text = "%02.0f:%02.f" % [medianSessionLength / 60, fmod(medianSessionLength, 60)]
	
	var medianBattleAbilityUses = battleAbilityUses[battleAbilityUses.size() / 2]
	var averageBattleAbilityUses: = 0.0
	for uses in battleAbilityUses:
		averageBattleAbilityUses += uses
	averageBattleAbilityUses /= float(battleAbilityUses.size())
	find_node("AverageBattleAbilityUsesLabel").text = "%.0f" % averageBattleAbilityUses
	find_node("MedianBattleAbilityUsesLabel").text = "%.0f" % medianBattleAbilityUses
	
	var filterString: = ""
	for entry in filter:
		if filter[entry].size() > 0:
			if filterString.length() > 0:
				filterString += ";   "
			filterString += entry + ": "
			for i in filter[entry].size():
				if i > 0:
					filterString += ", "
				filterString += filter[entry][i]
				
	find_node("FilterLabel").text = filterString
	
	if find_node("PinStatsButton").visible:
		if find_node("PinStatsButton").is_connected("pressed", self, "emit_signal"):
			find_node("PinStatsButton").disconnect("pressed", self, "emit_signal")
		find_node("PinStatsButton").connect("pressed", self, "emit_signal", ["pin", filteredRuns, filter])

func _on_DeleteStatsButton_pressed():
	get_parent().queue_free()
