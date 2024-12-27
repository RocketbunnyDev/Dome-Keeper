extends Node

var resolution: = 1000.0
onready var listingContainer = find_node("Listing")

var currentData
var currentEntry
var displayMode: = 0
var selectedVersions: = []
var filesByVersion: Dictionary

func _ready():
	Backend.login()
	
	yield (Backend, "loggedIn")
	
	OS.window_maximized = true
	get_tree().set_screen_stretch(SceneTree.STRETCH_MODE_2D, SceneTree.STRETCH_ASPECT_EXPAND, Vector2(1920, 1080), 1)
	
	var versionsFile = File.new()
	var err = versionsFile.open("user://sessions-by-version.txt", File.READ)
	if err == 0:
		filesByVersion = JSON.parse(versionsFile.get_as_text()).result
		var versions: = []
		for r in filesByVersion:
			versions.append(r)
		versions.sort()
		var group = ButtonGroup.new()
		for i in range(0, versions.size()):
			var v = versions[i]
			var b = Button.new()
			b.focus_mode = Button.FOCUS_NONE
			b.text = v
			b.toggle_mode = true
			b.group = group
			b.connect("toggled", self, "setVersionFilter", [v])
			find_node("VersionButtons").add_child(b)
	versionsFile.close()

	Style.init(self)
	
	start()

func setVersionFilter(active: bool, version: String):
	if active:
		selectedVersions.append(version)
	else:
		selectedVersions.erase(version)
	updateView()

func updateView():
	var sessions: = []
	for v in selectedVersions:
		sessions.append_array(filesByVersion[v])
	find_node("Listing").displayCachedSessions(sessions)

func start():
	find_node("RawDataPanel").visible = false
	find_node("PlottedDataPanel").visible = false
	listingContainer.visible = true
	listingContainer.start("Sessions", "compiled-sessions", "*.txt")
	listingContainer.connect("received_entry", self, "showEntry")

func showEntryAsChart(entry):
	if not entry:
		return 
	
	currentEntry = entry
	
	var data = JSON.parse(entry).result
	find_node("PlottedDataPanel").visible = true
	find_node("RawDataPanel").visible = false
	
	clearContainer("RunButtons")
	
	var runs: = Backend.parseRunsFromSession(data)
	
	if runs.size() == 0:
		var l = Label.new()
		l.text = "no new runs"
		find_node("RunButtons").add_child(l)
	
	var i: = 1
	var buttonGroup = ButtonGroup.new()
	for run in runs:
		var b = Button.new()
		b.focus_mode = Button.FOCUS_NONE
		b.text = "Run " + str(i)
		b.group = buttonGroup
		b.toggle_mode = true
		b.connect("pressed", self, "plotRun", [run])
		if i == 1:
			plotRun(run)
			b.pressed = true
		find_node("RunButtons").add_child(b)
		Style.init(b)
		i += 1

func clearContainer(n: String):
	var container = find_node(n)
	for c in container.get_children():
		container.remove_child(c)
		c.queue_free()

func plotRun(data):
	currentData = data
	clearContainer("PlotContainer")
	clearContainer("Labels")
	
	if not data:
		return 
	
	find_node("DurationLabel").text = "Duration: %.0fm" % (data.get("duration", 1) / 60000.0)
	find_node("ResultLabel").text = "Result: " + data.get("state", "unknown")
	find_node("VersionLabel").text = "Version: " + data["meta"].get("version", "unknown")
	find_node("PlatformLabel").text = "Platform: " + data["meta"].get("platform_name", "unknown")
	var time: Dictionary = data["meta"].get("date", {})
	find_node("DateLabel").text = "%02d/%02d/%d %02d:%02d" % [time.day, time.month, time.year, time.hour, time.minute]
	
	var plotContainer = find_node("PlotContainer")
	var lineBottom = plotContainer.rect_size.y - 200
	
	var line: Line2D
	for d in data.get("waves"):
		var t = timeToX(d)
		if not line:
			line = Line2D.new()
			line.width = 500
			line.default_color = Color("0D2B45")
			line.add_point(Vector2(t, lineBottom - 250))
		else:
			line.add_point(Vector2(t, lineBottom - 250))
			plotContainer.add_child(line)
			line = null
	
	var ironLine = Line2D.new()
	ironLine.width = 3
	ironLine.default_color = Color.yellow
	var waterLine = Line2D.new()
	waterLine.width = ironLine.width
	waterLine.default_color = Color.cornflower
	var sandLine = Line2D.new()
	sandLine.width = ironLine.width
	sandLine.default_color = Color.purple



	var domeHealth = Line2D.new()
	domeHealth.width = ironLine.width
	domeHealth.default_color = Color.brown
	
	var indexLabel = Label.new()
	indexLabel.text = "iron"
	indexLabel.add_color_override("font_color", Color.yellow)
	find_node("Labels").add_child(indexLabel)
	indexLabel = Label.new()
	indexLabel.text = "water"
	indexLabel.add_color_override("font_color", Color.cornflower)
	find_node("Labels").add_child(indexLabel)
	indexLabel = Label.new()
	indexLabel.text = "sand"
	indexLabel.add_color_override("font_color", Color.purple)
	find_node("Labels").add_child(indexLabel)
	indexLabel = Label.new()
	indexLabel.text = "health"
	indexLabel.add_color_override("font_color", Color.brown)
	find_node("Labels").add_child(indexLabel)
	
	var allMetrics = data.get("cycles")
	for d in allMetrics:
		var metrics = d.get("data")
		var t = timeToX(d)
		ironLine.add_point(Vector2(t, lineBottom - metrics.get("i", 1) * 10))
		waterLine.add_point(Vector2(t, lineBottom - 3 - metrics.get("w", 1) * 10))
		sandLine.add_point(Vector2(t, lineBottom - 6 - metrics.get("s", 1) * 10))

		domeHealth.add_point(Vector2(t, lineBottom - metrics.get("health", 1) * 0.3))
	plotContainer.add_child(ironLine)
	plotContainer.add_child(waterLine)
	plotContainer.add_child(sandLine)

	plotContainer.add_child(domeHealth)
	var lastX = timeToX(allMetrics.back())
	plotContainer.rect_min_size.x = lastX + 100
	
	var bound = Line2D.new()
	bound.width = 8
	bound.default_color = Style.STRUCT_DARK
	bound.add_point(Vector2(4, lineBottom + 6))
	bound.add_point(Vector2(lastX + 4, lineBottom + 6))
	bound.add_point(Vector2(lastX + 4, 135))
	bound.add_point(Vector2(4, 135))
	bound.add_point(Vector2(4, lineBottom + 6))
	plotContainer.add_child(bound)
	
	var upgrades = data.get("upgrades")
	var last: = - 100.0
	var off: = 0
	for d in upgrades:
		var l = Label.new()
		l.set("custom_fonts/font", preload("res://gui/fonts/FontSmall.tres"))
		l.set_rotation(PI * 0.25)
		l.text = d.get("data").capitalize()
		l.rect_position.x = timeToX(d) + 6
		l.rect_position.y = plotContainer.rect_size.y - 180
		if abs(last - l.rect_position.x) < 20:
			off += 26 + (l.rect_position.x - last)
			l.rect_position.y += off
		else:
			off = 0
		plotContainer.add_child(l)
		last = l.rect_position.x

	var gadgets = data.get("gadgets")
	last = - 100.0
	off = 0
	for d in gadgets:
		var l = Label.new()
		l.set("custom_fonts/font", preload("res://gui/fonts/FontSmall.tres"))
		l.set_rotation(PI * 1.75)
		l.text = d.get("data").capitalize()
		l.rect_position.x = timeToX(d) + 6
		l.rect_position.y = lineBottom - 650
		if abs(last - l.rect_position.x) < 20:
			off += 28
			l.rect_position.y += off
		else:
			off = 0
		plotContainer.add_child(l)
		last = l.rect_position.x
	
	var gadgetUses = data.get("gadgetUses")
	last = - 100.0
	off = 0
	for d in gadgetUses:
		var l = Label.new()
		l.set("custom_fonts/font", preload("res://gui/fonts/FontSmall.tres"))
		l.set_rotation(PI * 0.25)
		l.text = d.get("data").capitalize()
		l.rect_position.x = timeToX(d) + 6
		l.rect_position.y = lineBottom - 620
		if abs(last - l.rect_position.x) < 20:
			off += 28
			l.rect_position.y += off
		else:
			off = 0
		plotContainer.add_child(l)
		last = l.rect_position.x

func timeToX(d: Dictionary):
	return 10 + d.get("time", 0) / resolution

func sortByTime(a, b):
	return a["time"] < b["time"]

func sortById(a, b):
	return a["id"] < b["id"]

func showEntryAsEventList(entry):
	if not entry:
		return 
	
	currentEntry = entry
	
	var data = JSON.parse(entry).result
	data.sort_custom(self, "sortById")
	find_node("RawDataPanel").visible = true
	find_node("PlottedDataPanel").visible = false
	
	var grid = find_node("RawDataGridContainer")
	for c in grid.get_children():
		grid.remove_child(c)
		c.queue_free()
	
	for d in data:
		var type = d.get("type", "missing")
		var l = Label.new()
		l.set("custom_fonts/font", preload("res://gui/fonts/FontSmall.tres"))
		l.align = Label.ALIGN_RIGHT
		l.text = str(d.get("id", - 1))
		grid.add_child(l)
		l = Label.new()
		l.set("custom_fonts/font", preload("res://gui/fonts/FontSmall.tres"))
		l.text = type.to_lower().replace("_", " ")
		grid.add_child(l)
		l = Label.new()
		l.set("custom_fonts/font", preload("res://gui/fonts/FontSmall.tres"))
		l.text = "%.0fs" % (d.get("time", 0) / 1000)
		l.align = Label.ALIGN_RIGHT
		grid.add_child(l)
		l = Label.new()
		l.set("custom_fonts/font", preload("res://gui/fonts/FontSmall.tres"))
		l.size_flags_horizontal = Label.SIZE_EXPAND_FILL
		l.autowrap = true
		l.text = str(d.get("data", ""))
		grid.add_child(l)

func _on_Listing_entry_selected()->void :
	clearContainer("RunButtons")
	clearContainer("PlotContainer")
	find_node("DurationLabel").text = ""
	find_node("ResultLabel").text = ""
	find_node("VersionLabel").text = ""
	find_node("PlatformLabel").text = ""

func _on_ButtonPlus_pressed()->void :
	resolution *= 0.5
	plotRun(currentData)

func _on_ButtonMinus_pressed()->void :
	resolution *= 2
	plotRun(currentData)

func _on_ModeTextButton_pressed()->void :
	displayMode = 1
	showEntry(currentEntry)

func _on_ModeChartsButton_pressed()->void :
	displayMode = 0
	showEntry(currentEntry)

func showEntry(entry):
	if displayMode == 0:
		showEntryAsChart(entry)
	elif displayMode == 1:
		showEntryAsEventList(entry)
