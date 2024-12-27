extends Node

var achievements: = {}

func isOpen(id: String):
	var state: int
	if achievements.has(id):
		state = achievements[id]
	else:
		var achievement: Dictionary = SteamGlobal.Steam.getAchievement(id)
		
		if achievement.get("achieved", false) == false:
			state = 0
		else:
			state = 1
		achievements[id] = state
	
	return state == 0

func triggerIfOpen(id: String):
	if isOpen(id):
		Logger.info("Achievement " + id + " triggered.")
		SteamGlobal.Steam.setAchievement(id)
		SteamGlobal.Steam.storeStats()

func addIfOpen(parent, id: String):
	if isOpen(id):
		add(parent, id)

func add(parent, id: String):
	var a = load("res://content/achievements/Achievement_" + id + ".tscn")
	if a:
		var ac = a.instance()
		ac.id = id
		parent.add_child(ac)
	else:
		Logger.error("achievement scene does not exist", "Achievements.addIfOpen", id)

func reactOnUnlock(unlock: String):
	match unlock:
		"shield-battle3":
			triggerIfOpen("SHIELD_COMPLETE")
		"repellent-battle3":
			triggerIfOpen("REPELLENT_COMPLETE")
		"orchard-battle2":
			triggerIfOpen("ORCHARD_COMPLETE")
		_:
			triggerIfOpen(unlock.to_upper() + "_UNLOCK")

func incrementStat(id: String):
	var val = SteamGlobal.Steam.getStatInt(id) + 1
	SteamGlobal.Steam.setStatInt(id, val)
	if val >= 10:
		if id == "run_wins" and isOpen("RUN_WINMANY"):
			SteamGlobal.Steam.setAchievement("RUN_WINMANY")
		elif id == "run_losses" and isOpen("RUN_LOSEMANY"):
			SteamGlobal.Steam.setAchievement("RUN_LOSEMANY")
	SteamGlobal.Steam.storeStats()
