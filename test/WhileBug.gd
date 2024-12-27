extends Node2D


var gadgetChoicesPerArtifact: = 3

func _ready()->void :
	var offer: = []
	var found: = true
	while offer.size() < gadgetChoicesPerArtifact and found:
		print("entered")
		found = false
	print("not entered")
