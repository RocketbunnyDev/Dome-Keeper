extends TextureRect

signal selected

var id: String
var selected: = false

func init(id: String):
	self.id = id
	$GadgetIcon.texture = load("res://content/icons/" + id + ".png")
	$GadgetIcon.rect_min_size = $GadgetIcon.texture.get_size() * 2
	$SelectedPanel.visible = false
	rect_pivot_offset = rect_size * 0.5
	rect_scale = Vector2.ONE * 1.0
	
func _on_GadgetOption_focus_entered():
	$SelectedPanel.visible = true

func _on_GadgetOption_focus_exited():
	$SelectedPanel.visible = false

func _on_GadgetOption_gui_input(event):
	if (event is InputEventMouseButton and event.pressed and event.button_index == BUTTON_LEFT)\
	 or InputMap.event_is_action(event, "ui_select") and event.pressed:
		emit_signal("selected")

func _process(delta):
	pass

func select():
	texture = preload("res://content/techtree/panels/big.png")
	rect_pivot_offset = rect_size * 0.5
	selected = true
	$Tween.stop_all()
	$Tween.remove_all()
	$Tween.interpolate_property(self, "rect_scale", rect_scale, rect_scale * 1.05, 0.5, Tween.TRANS_QUAD, Tween.EASE_IN_OUT)
	$Tween.start()

func unselect():
	texture = preload("res://content/techtree/panels/big_dark.png")
	rect_scale = Vector2.ONE
	selected = false
	
	$Tween.stop_all()
	$Tween.remove_all()
	$Tween.interpolate_property(self, "rect_scale", rect_scale, Vector2.ONE, 0.2, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	$Tween.start()

func _on_GadgetOption_mouse_entered():
	$SelectedPanel.visible = true

func _on_GadgetOption_mouse_exited():
	$SelectedPanel.visible = false

func _on_Tween_tween_all_completed():
	$Tween.interpolate_property(self, "rect_scale", rect_scale, Vector2.ONE / rect_scale, 0.5, Tween.TRANS_QUAD, Tween.EASE_IN_OUT)
	$Tween.start()
