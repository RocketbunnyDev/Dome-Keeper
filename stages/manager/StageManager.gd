extends Node

var currentStage: Stage = null
var pendingStagePacked: PackedScene = null
var pendingStage: Stage = null
var pendingStageResource: = ""
var pendingStageName: = ""
var pausedStages = []

var initData: Dictionary

var sceneCache = {}

signal stage_started


func startStage(stageName: String, data: Array = [], tabula: bool = true):
	if stageName == pendingStageName:
		Logger.warn("same stage queued again, ignoring", "StageManager.startStage", stageName)
		return 
	
	if tabula:
		pausedStages.clear()
	queueStage(stageName, data)
	
	if currentStage:
		_stopOldStage()
	else:
		_addNewStage()

func queueStage(stageName: String, data: Array = []):
	var i = stageName.find_last("/")
	pendingStageResource = stageName.substr(0, i) + "/" + stageName.substr(i + 1, 1).capitalize() + stageName.substr(i + 2) + "Stage.tscn"
	pendingStageName = stageName
	initData[pendingStageResource] = data

func _stopOldStage():
	currentStage.beforeEnd()
	for i in currentStage.inputs:
		i.desintegrate()
	if currentStage.fadeOutTime > 0:
		$Canvas / ScreenOverlay.fadeOutCallback(currentStage.fadeOutTime, self, "_removeOldStage")
	else:
		$Canvas / ScreenOverlay.setOpaque()
		_removeOldStage()

func _removeOldStage():
	currentStage.end()
	currentStage.emit_signal("ended")
	find_node("CurrentStage").remove_child(currentStage)
	currentStage.queue_free()
	
	if pendingStageName:
		_addNewStage()
	elif pausedStages.size() > 0:
		pendingStage = pausedStages.pop_back()
		pendingStage.resuming = true
		_addNewStage()

func _addNewStage():
	var data = initData[pendingStageResource]
	initData.erase(pendingStageResource)
	if pendingStage:
		
		currentStage = pendingStage
		pendingStage = null
	else:
		
		if sceneCache.has(pendingStageName):
			currentStage = sceneCache.get(pendingStageName).instance()
		else:
			var scene = load("res://" + pendingStageResource)
			sceneCache[pendingStageName] = scene
			currentStage = load("res://" + pendingStageResource).instance()
		pendingStageResource = ""
		pendingStageName = ""
	
	currentStage.beforeReady()
	find_node("CurrentStage").add_child(currentStage)
	
	if not currentStage.resuming:
		currentStage.connect("request_end", self, "_stopOldStage")
		currentStage.build(data)
		
	emit_signal("stage_started")
	

	currentStage.beforeStart()
	if currentStage.fadeInTime > 0:
		$Canvas / ScreenOverlay.fadeInCallback(currentStage.fadeInTime, self, "_startNewStage")
	else:
		$Canvas / ScreenOverlay.setClear()
		_startNewStage()

func _startNewStage():
	currentStage.start()
	currentStage.resuming = false

func error(message: String):
	if currentStage:
		queueStage("stages/debug/error", [message])
		currentStage.emit_signal("request_end")
	else:
		startStage("stages/debug/error", [message])

func interleaveStage(stageName: String, data: Array = []):
	pausedStages.append(currentStage)
	for i in currentStage.inputs:
		i.desintegrate()
	
	currentStage.pause()
	
	queueStage(stageName, data)
	if currentStage.fadeOutTime > 0:
		$Canvas / ScreenOverlay.fadeOutCallback(currentStage.fadeOutTime, self, "_addInterleaveStage")
	else:
		_addInterleaveStage()

func _addInterleaveStage():
	var oldStage = pausedStages.back()
	find_node("CurrentStage").remove_child(oldStage)
	_addNewStage()

func getPauseScreenInfo():
	if currentStage:
		return currentStage.getPauseScreenInfo()
	return null

func getContext()->String:
	var s: = "current="
	if currentStage:
		s += currentStage.getContext()
	return s
