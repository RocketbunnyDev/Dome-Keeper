extends Node

signal loggedIn

export (bool) var logEvents: = false

export (Array, String) var ignoredEvents: = []

var eventCounter: = 1
var enableTracking: bool

var playerId: = ""
var sessionId: = ""
var userToken: = ""

func init():
	var save: = File.new()
	var err = save.open("user://id.txt", File.READ)
	if err == OK:
		var i = save.get_as_text()
		var parsed = JSON.parse(i)
		if parsed.result:
			playerId = parsed.result.get("player-id", "")
			if playerId == "qa-debug":
				enableTracking = false
	save.close()
	
	if playerId == "":
		err = save.open("user://id.txt", File.WRITE)
		if err == OK:
			playerId = UUID.v4()
			Logger.info("generated random player id", "Backend.init", playerId)
			save.store_string(JSON.print({"player-id": playerId}))
		save.close()
	
	if not playerId:
		enableTracking = false
	
	if enableTracking:
		var combined_info_request_params = GetPlayerCombinedInfoRequestParams.new()
		combined_info_request_params.show_all()
		$PlayFabClient.login_with_custom_id(playerId, true, combined_info_request_params)
	
		var d = OS.get_datetime()
		var date = str(d["year"]) + "-" + str(d["month"]).pad_zeros(2) + "-" + str(d["day"]).pad_zeros(2) + "-" + str(d["hour"]).pad_zeros(2) + "-" + str(d["minute"]).pad_zeros(2)
		sessionId = playerId + "_" + date
		
		var data = {"date": OS.get_datetime(), 
		"startupTime": OS.get_ticks_msec(), 
		"platform_name": OS.get_name(), 
		"version": GameWorld.version, 
		"buildType": GameWorld.buildType, 
		}
		
		event("game_launched", data)

func sendBufferedEvents():
	if enableTracking and sessionId != "":
		$PlayFabEvents._flush_playstream_event_batch()

func event(type, data = ""):
	if not enableTracking or ignoredEvents.has(type):
		return 
	
	data["idx"] = eventCounter
	data["runTime"] = GameWorld.runTime
	data["timestamp"] = OS.get_ticks_msec()
	eventCounter += 1
	$PlayFabEvents.batch_title_player_telemetry_event(type, data, funcref(self, "nothing"))
	
	if logEvents:
		print(data)

func parseRunsFromSession(session: Array)->Array:
	var runs: = []
	var meta: = {}
	var currentRun
	var timeOffset: = 0.0
	session.sort_custom(self, "sortByTime")
	for d in session:
		var type = d.get("type").to_lower()
		if type == "game_launched":
			meta = d.get("data")
		elif type == "level_launched":
			currentRun = {"cycles": [], "upgrades": [], "gadgets": [], "waves": [], "state": "", "gadgetUses": [], "battleAbility": []}
			currentRun["level"] = d.get("data")
			timeOffset = d.get("time")
		elif currentRun:
			if d.has("time"):
				d["time"] -= timeOffset
				currentRun["duration"] = max(currentRun.get("duration", 0), d["time"])
			match type:
				"cycle_change":
					currentRun["cycles"].append(d)
				"upgrade":
					currentRun["upgrades"].append(d)
				"gadget_unlocked":
					currentRun["gadgets"].append(d)
				"wave_started":
					currentRun["waves"].append(d)
				"wave_finished":
					currentRun["waves"].append(d)
				"gadget_used":
					currentRun["gadgetUses"].append(d)
				"battle_ability_used":
					currentRun["battleAbility"].append(d)
				"game_won":
					currentRun["state"] = "won"
					if currentRun.get("cycles").size() >= 3:
						runs.append(currentRun)
					currentRun = null
				"game_lost":
					currentRun["state"] = "lost"
					if currentRun.get("cycles").size() >= 3:
						runs.append(currentRun)
					currentRun = null
	
	if currentRun and currentRun.get("cycles").size() >= 3:
		runs.append(currentRun)
	
	for run in runs:
		run["meta"] = meta
	
	return runs

func sortByTime(a, b):
	return a["time"] < b["time"]

func _on_PlayFabClient_logged_in(login_result: LoginResult):
	if login_result.NewlyCreated:
		Logger.info("registered on playfab", "Backend._on_PlayFabClient_logged_in", login_result.PlayFabId)
	Logger.info("successful login", "Backend._on_PlayFabClient_logged_in", login_result.PlayFabId)

func _on_PlayFabClient_registered(r: RegisterPlayFabUserResult):
	Logger.info("registered on playfab", "Backend._on_PlayFabClient_registered", r.PlayFabId)

func _on_PlayFab_api_error(api_error_wrapper):
	Logger.error("api error on playfab request", "Backend._on_PlayFabClient_api_error", 
	{"code": api_error_wrapper.code, "error": api_error_wrapper.error, "errorCode": api_error_wrapper.errorCode, 
	"errorDetails": api_error_wrapper.errorDetails, "errorMessage": api_error_wrapper.errorMessage, "status": api_error_wrapper.status})

func _on_PlayFab_json_parse_error(json_result):
	Logger.error("json parse error on playfab request", "Backend._on_PlayFabClient_json_parse_error", 
	{"error": json_result.error, "error_string": json_result.error_string, "error_line": json_result.error_line, "result": json_result.result})

func _on_PlayFab_server_error(path):
	Logger.error("server error on playfab request", "Backend._on_PlayFabClient_server_error", path)

func _on_PlayFabEvents_event_batch_telemetry_flushed(event_ids):
	prints("flushed", event_ids)

func nothing():
	pass
