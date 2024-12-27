extends Control

func _ready():
	GameWorld.unlockableElements.clear()
	GameWorld.unlockedElements.clear()
	GameWorld.unlockableElements.append("repellent")
	GameWorld.unlockableElements.append(CONST.MODE_PRESTIGE)
	GameWorld.unlockableElements.append("shield-battle2")

	Audio.sound("gui_select")
	var i = preload("res://gui/PopupInput.gd").new()
	var unlockablesPopup = preload("res://content/gamemode/unlockables/UnlockablesPopup.tscn").instance()
	unlockablesPopup.connect("proceed", i, "desintegrate")
	unlockablesPopup.connect("back", i, "desintegrate")
	unlockablesPopup.connect("back", self, "updateFocus")
	unlockablesPopup.connect("back", unlockablesPopup, "queue_free")
	add_child(unlockablesPopup)
	i.popup = unlockablesPopup
	i.integrate(self)
	i.handleStart()
