extends CenterContainer

var isIn: = false
var startScoreCount: = false

onready var ScoreLabel = find_node("ScoreLabel")
onready var ScoreUploadResult = find_node("ScoreUploadResult")
onready var Leaderboard = find_node("PrestigeLeaderboard")

var currentScore: int
var totalScore: int
var currentTime: float
var totalTime: float

var scoreUploadMessage: String
var shoulShowUploadMessage: = false

func _ready():
	if get_parent() == get_tree().root:
		SteamGlobal.init()
		Data.apply("prestige.baseperwave", 10)
		Data.apply("prestige.multiplier", 1)
		Data.apply("monsters.cycle", 1)
		Data.apply("prestige.score", 10010)
		Data.apply("prestige.sentcobalt", 1)
		Data.apply("inventory.totalsand", 1)
		GameWorld.version = "v1.1"
		$Tween.interpolate_callback(self, 0.3, "startScoreCount")
		$Tween.start()
	
	find_node("RunStats").init(false)
	ScoreLabel.text = "0"
	
	find_node("AnotherRunButton").visible = true
	find_node("TitleLabel").text = "level.gameover.prestige.title"
	match GameWorld.modeVariation:
		CONST.MODE_PRESTIGE_COBALT:
			find_node("VariationLabel").visible = true
			find_node("VariationLabel").text = tr("loadout.prestige.cobalt")
		CONST.MODE_PRESTIGE_COUNTDOWN:
			find_node("VariationLabel").visible = true
			find_node("VariationLabel").text = tr("loadout.prestige.countdown")
		CONST.MODE_PRESTIGE_MINER:
			find_node("VariationLabel").visible = true
			find_node("VariationLabel").text = tr("loadout.prestige.miner")
		"":
			find_node("VariationLabel").visible = false
	
	if GameWorld.boughtUpgrades.has("prestigefinish") and GameWorld.unlockableElements.size() > 0:
		find_node("NavigationButtons").visible = false
		find_node("UnlockElementButton").visible = true
	else:
		find_node("NavigationButtons").visible = true
		find_node("UnlockElementButton").visible = false
	
	Style.init(self)
	


	
	ScoreUploadResult.text = ""
	scoreUploadMessage = tr("level.gameover.prestige.uploading.inprocess")
	totalScore = Data.of("prestige.score")
	
	Leaderboard.connect("leaderboard_not_found", self, "onLeaderboardNotFound")
	Leaderboard.connect("leaderboard_found", self, "onLeaderboardFound")
	Leaderboard.connect("leaderboard_score_upload_success", self, "leaderboard_Score_Upload_Success")
	Leaderboard.connect("leaderboard_score_upload_failed", self, "leaderboard_Score_Upload_Failed")
	
	Leaderboard.start()

func onLeaderboardNotFound():
	scoreUploadMessage = tr("level.gameover.prestige.uploading.finalfailed")
	updateScoreUploadLabel()

func onLeaderboardFound():
	ScoreUploadResult.text = tr("level.gameover.prestige.uploading.inprocess")
	Leaderboard.uploadScore(totalScore)

func _process(delta):
	if not startScoreCount:
		return 
	
	if currentTime > totalTime or ScoreLabel.text == str(totalScore):
		currentTime = totalTime
		startScoreCount = false
		$FinalRaised.play()
		ScoreLabel.rect_pivot_offset = ScoreLabel.rect_size * 0.5
		$Tween.interpolate_property(ScoreLabel, "rect_scale", Vector2.ONE * 3, Vector2.ONE, 0.5, Tween.TRANS_EXPO, 0, 0.1)
		$Tween.interpolate_callback($FinalDropped, 0.5, "play")
		$Tween.interpolate_callback(self, 1.0, "set", "shoulShowUploadMessage", true)
		$Tween.interpolate_callback(self, 1.1, "updateScoreUploadLabel")
		$Tween.start()
		
	var fraction = currentTime / totalTime
	var newText = str("%.0f" % (fraction * totalScore))
	if newText != ScoreLabel.text:
		ScoreLabel.text = newText
		$Ping.play()
	
	var deltaMod = 1.0 - 1.99 * abs(0.5 - fraction)
	currentTime += delta * 10000 * pow(min(deltaMod, 0.05), 3)

func updateScoreUploadLabel():
	
	if shoulShowUploadMessage:
		ScoreUploadResult.text = scoreUploadMessage
	else:
		ScoreUploadResult.text = ""

func startScoreCount():
	totalTime = 1.0 + pow(totalScore, 0.4) * 0.02
	startScoreCount = true

func leaderboard_Score_Upload_Failed()->void :
	shoulShowUploadMessage = true
	scoreUploadMessage = tr("level.gameover.prestige.uploading.failed")
	updateScoreUploadLabel()
	shoulShowUploadMessage = false

func leaderboard_Score_Upload_Success(score_changed: int, new_rank: int, prev_rank: int)->void :
	scoreUploadMessage = ""
	if score_changed == 1:
		scoreUploadMessage = tr("level.gameover.prestige.score.personalbest") + " "
	if new_rank == prev_rank:
		scoreUploadMessage += tr("level.gameover.prestige.score.rankunchanged")
	else:
		scoreUploadMessage += tr("level.gameover.prestige.score.rankimproved").format({"rank": new_rank})
	updateScoreUploadLabel()

func moveIn():
	if isIn:
		return 
	
	GameWorld.setShowMouse(true)
	isIn = true
	$Tween.stop_all()
	$Tween.remove_all()
	$Tween.interpolate_property(self, "rect_position:y", rect_position.y, (get_viewport_rect().size.y - rect_size.y) * 0.5, 1.2, Tween.TRANS_CUBIC, Tween.EASE_OUT)
	$Tween.interpolate_callback(self, 1.3, "startScoreCount")
	$Tween.interpolate_callback(self, 3.0, "updateFocus")
	$Tween.start()

func moveOut():
	if not isIn:
		return 
	
	isIn = false
	$Tween.interpolate_property(self, "rect_position:y", rect_position.y, get_viewport_rect().size.y, 0.3, Tween.TRANS_CUBIC, Tween.EASE_IN)
	$Tween.interpolate_callback(self, 0.5, "queue_free")
	$Tween.start()

func _on_MainMenuButton_pressed():
	if isIn:
		continuePressed()
		StageManager.startStage("stages/title/title")

func _on_AnotherRunButton_pressed():
	if isIn:
		continuePressed()
		StageManager.startStage("stages/loadout/loadout")

func continuePressed():
	Audio.stopMusic()
	Audio.sound("gui_select")
	find_node("MainMenuButton").disabled = true
	find_node("AnotherRunButton").disabled = true

func _on_UnlockElementButton_pressed():
	Audio.sound("gui_select")
	var i = preload("res://gui/PopupInput.gd").new()
	var unlockablesPopup = preload("res://content/gamemode/unlockables/UnlockablesPopup.tscn").instance()
	unlockablesPopup.connect("proceed", i, "desintegrate")
	unlockablesPopup.connect("back", i, "desintegrate")
	unlockablesPopup.connect("back", self, "updateFocus")
	unlockablesPopup.connect("back", unlockablesPopup, "queue_free")
	get_parent().add_child(unlockablesPopup)
	i.popup = unlockablesPopup
	i.integrate(Level.stage)

func updateFocus():
	if find_node("NavigationButtons").visible:
		InputSystem.grabFocus(find_node("AnotherRunButton"))
	else:
		InputSystem.grabFocus(find_node("UnlockElementButton"))
