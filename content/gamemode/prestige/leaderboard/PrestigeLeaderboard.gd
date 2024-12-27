extends PanelContainer

signal leaderboard_not_found
signal leaderboard_found
signal leaderboard_score_upload_success
signal leaderboard_score_upload_failed

var leaderboardName = "domekeeper_prestige_weekly"

onready var LeaderboardLoadingLabel = find_node("LeaderboardLoadingLabel")

var leaderboardGlobalEntries: Array
var leaderboardRelativeEntries: Array
var leaderboardFriendEntries: Array

var ownRank: int = - 1
var ownBestScore: int
var currentScore: int
var cheatHash: int

var lastDownload: = 0
var nextDownload: = 0

var season: int
var uploadDone: = false

const details: = 9

var loadedBoards: = []

func _ready():
	SteamGlobal.Steam.connect("leaderboard_find_result", self, "leaderboard_Find_Result")
	SteamGlobal.Steam.connect("leaderboard_scores_downloaded", self, "leaderboard_Scores_Downloaded")
	SteamGlobal.Steam.connect("leaderboard_score_uploaded", self, "leaderboard_Score_Uploaded")
	
	match GameWorld.lastLeaderboardSection:
		"global":
			find_node("ButtonShowLeaderboard").pressed = true
		_:
			find_node("ButtonShowFriends").pressed = true
	
	var seasonButtonsContainer = find_node("SeasonButtons")
	for i in range(1, 1 + seasonButtonsContainer.get_child_count()):
		var button = find_node("ButtonSeason" + str(i))
		button.disabled = true
		button.text = tr("leaderboard.season").format({"season": i})
		button.connect("pressed", self, "setSeason", [i])
		
		if i != 1:
			var friends = find_node("FriendsLeaderboardContainer1").duplicate()
			friends.name = "FriendsLeaderboardContainer" + str(i)
			find_node("FriendsContainer").add_child(friends)
			var global = find_node("GlobalLeaderboardContainer1").duplicate()
			global.name = "GlobalLeaderboardContainer" + str(i)
			find_node("LeaderboardContainer").add_child(global)

func setButtonsDisabled(disabled: bool):
	find_node("ButtonShowFriends").disabled = disabled
	find_node("ButtonShowLeaderboard").disabled = disabled
	for button in find_node("SeasonButtons").get_children():
		button.disabled = disabled
	
	LeaderboardLoadingLabel.visible = disabled
	
	if disabled:
		for global in find_node("LeaderboardContainer").get_children():
			global.visible = false
		for friend in find_node("FriendsContainer").get_children():
			friend.visible = false
	else:
		updateVisibleBoard()

func start():
	Style.init(self)
	
	cheatHash = CheatDetection.stop()
	Backend.event("cheat_stats", {"cheatHash": cheatHash})
	season = 2
	updateLeaderboardName()
	




	Logger.info("Leaderboard unknown, finding before uploading score")
	SteamGlobal.Steam.findOrCreateLeaderboard(leaderboardName, 2, 1)
	setButtonsDisabled(true)
	
	find_node("FriendsContainer").visible = find_node("ButtonShowFriends").pressed
	find_node("LeaderboardContainer").visible = find_node("ButtonShowLeaderboard").pressed

func updateLeaderboardName():
	if cheatHash > 0:
		leaderboardName = "domekeeper_prestige_cheats"
	else:
		match season:
			1: leaderboardName = "domekeeper_prestige_weekly"
			2: leaderboardName = "domekeeper_prestige_season2"
		match GameWorld.modeVariation:
			CONST.MODE_PRESTIGE_COBALT:
				leaderboardName += "_cobalt"
			CONST.MODE_PRESTIGE_COUNTDOWN:
				leaderboardName += "_countdown"
			CONST.MODE_PRESTIGE_MINER:
				leaderboardName += "_miner"
	
	prints("current leaderboard", leaderboardName)

func setOwnRank(ownRank):
	self.ownRank = ownRank

func leaderboard_Find_Result(handle: int, found: int)->void :
	if found == 1:
		Logger.info("Leaderboard found")
		GameWorld.leaderboardHandles[leaderboardName] = handle
		onLeaderboardFound()
	else:
		Logger.error("Leaderboard not found")
		emit_signal("leaderboard_not_found")

func leaderboard_Scores_Downloaded(message: String, result: Array):
	match lastDownload:
		0:
			leaderboardGlobalEntries = result.duplicate()
		1:
			leaderboardRelativeEntries = result.duplicate()
		2:
			leaderboardFriendEntries = result.duplicate()
	downloadLeaderboard()

func fillLeaderboards():
	var c = find_node("GlobalLeaderboardContainer" + str(season), true, false)
	var isTop10: = false
	for R in leaderboardGlobalEntries:
		var steamid = R.get("steam_id", 0)
		var isSelf: bool = steamid == SteamGlobal.STEAM_ID
		if isSelf:
			isTop10 = true
		
		var playerName = SteamGlobal.Steam.getFriendPersonaName(R.get("steam_id", 0))
		addRow(R.get("global_rank", 0), R.get("score", 0), R.get("details", []), playerName, c, isSelf)
	
	if not isTop10:
		var l = Label.new()
		l.text = "..."
		c.add_child(l)
		c.add_child(Control.new())
		c.add_child(Control.new())
		c.add_child(Control.new())
		c.add_child(Control.new())
		c.add_child(Control.new())
		
		for R in leaderboardRelativeEntries:
			var steamid = R.get("steam_id", 0)
			var isSelf: bool = steamid == SteamGlobal.STEAM_ID
			var playerName = SteamGlobal.Steam.getFriendPersonaName(R.get("steam_id", 0))
			addRow(R.get("global_rank", 0), R.get("score", 0), R.get("details", []), playerName, c, isSelf)
	
	c = find_node("FriendsLeaderboardContainer" + str(season), true, false)
	for R in leaderboardFriendEntries:
		var steamid = R.get("steam_id", 0)
		var isSelf: bool = steamid == SteamGlobal.STEAM_ID
		var playerName = SteamGlobal.Steam.getFriendPersonaName(R.get("steam_id", 0))
		addRow(R.get("global_rank", 0), R.get("score", 0), R.get("details", []), playerName, c, isSelf)

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
	l.text = "%5.0f" % score
	l.align = Label.ALIGN_RIGHT
	if highlight:
		l.add_color_override("font_color", Style.FONT_COLOR_HIGHLIGHT)
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

func onLeaderboardFound():
	if uploadDone:
		downloadLeaderboard()
	else:
		SteamGlobal.Steam.setLeaderboardDetailsMax(details)
		emit_signal("leaderboard_found")

func downloadLeaderboard():
	if loadedBoards.has(leaderboardName):
		setButtonsDisabled(false)
		return 
	
	setButtonsDisabled(true)
	
	var h = GameWorld.leaderboardHandles[leaderboardName]
	lastDownload = nextDownload
	var entries: = 14
	prints("loading", leaderboardName, nextDownload)
	match nextDownload:
		0:
			if ownRank <= entries:
				nextDownload += 2
				SteamGlobal.Steam.downloadLeaderboardEntries(1, entries, 0, h)
			else:
				nextDownload += 1
				SteamGlobal.Steam.downloadLeaderboardEntries(1, entries - 6, 0, h)
		1:
			nextDownload += 1
			SteamGlobal.Steam.downloadLeaderboardEntries(max(entries - ownRank, - 2), 2, 1, h)
		2:
			nextDownload += 1
			SteamGlobal.Steam.downloadLeaderboardEntries(1, entries, 2, h)
		3:
			fillLeaderboards()
			loadedBoards.append(leaderboardName)
			setButtonsDisabled(false)
			prints("finished loading", leaderboardName)

func uploadScore(score):
	self.currentScore = score
	if score > 0:
		var handle = GameWorld.leaderboardHandles.get(leaderboardName, 0)
		prints("uploading leaderboard score to handle", handle, "for board", leaderboardName)
		SteamGlobal.Steam.uploadLeaderboardScore(score, true, generateHighscoreArray(), handle)
	else:
		downloadLeaderboard()
		emit_signal("leaderboard_score_upload_success", 0, 0, 0)
		ownRank = 0
		ownBestScore = 0

func leaderboard_Score_Uploaded(success: int, score: int, score_changed: int, new_rank: int, prev_rank: int)->void :
	if success == 1:
		
		Logger.info("new score uploaded, new rank is " + str(new_rank))
		uploadDone = true
		emit_signal("leaderboard_score_upload_success", score_changed, new_rank, prev_rank)
		ownRank = new_rank
		ownBestScore = score
		downloadLeaderboard()
	else:
		Logger.info("new score upload failed")
		emit_signal("leaderboard_score_upload_failed")
		$Tween.interpolate_callback(SteamGlobal.Steam, 10.0, "uploadLeaderboardScore", currentScore, true)
		$Tween.start()

func generateHighscoreArray()->Array:
	
	
	
	
	
	
	
	
	
	
	
	
	var d: = []
	d.append(int(GameWorld.lastDomeId.substr(4)))
	d.append(int(GameWorld.lastKeeperId.substr(6)))
	match GameWorld.lastGadgetId:
		"orchard": d.append(1)
		"repellent": d.append(2)
		"shield": d.append(3)
		"dronhub": d.append(4)
		_: d.append(0)
	d.append(int(GameWorld.worldId.substr(5)))
	d.append(int(GameWorld.runTime))
	d.append(int(Data.of("prestige.baseperwave")))
	d.append(int(Data.of("prestige.multiplier")))
	d.append(int(Data.of("monsters.cycle")))
	d.append(1 if GameWorld.won else 0)
	d.append(cheatHash)
	var versionParts = GameWorld.version.split(".")
	var versionHash = 1024 * int(versionParts[0].substr(1)) + int(versionParts[1])
	d.append(versionHash)
	var modeId: int
	match GameWorld.modeVariation:
		CONST.MODE_PRESTIGE_COBALT:
			modeId = 1
		CONST.MODE_PRESTIGE_COUNTDOWN:
			modeId = 2
		CONST.MODE_PRESTIGE_MINER:
			modeId = 3
		_:
			modeId = 0
	d.append(modeId)
	return d

func _on_ButtonShowFriends_pressed():
	GameWorld.lastLeaderboardSection = "friends"
	updateVisibleBoard()

func _on_ButtonShowLeaderboard_pressed():
	GameWorld.lastLeaderboardSection = "global"
	updateVisibleBoard()

func updateVisibleBoard():
	if find_node("ButtonShowFriends").pressed:
		for friend in find_node("FriendsContainer").get_children():
			friend.visible = friend.name.ends_with(str(season))
		find_node("LeaderboardContainer").visible = false
		find_node("FriendsContainer").visible = true
	else:
		find_node("LeaderboardContainer").visible = true
		find_node("FriendsContainer").visible = false
		for global in find_node("LeaderboardContainer").get_children():
			global.visible = global.name.ends_with(str(season))

func setSeason(i: int):
	season = i
	updateLeaderboardName()
	lastDownload = 0
	nextDownload = 0



	SteamGlobal.Steam.findOrCreateLeaderboard(leaderboardName, 2, 1)
	setButtonsDisabled(true)
