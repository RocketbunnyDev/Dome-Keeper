extends HudElement

func init():
	Data.listen(self, "inventory.iron", true)
	Data.listen(self, "inventory.water", true)
	Data.listen(self, "inventory.sand", true)

func propertyChanged(property: String, oldValue, newValue):
	match property:
		"inventory.iron":
			find_node("LabelIron").text = str(clamp(newValue, 0, 99))
		"inventory.water":
			find_node("LabelWater").text = str(clamp(newValue, 0, 99))
		"inventory.sand":
			find_node("LabelSand").text = str(clamp(newValue, 0, 99))
