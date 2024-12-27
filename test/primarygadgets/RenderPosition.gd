extends Node2D

func _ready():
	GameWorld.prepareCleanData()
	
	$Dome1_1.unlockGadget(Data.gadgets.get("orchard"))
	$Dome1_2.unlockGadget(Data.gadgets.get("repellent"))
	$Dome1_3.unlockGadget(Data.gadgets.get("shield"))
	$Dome2_1.unlockGadget(Data.gadgets.get("orchard"))
	$Dome2_2.unlockGadget(Data.gadgets.get("repellent"))
	$Dome2_3.unlockGadget(Data.gadgets.get("shield"))
	Data.apply("shield.stage", 2)
