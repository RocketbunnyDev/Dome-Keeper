extends Control

var indexColors: = []
var colorMap: = {}

func _ready():
	Style.init(self)
	
	Audio.set_bus_volume(Audio.BUS_MASTER, - 30)
	
	var indexImage = Image.new()
	var palette1Image = Image.new()
	var err1 = indexImage.load("res://systems/style/palettes/index_palette.png")
	var err2 = palette1Image.load("res://systems/style/palettes/palette_1_1.png")
	var yLength = indexImage.get_height() / 10
	var xLength = indexImage.get_width() / 10
	if err1 == OK and err2 == OK:
		indexImage.lock()
		palette1Image.lock()
		for x in xLength:
			for y in yLength:
				var key = Vector2(x * 10 + 5, (yLength - y - 1) * 10 + 5)
				var color = indexImage.get_pixelv(key)
				var r = round(255 * color.r)
				if abs(color.b - 240.0 / 255.0) <= 0.01 and not indexColors.has(r):
					indexColors.append(r)
					var lookupColor = palette1Image.get_pixelv(key)
					colorMap[lookupColor] = color
		indexImage.unlock()
		palette1Image.unlock()

func _on_RunButton_pressed():
	find_node("RunButton").disabled = true

func _on_FolderButton_pressed():
	find_node("FileDialog").popup()
	find_node("FileDialog").popup()

func _on_FileDialog_dir_selected(dirPath):
	var dir = Directory.new()
	dir.open(dirPath)
	dir.list_dir_begin()
	while true:
		var file = dir.get_next()
		if file == "":
			break
		if file.ends_with(".png"):
			var fullPath = dirPath + "/" + file
			var tex = load(fullPath)
			var image = tex.get_data()
			image.lock()
			for x in image.get_width():
				for y in image.get_height():
					var key = Vector2(x, y)
					var color: Color = image.get_pixelv(key)
					if color.a == 0.0:
						continue
					var replaced: = false
					var bestColor
					var bestColorDelta: = INF
					for c in colorMap.keys():
						var colorDelta = abs(c.r - color.r) + abs(c.g - color.g) + abs(c.b - color.b)
						if colorDelta < bestColorDelta and colorDelta < 0.4:
							bestColor = c
							bestColorDelta = colorDelta
					if bestColor:
						image.set_pixelv(key, colorMap[bestColor])
						replaced = true



			image.unlock()
			image.save_png(fullPath)
