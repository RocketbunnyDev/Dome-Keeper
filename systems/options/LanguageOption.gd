extends PanelContainer

signal request_change()





func init(flag: Texture, language: String, description: String):
	find_node("Flag").texture = flag
	find_node("Language").text = language
	if description == "":
		find_node("TranslationType").visible = false
	else:
		find_node("TranslationType").text = description
	$SelectedPanel.visible = false
	
func _on_LanguageOption_focus_entered():


	$SelectedPanel.visible = true

func _on_LanguageOption_focus_exited():


	$SelectedPanel.visible = false

func _on_LanguageOption_gui_input(event):


	if event is InputEventMouseButton and event.pressed and event.button_index == BUTTON_LEFT:
		emit_signal("request_change")
	
	if Input.is_action_pressed("ui_accept"):
		emit_signal("request_change")

func _on_LanguageOption_mouse_entered():


	$SelectedPanel.visible = false


	set("custom_styles/panel", preload("res://gui/buttons/button_hover.tres"))

func _on_LanguageOption_mouse_exited():


	find_node("Language").set("custom_colors/font_color", null)
	modulate = Color.white
	if not has_focus():



		set("custom_styles/panel", preload("res://gui/buttons/button_normal.tres"))

