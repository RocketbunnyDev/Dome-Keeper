extends CenterContainer

var cooldown: = 10.0
var overlay

var done: = true

func _ready():
	visible = false
	$PanelContainer.rect_pivot_offset = $PanelContainer.rect_size * 0.5
	Style.init(self)

func _process(delta):
	if done:
		return 
	
	cooldown -= delta
	var newText = str(abs(round(cooldown)))
	if find_node("LabelTime").text != newText:
		find_node("LabelTime").text = newText
		Audio.sound("alarm")
	if cooldown <= 0.0:
		done = true
		StageManager.startStage("stages/title/title")

func fadeIn(t: float = 0.5):
	visible = true
	
	done = false
	cooldown = 10.49
	overlay.showOverlay()
	Audio.sound("gui_pause_start")
	Audio.muteSounds()
	

func fadeOut(t: float = 0.5):
	visible = false
	overlay.hideOverlay()
	done = true
	Audio.sound("gui_pause_stop")
	Audio.unmuteSounds()
