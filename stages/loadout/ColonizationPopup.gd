extends "res://stages/loadout/ModePopup.gd"

func _ready():
	find_node("OptionScoresButton").pressed = GameWorld.lastAdditionalUpgradeLimits.has("highscore")
	find_node("OptionFuelButton").pressed = GameWorld.lastAdditionalUpgradeLimits.has("fuel")

func _on_OptionScoresButton_toggled(button_pressed):
	if button_pressed:
		if not GameWorld.lastAdditionalUpgradeLimits.has("highscore"):
			GameWorld.lastAdditionalUpgradeLimits.append("highscore")
	else:
		if GameWorld.lastAdditionalUpgradeLimits.has("highscore"):
			GameWorld.lastAdditionalUpgradeLimits.erase("highscore")

func _on_OptionFuelButton_toggled(button_pressed):
	if button_pressed:
		if not GameWorld.lastAdditionalUpgradeLimits.has("fuel"):
			GameWorld.lastAdditionalUpgradeLimits.append("fuel")
	else:
		if GameWorld.lastAdditionalUpgradeLimits.has("fuel"):
			GameWorld.lastAdditionalUpgradeLimits.erase("fuel")
