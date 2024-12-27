extends Node

func _ready():
	var dir = Directory.new()
	dir.open("res://systems/localization/translations")
	dir.list_dir_begin()
	var regex = RegEx.new()
	regex.compile("\".*?\"")
	while true:
		var fileName = dir.get_next()
		if fileName == "":
			break
		if not fileName.begins_with(".") and not fileName.ends_with(".import"):
			if fileName.ends_with(".translation"):
				dir.remove("res://systems/localization/translations/" + fileName)
			else:
				var start = fileName.find("_") + 1
				var code = fileName.substr(start, fileName.find_last(".") - start)
				var file: = File.new()
				var lines: = []
				var err = file.open("res://systems/localization/translations/" + fileName, File.READ)
				if err == OK:
					var line = file.get_line()
					if line.count(",") == 1:
						print("not processing " + fileName + ", seems already processed")
						file.close()
						continue
					print("processing " + fileName)
					while not file.eof_reached():
						line = file.get_line()
						while line.count("\"") < 6 and not file.eof_reached():
							line += "\n" + file.get_line()
						var firstComma = line.find(",")
						var p1 = line.substr(0, firstComma)
						var p2 = line.substr(firstComma + 1)
						p2 = p2.substr(0, p2.find("\",\"") + 1)
						line = p1.replace("\"", "") + "," + p2
						lines.append(line)
				file.close()
				err = file.open("res://systems/localization/translations/" + fileName, File.WRITE_READ)
				if err == OK:
					file.store_string("keys," + code + "\n")
					for line in lines:
						file.store_string(line + "\n")
				file.close()
	
	var file: = File.new()
	var lines: = []
	var err = file.open("res://systems/localization/localization.csv", File.READ)
	if err == OK:
		while not file.eof_reached():
			var line = file.get_line()
			while line.count("\"") % 2 != 0 and not file.eof_reached():
				line += "\n" + file.get_line()
			var firstComma = line.find(",")
			var p1 = line.substr(0, firstComma)
			var p2 = line.substr(firstComma)
			p2 = p2.substr(0, p2.find_last(","))
			line = p1 + p2
			lines.append(line)
	file.close()
	err = file.open("res://systems/localization/translations/localization_en_US.csv", File.WRITE_READ)
	lines.pop_front()
	if err == OK:
		file.store_string("keys,en_US\n")
		for line in lines:
			file.store_string(line + "\n")
	file.close()
	
	
	get_tree().quit()
