extends Control

var leaderboardGlobalEntries
var currentLeaderboardId: String
var handles: = {}
var page: = 1

func _ready():
	SteamGlobal.init()
	SteamGlobal.Steam.connect("leaderboard_find_result", self, "leaderboard_Find_Result")
	SteamGlobal.Steam.connect("leaderboard_scores_downloaded", self, "leaderboard_Scores_Downloaded")
	findLeaderboard("domekeeper_prestige_weekly")
	find_node("ButtonPrestige").pressed = true
	
	Style.init(self)

func findLeaderboard(id: String):
	self.currentLeaderboardId = id
	SteamGlobal.Steam.findLeaderboard(id)

func leaderboard_Find_Result(handle: int, found: int)->void :
	if found == 1:
		Logger.info("Leaderboard found")
		handles[currentLeaderboardId] = handle
		SteamGlobal.Steam.setLeaderboardDetailsMax(11)
		SteamGlobal.Steam.downloadLeaderboardEntries(100 * (page - 1), 100 * page, 0, handle)
	else:
		Logger.error("Leaderboard not found")
		emit_signal("leaderboard_not_found")

func leaderboard_Scores_Downloaded(message: String, result: Array):
	leaderboardGlobalEntries = result.duplicate()
	fillLeaderboards()

func fillLeaderboards():
	var c = find_node("GlobalLeaderboardContainer")
	for R in leaderboardGlobalEntries:
		var steamid = R.get("steam_id", 0)
		var playerName = SteamGlobal.Steam.getFriendPersonaName(R.get("steam_id", 0))
		addRow(R.get("global_rank", 0), R.get("score", 0), R.get("details", []), playerName, c, false)

func addRow(rank: int, score: int, details: Array, playerName: String, container, highlight: = false):
	if playerName.length() > 24:
		playerName = playerName.substr(0, 24)
	var l = Label.new()
	l.text = "#" + str(rank)
	l.rect_min_size.x = 30
	if highlight:
		l.add_color_override("font_color", Style.FONT_COLOR_HIGHLIGHT)
	l.add_font_override("font", preload("res://gui/fonts/FontNormalMonospace.tres"))
	container.add_child(l)
	l.align = Label.ALIGN_RIGHT
	l = Label.new()
	l.text = playerName
	l.add_font_override("font", preload("res://gui/fonts/FontLeaderboardPlayername.tres"))
	l.size_flags_horizontal = Control.SIZE_EXPAND
	l.align = Label.ALIGN_RIGHT
	if highlight:
		l.add_color_override("font_color", Style.FONT_COLOR_HIGHLIGHT)
	container.add_child(l)
	
	if details.size() >= 3:
		container.add_child(getTextureRectFor(0, details[0]))
		container.add_child(getTextureRectFor(1, details[1]))
		container.add_child(getTextureRectFor(2, details[2]))
	
	
	
	
	
	
	
	
	
	
	
	
	
	l = Label.new()
	l.text = str(details[6]) + " x " + str(details[5]) + " = " + "%5.0f" % score
	l.align = Label.ALIGN_RIGHT
	l.add_font_override("font", preload("res://gui/fonts/FontNormalMonospace.tres"))
	container.add_child(l)
	
	l = Label.new()
	l.text = "%.0f" % (details[4] / 60) + "m"
	l.align = Label.ALIGN_RIGHT
	l.add_font_override("font", preload("res://gui/fonts/FontNormalMonospace.tres"))
	container.add_child(l)
	
	l = Label.new()
	l.text = "wave " + str(details[7])
	l.align = Label.ALIGN_RIGHT
	l.add_font_override("font", preload("res://gui/fonts/FontNormalMonospace.tres"))
	container.add_child(l)
	
	l = Label.new()
	l.text = "ch " + str(details[9])
	l.align = Label.ALIGN_RIGHT
	l.add_font_override("font", preload("res://gui/fonts/FontNormalMonospace.tres"))
	container.add_child(l)
	
	l = Label.new()
	l.text = "v " + str(details[10] / 1024) + "." + str(details[10] % 1024)
	l.align = Label.ALIGN_RIGHT
	l.add_font_override("font", preload("res://gui/fonts/FontNormalMonospace.tres"))
	container.add_child(l)

func getTextureRectFor(col: int, value: int)->TextureRect:
	var s = TextureRect.new()
	match col:
		0:
			match value:
				1: s.texture = preload("res://content/gamemode/prestige/leaderboard/leaderboardicons01.png")
				2: s.texture = preload("res://content/gamemode/prestige/leaderboard/leaderboardicons02.png")
				3: s.texture = preload("res://content/gamemode/prestige/leaderboard/leaderboardicons03.png")
		1:
			match value:
				1: s.texture = preload("res://content/gamemode/prestige/leaderboard/leaderboardicons04.png")
				2: s.texture = preload("res://content/gamemode/prestige/leaderboard/leaderboardicons05.png")
		2:
			match value:
				1: s.texture = preload("res://content/gamemode/prestige/leaderboard/leaderboardicons08.png")
				2: s.texture = preload("res://content/gamemode/prestige/leaderboard/leaderboardicons07.png")
				3: s.texture = preload("res://content/gamemode/prestige/leaderboard/leaderboardicons09.png")
				4: s.texture = preload("res://content/gamemode/prestige/leaderboard/leaderboardicons06.png")
	if s.texture:
		s.rect_min_size = s.texture.get_size() * 2
	s.expand = true
	s.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	return s

func _on_ButtonUpdate_pressed():
	var c = find_node("GlobalLeaderboardContainer")
	for e in c.get_children():
		e.queue_free()
	if handles.has(currentLeaderboardId):
		SteamGlobal.Steam.downloadLeaderboardEntries(100 * (page - 1) + 1, 100 * page, 0, handles[currentLeaderboardId])
	else:
		findLeaderboard(currentLeaderboardId)
	find_node("LabelPage").text = "Page " + str(page)

func _on_ButtonPrestige_pressed():
	currentLeaderboardId = "domekeeper_prestige_weekly"
	_on_ButtonUpdate_pressed()

func _on_ButtonPrestige2_pressed():
	currentLeaderboardId = "domekeeper_prestige_weekly_cobalt"
	_on_ButtonUpdate_pressed()

func _on_ButtonPrestige3_pressed():
	currentLeaderboardId = "domekeeper_prestige_weekly_countdown"
	_on_ButtonUpdate_pressed()

func _on_ButtonPrestige4_pressed():
	currentLeaderboardId = "domekeeper_prestige_weekly_miner"
	_on_ButtonUpdate_pressed()

func _on_ButtonPrestige5_pressed():
	currentLeaderboardId = "domekeeper_prestige_cheats"
	_on_ButtonUpdate_pressed()

func _on_ButtonBack_pressed():
	page = max(1, page - 1)
	_on_ButtonUpdate_pressed()

func _on_ButtonForward_pressed():
	page = page + 1
	_on_ButtonUpdate_pressed()

