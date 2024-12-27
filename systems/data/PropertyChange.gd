extends Reference

class_name PropertyChange

var key: String
var keyClass: String
var keyName: String
var cumulative: bool = false
var multiplicative: bool = false
var doesRepair: bool = false
var hidden: bool = false
var value

func _init(line: String = ""):
	if line != "":
		var splits = line.split("=")
		key = splits[0]
		var isPlusCumulative = key.ends_with("+")
		var isMinusCumulative = key.ends_with("-")
		var isMultiplicative = key.ends_with("*")
		if isPlusCumulative or isMinusCumulative:
			cumulative = true
			key = key.substr(0, key.length() - 1)
		elif isMultiplicative:
			multiplicative = true
			key = key.substr(0, key.length() - 1)
		
		key = key.to_lower().strip_edges()
		var firstDot: int = key.find(".")
		keyClass = key.substr(0, firstDot)
		keyName = key.substr(firstDot + 1)
		if splits[1].find("/") != - 1:
			var valueSplit = splits[1].split("/")
			value = str2var(valueSplit[0])
			if valueSplit[1] == "h":
				hidden = true
		else:
			value = str2var(splits[1])
		if isMinusCumulative:
			value = - value
		if key == "dome.baserepair" or key == "dome.healthfractionrepair":
			doesRepair = true

func applyValue(oldValue):
	var newVal
	if cumulative:
		newVal = oldValue + value
	elif multiplicative:
		newVal = oldValue * value
	else:
		newVal = value
	return newVal

func duplicate()->PropertyChange:
	var p = get_script().new()
	p.key = key
	p.keyClass = keyClass
	p.keyName = keyName
	p.cumulative = cumulative
	p.multiplicative = multiplicative
	p.doesRepair = doesRepair
	p.hidden = hidden
	p.value = value
	return p
