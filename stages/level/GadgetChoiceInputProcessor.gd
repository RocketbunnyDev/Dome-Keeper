extends InputProcessor

signal gadgetSelected
signal dropsSelected

var popup

func _ready():
	name = "GadgetChoiceInputProcessor"

func handleStart():
	popup.moveIn()

func handleStop():
	popup.moveOut()

func becameLeaf():
	popup.moveIn()

func notLeaf():
	popup.moveOut()

func keyEvent(event)->bool:
	if justPressed(event, "ui_select") and popup.animationDone:
		if popup.selectedGadget.has("amount"):
			
			

			emit_signal("dropsSelected", popup.selectedGadget.get("dropType", CONST.IRON), popup.selectedGadget.get("amount", 0))
			Audio.sound("cobaltscavenge")
		else:
			emit_signal("gadgetSelected", popup.selectedGadget.get("id"))
			Audio.sound("gadgetinsert")
		desintegrate()
	elif justPressed(event, "escape"):
		return true
	
	return true
