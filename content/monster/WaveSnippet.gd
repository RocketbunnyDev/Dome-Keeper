extends Reference

class_name WaveSnippet



var monsters: = []
var weight: = - 1.0
var entries: = []

func addEntry(entry: WaveEntry):
	if entry.type == "add" and not monsters.has(entry.breed):
		monsters.append(entry.breed)
	entries.append(entry)
	weight = - 1.0

func flipVariants():
	for e in entries:
		match e.variant:
			"left": e.variant = "right"
			"right": e.variant = "left"
			"left_low": e.variant = "right_low"
			"right_low": e.variant = "left_low"
			"left_high": e.variant = "right_high"
			"right_high": e.variant = "left_high"

func getWeight(w_entries: = entries, force: = false)->float:
	if not force and weight != - 1.0:
		return weight
	
	var weightTimeMods = Data.gameProperties.get("monsters.weightModTimeBetweenMonsters".to_lower())
	
	weight = 0
	var prevWaitMod: = 1.0
	for entry in w_entries:
		var thisWeight: = 0
		match entry.type:
			"add":
				thisWeight += Data.gameProperties.get(entry.breed + ".weight")
			"wait":
				prevWaitMod = weightTimeMods[int(entry.breed)]
		thisWeight *= prevWaitMod
		weight += thisWeight
	return weight

func _to_string()->String:
	return str(entries)

func duplicate()->WaveSnippet:
	var dup = get_script().new()
	dup.monsters = monsters.duplicate()
	dup.weight = weight
	dup.entries = []
	for e in entries:
		dup.entries.append(e.duplicate())
	return dup
