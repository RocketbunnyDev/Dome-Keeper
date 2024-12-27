extends Node

var lastMonsters: = []
var allSnippets: = []
var allowedMonsters = null

var DEFAULT_WAVE: Wave

func _ready():
	DEFAULT_WAVE = Wave.new()
	var s = WaveSnippet.new()
	if randf() > 0.5:
		s.addEntry(WaveEntry.new("add.walker.left"))
	else:
		s.addEntry(WaveEntry.new("add.walker.right"))
	DEFAULT_WAVE.addSnippet(s)
	
	var waveData: = File.new()
	var err = waveData.open("res://wavepart.txt", File.READ)
	if err == OK:
		while not waveData.eof_reached():
			var line: String = waveData.get_line()
			if line.strip_edges().length() > 1:
				var snippet = WaveSnippet.new()
				for entry in str2var(line):
					var e = WaveEntry.new(entry)
					snippet.addEntry(e)
				snippet.addEntry(WaveEntry.new("wait.2"))
				allSnippets.append(snippet)
	waveData.close()
	








func setAllowedMonsters(allowedMonsters: Array):
	self.allowedMonsters = allowedMonsters

func generateWave(baseWeight: float, weightModifier: float)->Wave:
	var goalWeight = baseWeight * weightModifier
	
	var allowedSnippets: = []
	for snippet in allSnippets:
		var ok: = true
		
		for monster in snippet.monsters:
			if Data.of(monster + ".minRunWeight") > baseWeight:
				ok = false
				break
			if allowedMonsters and not allowedMonsters.has(monster):
				ok = false
				break
			if lastMonsters.size() > 0 and not Data.ofOr(monster + ".repeatable", true):
				if lastMonsters[0].has(monster):
					ok = false
					break
		if ok:
			allowedSnippets.append(snippet)
	
	if allowedSnippets.empty():
		return DEFAULT_WAVE
	
	var currentWave = Wave.new()
	var failsafe: = 100
	var deviation = 0.1
	var maxWeight = goalWeight * (1.0 + deviation) + 5
	var minWeight = goalWeight * (1.0 - deviation) - 5
	while true:
		if currentWave.getWeight() >= minWeight and currentWave.getWeight() <= maxWeight:
			return currentWave
		
		failsafe -= 1
		if failsafe == 0:
			if deviation == 0.1:
				deviation = 0.2
				maxWeight = goalWeight * (1.0 + deviation) + 5
				minWeight = goalWeight * (1.0 - deviation) - 5
				failsafe = 100
			else:
				Logger.warn("failed to generate wave", "WaveGenerator.generateWave", {"goalWeight": goalWeight, "currentWeight": currentWave.getWeight(), "currentWaveSize": currentWave.entries.size(), "allowedSnippets": allowedSnippets})
				if currentWave.getMonsterCount() == 0:
					return DEFAULT_WAVE
				else:
					return currentWave
		
		var flipWeight: = 0.5
		for _i in min(allowedSnippets.size(), 5):
			var snippet = allowedSnippets[randi() % allowedSnippets.size()]
			if randf() > flipWeight:
				snippet.flipVariants()
				if flipWeight < 0.4:
					flipWeight += 0.2
				else:
					flipWeight += 0.1
			else:
				if flipWeight > 0.6:
					flipWeight -= 0.2
				else:
					flipWeight -= 0.1
			var newW = currentWave.getWeightWithSnippet(snippet)
			if newW < maxWeight:
				currentWave.addSnippet(snippet.duplicate())
				currentWave.weight = newW
				for monster in snippet.monsters:
					if Data.ofOr(monster + ".single", false):
						allowedSnippets.erase(snippet)
						break
				break
	
	return DEFAULT_WAVE

func waveFinished(wave: Wave):
	if not wave:
		return 
	
	var monsters: = []
	for snippet in wave.snippets:
		for monster in snippet.monsters:
			if not monsters.has(monster):
				monsters.append(monster)
	
	lastMonsters.push_front(monsters)
	if lastMonsters.size() > 2:
		lastMonsters.pop_back()


