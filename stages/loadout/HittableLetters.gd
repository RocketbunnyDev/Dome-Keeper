extends HBoxContainer

var LETTER = preload("res://stages/loadout/HittableLetter.tscn")

var headline = tr("loadout.title")






func _ready():
	var i: = 0

	var lastSpace = headline.find_last(" ")
	for l in headline:
		var letter = LETTER.instance()
		letter.text = l
		if i > lastSpace:
			letter.dieAt = 100
		add_child(letter)







		i += 1

