extends HudElement

func init():
	Data.listen(self, "probe.chargesRemaining")
	Data.listen(self, "probe.charges")
	updateSlots()
	updateCharges()

func propertyChanged(property: String, oldValue, newValue):
	match property:
		"probe.chargesremaining":
			updateCharges()
		"probe.charges":
			updateSlots()

func updateSlots():
	var unlocked = Data.of("probe.charges")
	for i in range(1, 5):
		get_node("Slot" + str(i)).visible = unlocked >= i
	match int(unlocked):
		2:
			size.y = 3
		4:
			size.y = 6
	emit_signal("request_rebuild")

func updateCharges():
	var unlocked = Data.of("probe.chargesRemaining")
	for i in range(1, 5):
		find_node("Charge" + str(i)).visible = unlocked >= i
