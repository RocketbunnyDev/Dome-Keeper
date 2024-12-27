extends PanelContainer

var currentlySelected = null

var firstOption = null

func init():
	var gadgets: = []
	for g in Data.gadgets:
		if Data.gadgets[g].get("slot", "primary") != "primary" and GameWorld.boughtUpgrades.has(g):
			gadgets.append(g)
	
	if gadgets.size() == 0:
		visible = false
		return 
	
	for id in gadgets:
		var choice = preload("res://content/gamemode/gadgetchoice/GadgetOption.tscn").instance()
		choice.init(id)
		choice.connect("selected", self, "gadgetSelected", [choice])
		find_node("GadgetContainer").add_child(choice)
		if GameWorld.gadgetToKeep == id:
			choice.select()
			firstOption = choice
			currentlySelected = choice
		if not firstOption:
			firstOption = choice
	
	if not currentlySelected:
		GameWorld.gadgetToKeep = ""
	
	updateKeepingLabel()
	GameWorld.keptGadgetUsed = false
	
	Style.init(self)

func updateKeepingLabel():
	var gadgetName: String
	if currentlySelected:
		gadgetName = tr("upgrades." + GameWorld.gadgetToKeep + ".title")
		find_node("SelectedGadgetLabel").bbcode_text = tr("level.gameover.keepgadget.keeping").format({"gadget": gadgetName})
	else:
		gadgetName = tr("level.gameover.keepgadget.none")
		find_node("SelectedGadgetLabel").bbcode_text = "[wave amp=20 freq=6]" + tr("level.gameover.keepgadget.keeping").format({"gadget": gadgetName}) + "[/wave]"

func gadgetSelected(gadgetPanel):
	Audio.sound("gui_select")
	
	if currentlySelected:
		currentlySelected.unselect()
		if currentlySelected == gadgetPanel:
			GameWorld.gadgetToKeep = ""
			currentlySelected = null
			updateKeepingLabel()
			return 
	
	currentlySelected = gadgetPanel
	currentlySelected.select()
	GameWorld.gadgetToKeep = gadgetPanel.id
	updateKeepingLabel()

func getFirstOption():
	return firstOption
