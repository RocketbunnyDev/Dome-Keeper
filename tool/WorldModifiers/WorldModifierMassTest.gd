extends Node

func _ready():
	var l = Loadout.new("null", "null", "null", "null")
	var counts: = {}
	var classes: = {}
	for i in 100000:
		l.generateModifiers()
	
		for m in l.worldModifiers:
			counts[m] = 1 + counts.get(m, 0)
			classes[Data.worldModifiers[m]["class"]] = 1 + classes.get(Data.worldModifiers[m]["class"], 0)
	
	for m in classes:
		print(m + ": " + str(classes[m]))
	print()
	for m in counts:
		print(m + ": " + str(counts[m]))
