extends HudElement

func init():
	Data.listen(self, "repellent.remainingbattleuses", true)
	Data.listen(self, "repellent.battleuses", true)

func propertyChanged(property: String, oldValue, newValue):
	match property:
		"repellent.remainingbattleuses":
			updateCharges(newValue)
		"repellent.battleuses":
			updateSlots(newValue)

func updateSlots(amount):
	for i in range(1, 4):
		get_node("Slot" + str(i)).visible = amount >= i
	match int(amount):
		1:
			size.x = 2
			size.y = 1
		2:
			size.x = 2
			size.y = 2
			for c in get_children():
				c.rect_position.y += 2
		3:
			size.x = 2
			size.y = 2
			for c in get_children():
				c.rect_position.y -= 2
	emit_signal("request_rebuild")
	
func updateCharges(charges):
	for i in range(1, 4):
		find_node("Charge" + str(i)).visible = charges >= i
