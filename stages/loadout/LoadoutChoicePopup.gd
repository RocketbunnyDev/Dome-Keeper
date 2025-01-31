extends Container

signal choice_made

var isIn: = false
var type: = ""

var backgroundHide
var panelsByOption: = {}

func addOptions(type: String, options: Array, focusOption, locked: = []):
	self.type = type
	find_node("PanelTitleLabel").text = "loadout." + type + "options.title"
	
	panelsByOption.clear()
	var cc = find_node("ChoicesContainer")
	for child in cc.get_children():
		child.queue_free()
	
	if options.size() <= 4:
		cc.columns = 2
	else:
		cc.columns = 3
	
	for option in options:
		var isLocked = locked.has(option)
		var panel = preload("res://stages/loadout/LoadoutOption.tscn").instance()
		var elementOk = GameWorld.unlockedElements.has(option) and not isLocked
		var petOk = GameWorld.unlockedPets.has(option) or option == "pet0"
		var skinOk = GameWorld.unlockedSkins.get(GameWorld.lastKeeperId, []).has(option) or option == "skin0"
		
		if option == CONST.MODE_PRESTIGE and not SteamGlobal.IS_OWNED:
			elementOk = false
		
		panel.disabled = not (petOk or elementOk or skinOk)
		panel.init(option, not isLocked, petOk, skinOk)
		panel.connect("selected", self, "select")
		cc.add_child(panel)
		if option == focusOption:
			InputSystem.grabFocus(panel)
		panelsByOption[option] = panel

func select():
	for option in panelsByOption:
		if panelsByOption[option].has_focus():
			if panelsByOption[option].disabled:
				Audio.sound("gui_err")
			else:
				emit_signal("choice_made", type, option)
			return 

func moveIn():
	if isIn:
		return 
	
	isIn = true
	$Tween.stop_all()
	$Tween.remove_all()
	
	$Tween.interpolate_property(backgroundHide, "modulate:a", 0.0, 1.0, 0.3)
	$Tween.interpolate_property(self, "rect_position:y", rect_position.y, get_viewport_rect().size.y * 0.5 - rect_size.y * 0.5, 0.6, Tween.TRANS_CUBIC, Tween.EASE_OUT)
	$Tween.start()
	
func moveOut():
	if not isIn:
		return 
	
	isIn = false
	$Tween.stop_all()
	$Tween.remove_all()
	$Tween.interpolate_property(backgroundHide, "modulate:a", 1.0, 0.0, 0.3)
	$Tween.interpolate_property(self, "rect_position:y", rect_position.y, get_viewport_rect().size.y, 0.3, Tween.TRANS_CUBIC, Tween.EASE_IN)
	$Tween.start()
