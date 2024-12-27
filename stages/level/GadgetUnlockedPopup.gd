extends PanelContainer

var isIn: = false
var animationDone: = false

func init(type: String, id: String):
	var headline: String
	match type:
		CONST.LOADOUT_DOME:
			headline = tr("level.gameover.domeunlock.title")
		CONST.LOADOUT_KEEPER:
			headline = tr("level.gameover.keeperunlock.title")
		CONST.LOADOUT_GAMEMODE:
			headline = tr("level.gameover.gamemodeunlock.title")
		CONST.LOADOUT_GADGET:
			headline = tr("level.gameover.gadgetunlock.title")
	find_node("LoadoutOption").init(id)
	
	Style.init(self)

func done():
	if isIn and animationDone:
		Audio.sound("gui_select")
		StageManager.startStage("stages/ending/ending")

func moveIn():
	if isIn:
		return 
	
	isIn = true
	$Tween.stop_all()
	$Tween.remove_all()
	$Tween.interpolate_property(self, "rect_position:y", rect_position.y, (get_viewport_rect().size.y - rect_size.y) * 0.5, 0.6, Tween.TRANS_CUBIC, Tween.EASE_OUT)
	$Tween.interpolate_callback(self, 0.7, "set", "animationDone", true)
	$Tween.interpolate_callback(InputSystem, 2.0, "grabFocus", find_node("Button"))
	$Tween.start()

