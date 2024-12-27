extends HBoxContainer

func setPopup(popup):
	var p = getPopup()
	if p == popup:
		return 
	find_node("PopupContainer").add_child(popup)

func hasPopup()->bool:
	var popup = find_node("*Popup", true, false)
	return popup != null

func getPopup():
	var popup = find_node("*Popup", true, false)
	return popup

func init(parent):
	pass

func end():
	pass
