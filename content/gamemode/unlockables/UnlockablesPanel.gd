extends PanelContainer

signal proceed
signal back

export (bool) var showButtons: = false

var isIn: = false
var animationDone: = false
var selectedUnlockable: = ""
var firstPanel

func init():
	if GameWorld.unlockableElements.size() == 0:
		visible = false
		return 
	
	while GameWorld.unlockableElements.size() > 3:
		
		GameWorld.unlockableElements.remove(randi() % GameWorld.unlockableElements.size())
	
	for u in GameWorld.unlockableElements:
		var panel = preload("res://content/gamemode/unlockables/UnlockOption.tscn").instance()
		panel.init(u)
		find_node("Options").add_child(panel)
		if selectedUnlockable == "":
			selectedUnlockable = u
			panel.grab_focus()
			panel.pressed()
			firstPanel = panel
		panel.connect("selected", self, "unlockableSelected", [u])
	
	find_node("Buttons").visible = showButtons
	
	Style.init(self)

func unlockableSelected(u):
	selectedUnlockable = u
	for c in find_node("Options").get_children():
		if u != c.id:
			c.releasePressed()

func applyUnlockable():
	if selectedUnlockable == "---":
		
		return 
	
	if selectedUnlockable != "":
		GameWorld.unlockElement(selectedUnlockable)
		Achievements.reactOnUnlock(selectedUnlockable)
		selectedUnlockable = "---"
		GameWorld.persistMetaState()

func _on_ProceedButton_pressed():
	find_node("ProceedButton").release_focus()
	find_node("ProceedButton").disabled = true
	find_node("CancelButton").disabled = true
	for c in find_node("Options").get_children():
		if selectedUnlockable != c.id:
			c.reject()
		else:
			c.highlight()
	Audio.sound("gui_unlock_upgrade")
	$Tween.interpolate_property(self, "rect_position", rect_position, rect_position + Vector2(0, - 25), 1.0, Tween.TRANS_QUAD, Tween.EASE_OUT)
	$Tween.interpolate_property(self, "rect_position", rect_position + Vector2(0, - 25), rect_position + Vector2(0, 1000), 0.5, Tween.TRANS_BACK, Tween.EASE_IN, 1.0)
	$Tween.interpolate_callback(self, 1.5, "emit_signal", "proceed")
	$Tween.start()

func _on_CancelButton_pressed():
	emit_signal("back")
	find_node("CancelButton").disabled = true
	find_node("ProceedButton").disabled = true

func getFirstPanel():
	return firstPanel
