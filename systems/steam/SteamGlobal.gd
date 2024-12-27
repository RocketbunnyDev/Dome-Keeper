extends Node

onready var Steam = preload("res://addons/godotsteam/godotsteam.gdns").new()


var IS_OWNED: bool = false
var IS_ONLINE: bool = false
var STEAM_ID: int = 0
var STEAM_USERNAME: String
var statsReceived: = false


func init(lockToSteam: bool = false):
	
	Steam.connect("current_stats_received", self, "_steam_Stats_Ready", [], CONNECT_ONESHOT)
	var INIT: Dictionary = Steam.steamInit()

	if INIT["status"] != 1:
		Logger.error("Steam failed to initialize: " + str(INIT["verbal"]), "SteamGlobal._initialize_Steam")
		if not GameWorld.devMode and lockToSteam:
			get_tree().quit()
		return 
	
	Logger.info("Steam App ID: " + str(Steam.getAppID()))
	IS_ONLINE = Steam.loggedOn()
	STEAM_ID = Steam.getSteamID()
	IS_OWNED = Steam.isSubscribed()
	STEAM_USERNAME = Steam.getPersonaName()

	
	if IS_OWNED == false and lockToSteam:
		print("[STEAM] User does not own this game")
		
		get_tree().quit()


func _process(_delta: float)->void :
	Steam.run_callbacks()

func _steam_Stats_Ready(game: int, result: int, user: int)->void :
	statsReceived = true




