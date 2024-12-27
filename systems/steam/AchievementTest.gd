extends Node2D



var ACHIEVEMENTS: Dictionary = {
	"ACHIEVEMENT_LASER_WINGAME": false, 
	"ACHIEVEMENT_GAME_START": false, 
	}



func _ready():
	
	
	
	
	
	
	
	SteamGlobal.Steam.connect("current_stats_received", self, "_steam_Stats_Ready", ["current"])
	
	
	
	
	
	SteamGlobal.Steam.connect("user_stats_received", self, "_steam_Stats_Ready", ["user"])
	
	for ACHIEVEMENT in ACHIEVEMENTS.keys():
		$Achievements.add_item(ACHIEVEMENT)
	
		
	if SteamGlobal.IS_ONLINE:
		$VBoxContainer / Label.set_text("Steamworks Status (Online)")
	else:
		
		pass
	$VBoxContainer / Label2.set_text("Steam ID: " + str(SteamGlobal.STEAM_ID))
	$VBoxContainer / Label3.set_text("Username: " + str(SteamGlobal.STEAM_USERNAME))
	$VBoxContainer / Label4.set_text("Owns App: " + str(SteamGlobal.IS_OWNED))



func _on_AchievmentUnlocked_pressed():
	var THIS_ID: int = $Achievements.get_selected_id()
	var THIS_ACHIEVE: String = $Achievements.get_item_text(THIS_ID)
	
	ACHIEVEMENTS[THIS_ACHIEVE] = true
	$Text.append_bbcode("----" + THIS_ACHIEVE + "\n")

	
	
	var SET_ACHIEVE: bool = SteamGlobal.Steam.setAchievement("ACHIEVEMENT_LASER_WINGAME")
	$Text.append_bbcode("[STEAM] Achievement " + str("ACHIEVEMENT_LASER_WINGAME") + " set correctly: " + str(SET_ACHIEVE) + "\n")

	
	var STORE_STATS: bool = SteamGlobal.Steam.storeStats()
	$Text.append_bbcode("[STEAM] Stats and achievements stored correctly: " + str(STORE_STATS) + "\n")


func _on_AchievmentLocked_pressed():
	var THIS_ID: int = $Achievements.get_selected_id()
	var THIS_ACHIEVE: String = $Achievements.get_item_text(THIS_ID)
	var GET_ACHIEVE = SteamGlobal.Steam.getAchievement(THIS_ACHIEVE)
	$Text.append_bbcode("[STEAM] Achievement " + str(THIS_ACHIEVE) + " get correctly: " + str(GET_ACHIEVE) + "\n")
	SteamGlobal.Steam.requestUserStats(SteamGlobal.STEAM_ID)
	
	SteamGlobal.Steam.resetAllStats(true)
