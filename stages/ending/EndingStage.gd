extends Stage

var world: = 0

var worlds: = [
	preload("res://stages/ending/World8SketchColor4Example.png"), 
	preload("res://stages/ending/World7Color4_Export.png"), 
	preload("res://stages/ending/World9Concept3_Color3_Export.png"), 
	preload("res://stages/ending/World10Concept_Color2_Example.png"), 
	preload("res://stages/ending/World11Concept_Color4_Example.png"), 
]

var worldIndex: = 0

func beforeStart():
	Style.setPalette("1_1")
	Style.init($Canvas / MarginContainer)
	
	if GameWorld.buildType == CONST.BUILD_TYPE.EXHIBITION:
		find_node("WishlistButton").visible = false
		find_node("DiscordButton").visible = false
		InputSystem.grabFocus(find_node("EndButton"))
	else:
		InputSystem.grabFocus(find_node("WishlistButton"))

func beforeEnd():
	Audio.stopMusic()

func _on_WishlistButton_pressed():
	OS.shell_open("steam://openurl/https://store.steampowered.com/app/1637320/")

func _on_VideoPlayer_finished():
	find_node("VideoPlayer").play()

func _on_DiscordButton_pressed():
	OS.shell_open("https://discord.gg/AxYpX7AaFP")

func _on_Button_pressed():
	StageManager.startStage("stages/title/title")

func _on_WorldTimer_timeout():
	worldIndex += 1
	find_node("WorldTexture").texture = worlds[worldIndex % worlds.size()]
	$WorldTimer.start()
