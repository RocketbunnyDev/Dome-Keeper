extends Container

signal selected

var id: String
var disabled: = false
var titleText: String
var starting_position = null

func _ready():
	Style.init(self)

	$Back.hide()
	
	yield (get_tree().create_timer(0.1), "timeout")
	rect_pivot_offset = rect_size / 2
	starting_position = rect_position

func _process(_delta):
	if starting_position != null:
		if has_focus():
			rect_position.y = starting_position.y + sin(OS.get_ticks_msec() / 200.0) * 4
		else:
			rect_position = starting_position
	
func init(id: String):
	self.id = id
	var icon: String
	var titleKey: String
	var descKey: String
	var type: String
	match id:
		"dome2":
			icon = "loadout_dome2"
			titleKey = "upgrades.dome2.title"
			descKey = "upgrades.dome2.desc"
			type = "level.gameover.unlock.dome"
		"keeper2":
			icon = "loadout_keeper2"
			titleKey = "upgrades.keeper2.title"
			descKey = "upgrades.keeper2.desc"
			type = "level.gameover.unlock.keeper"
		"shield-battle2":
			icon = "loadout_shield"
			titleKey = "upgrades.shieldbattlereflect.title"
			descKey = "upgrades.shieldbattlereflect.desc"
			type = "level.gameover.unlock.gadgetability"
		"shield-battle3":
			icon = "loadout_shield"
			titleKey = "upgrades.shieldbattleinvulnerable.title"
			descKey = "upgrades.shieldbattleinvulnerable.desc"
			type = "level.gameover.unlock.gadgetability"
		"repellent":
			icon = "loadout_repellent"
			titleKey = "upgrades.repellent.title"
			descKey = "upgrades.repellent.desc"
			type = "level.gameover.unlock.gadget"
		"repellent-battle2":
			icon = "loadout_repellent"
			titleKey = "upgrades.repellentbattlehealthreduction.title"
			descKey = "upgrades.repellentbattlehealthreduction.desc"
			type = "level.gameover.unlock.gadgetability"
		"repellent-battle3":
			icon = "loadout_repellent"
			titleKey = "upgrades.repellentbattleslowdownstun1.title"
			descKey = "upgrades.repellentbattleslowdownstun2.title"
			type = "level.gameover.unlock.gadgetability"
		"orchard":
			icon = "loadout_orchard"
			titleKey = "upgrades.orchard.title"
			descKey = "upgrades.orchard.desc"
			type = "level.gameover.unlock.gadget"
		"orchard-battle2":
			icon = "loadout_orchard"
			titleKey = "upgrades.orchardbattleshield.title"
			descKey = "upgrades.orchardbattleshield.desc"
			type = "level.gameover.unlock.gadgetability"
		CONST.MODE_PRESTIGE:
			icon = "loadout_prestige"
			titleKey = "upgrades.prestige.title"
			descKey = "upgrades.prestige.desc"
			type = "level.gameover.unlock.gamemode"
		CONST.MODE_PRESTIGE_COBALT:
			icon = "loadout_prestige"
			titleKey = "loadout.prestige.cobalt"
			descKey = "loadout.prestige.cobalt.description"
			type = "level.gameover.unlock.gamemodevariant"
		CONST.MODE_PRESTIGE_COUNTDOWN:
			icon = "loadout_prestige"
			titleKey = "loadout.prestige.countdown"
			descKey = "loadout.prestige.countdown.description"
			type = "level.gameover.unlock.gamemodevariant"
		CONST.MODE_PRESTIGE_MINER:
			icon = "loadout_prestige"
			titleKey = "loadout.prestige.miner"
			descKey = "loadout.prestige.miner.description"
			type = "level.gameover.unlock.gamemodevariant"
			
	find_node("IconRect").texture = load("res://content/icons/" + icon + ".png")
	titleText = tr(titleKey)
	find_node("TitleLabel").text = titleText
	find_node("TypeTitleLabel").text = tr(type)
	find_node("DescriptionLabel").bbcode_text = tr(descKey)
	
func _on_LoadoutOption_focus_entered():
	set("custom_styles/panel", preload("res://gui/buttons/button_pressed.tres"))

func _on_LoadoutOption_focus_exited():
	set("custom_styles/panel", preload("res://gui/buttons/button_normal.tres"))

func _on_LoadoutOption_gui_input(event):
	if (event is InputEventMouseButton and event.pressed and event.button_index == BUTTON_LEFT)\
	 or (InputMap.event_is_action(event, "ui_select") and event.pressed):
		emit_signal("selected")
		Audio.sound("gui_select")
		pressed()

func _on_LoadoutOption_mouse_entered():
	find_node("TitleLabel").set("custom_colors/font_color", Style.LIVE_BRIGHT)
	set("custom_styles/panel", preload("res://gui/buttons/button_hover.tres"))
		

func _on_LoadoutOption_mouse_exited():
	find_node("TitleLabel").set("custom_colors/font_color", null)
	modulate = Color.white
	if not has_focus():
		set("custom_styles/panel", preload("res://gui/buttons/button_normal.tres"))

func pressed():
	set("custom_styles/panel", preload("res://gui/buttons/button_pressed.tres"))
	if has_focus():
		$Tween.interpolate_property(self, "rect_scale", Vector2(1, 1), Vector2(0, 1), 0.1, Tween.TRANS_SINE, Tween.EASE_OUT)
		$Tween.interpolate_property(self, "rect_scale", Vector2(0, 1), Vector2(1, 1), 0.1, Tween.TRANS_SINE, Tween.EASE_OUT, 0.1)
		$Tween.interpolate_property(self, "rect_scale", Vector2(1, 1), Vector2(1.05, 1.05), 0.2, Tween.TRANS_SINE, Tween.EASE_OUT, 0.2)
		$Tween.interpolate_property(self, "rect_scale", Vector2(1.05, 1.05), Vector2(1.0, 1.0), 0.2, Tween.TRANS_SINE, Tween.EASE_IN_OUT, 0.4)
		$Tween.start()
		yield (get_tree().create_timer(0.2), "timeout")
		grab_focus()
		set("custom_styles/panel", preload("res://gui/buttons/button_hover.tres"))
	
func releasePressed():
	set("custom_styles/panel", preload("res://gui/buttons/button_normal.tres"))


func highlight():
	$Tween.interpolate_property(self, "rect_scale", Vector2(1, 1), Vector2(1.05, 1.05), 0.3, Tween.TRANS_SINE, Tween.EASE_OUT)
	$Tween.start()

func reject():
	$Back.show()
	$Tween.interpolate_property(self, "rect_scale", Vector2(1, 1), Vector2(0, 1), 0.1, Tween.TRANS_SINE, Tween.EASE_OUT)
	$Tween.interpolate_property(self, "rect_scale", Vector2(0, 1), Vector2(1, 1), 0.1, Tween.TRANS_SINE, Tween.EASE_OUT, 0.1)
	$Tween.start()
