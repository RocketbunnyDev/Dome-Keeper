extends Reference

class_name WaveEntry

var type: String
var breed: String
var variant
var s: = ""

func _init(data: String = ""):
	var d = data.split(".")
	type = d[0]
	if type == "add":
		breed = d[1]
		variant = d[2]
		s = breed + "_" + variant
	elif type == "wait":
		breed = d[1]
		s = type + "_" + breed

func _to_string():
	return s

func duplicate()->WaveEntry:
	var dup = get_script().new()
	dup.type = type
	dup.breed = breed
	dup.variant = variant
	dup.s = s
	return dup
