extends Container

var isIn: = false

var animationDone: bool
var focussedPanel

func _ready():
	rect_position.y += rect_size.y
	find_node("TechTree").build()
	
	find_node("Inventory").visible = true
	find_node("LabelIron").text = str(Data.getInventory(CONST.IRON))
	find_node("LabelWater").text = str(Data.getInventory(CONST.WATER))
	find_node("LabelSand").text = str(Data.getInventory(CONST.SAND))
	
	Options.setActionIcons(find_node("Controls"))
	
	Data.listen(self, "inventory.iron")
	Data.listen(self, "inventory.water")
	Data.listen(self, "inventory.sand")
	
	Style.init(self)

func propertyChanged(property: String, oldValue, newValue):
	match property:
		"inventory.iron":
			find_node("LabelIron").text = str(clamp(newValue, 0, 99))
		"inventory.water":
			find_node("LabelWater").text = str(clamp(newValue, 0, 99))
		"inventory.sand":
			find_node("LabelSand").text = str(clamp(newValue, 0, 99))
	updateCostLabels()

func focus():
	find_node("TechTree").focus()

func techTree():
	return find_node("TechTree")

func moveIn():
	if isIn:
		return 
	
	visible = true
	isIn = true
	animationDone = false
	
	$Tween.interpolate_property(self, "rect_position:y", rect_position.y, get_viewport_rect().size.y - rect_size.y, 0.3, Tween.TRANS_CUBIC, Tween.EASE_OUT)
	$Tween.interpolate_callback(self, 0.4, "set", "animationDone", true)
	$Tween.start()
	
func moveOut():
	if not isIn:
		return 
	
	isIn = false
	
	Data.unlisten(self, "inventory.iron")
	Data.unlisten(self, "inventory.water")
	Data.unlisten(self, "inventory.sand")
	Data.apply("dome.potentialrepair", 0)
	
	$Tween.interpolate_property(self, "rect_position:y", rect_position.y, get_viewport_rect().size.y, 0.3, Tween.TRANS_CUBIC, Tween.EASE_IN)
	$Tween.interpolate_callback(self, 0.5, "queue_free")
	$Tween.start()
	
	if focussedPanel:
		focussedPanel.release_focus()
	focussedPanel = null
	
func buyUpgrade():
	if animationDone:
		find_node("TechTree").buyCurrentUpgrade()
		updateCostLabels()

func _on_TechTree_techFocussed(techPanel)->void :
	if not isIn:
		return 
	
	find_node("TechTitle").text = techPanel.title
	find_node("TechDescription").bbcode_text = tr(techPanel.explanationBb)
	
	
	var bonusSection = find_node("BonusSection")
	for c in bonusSection.get_children():
		c.free()
	
	
	var regex = RegEx.new()
	regex.compile("\\{.*\\}")
	for propertyChange in techPanel.propertyChanges:
		if propertyChange.hidden:
			continue
		
		var outString = null
		var translationKey = "properties." + propertyChange.key
		var template = tr(translationKey)
		if template != translationKey:
			var result = regex.search(template)
			if not result or result.strings.empty():
				
				outString = template
			else:
				var placeholder = result.strings.front()
				var before
				var after
				var replacement: = ""
				if propertyChange.cumulative:
					before = 0
					after = propertyChange.value
					if propertyChange.value > 0:
						replacement = "+"
				else:
					before = Data.of(propertyChange.key)
					after = propertyChange.value
				
				var unit: = ""
				var dotPos = placeholder.find(".")
				if dotPos > 1:
					unit = placeholder.substr(1, dotPos - 1)
				var isPercent = placeholder.find(".percent") != - 1
				if isPercent:
					before = int(before * 100)
					after = int(after * 100)
					unit = "%"
				
				if (typeof(before) == TYPE_INT or typeof(before) == TYPE_REAL):
					
					var valueTemplate: String
					if after == int(after):
						valueTemplate = "%d"
					else:
						valueTemplate = "%0.2f"
					if propertyChange.multiplicative:
						valueTemplate = "*" + valueTemplate
					
					replacement += valueTemplate % [after] + unit
					var suffix: = ""
					if propertyChange.cumulative:
						if not isPercent and before != after:
							var delta = 0.0
							if before > 0:
								delta = (float(after) - float(before)) * 100.0 / float(before)
								var delta_sign = "+" if delta > 0 else ""
								suffix = " (%s%d%%)" % [delta_sign, delta]
					outString = regex.sub(template, replacement) + suffix
				else:
					outString = template
	
			var box = HBoxContainer.new()
			box.set("custom_constants/separation", 8)
			var icon = TextureRect.new()






			icon.texture = preload("res://content/techtree/common/star.png")
			icon.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
			box.add_child(icon)

			var label = Label.new()
			label.align = Label.ALIGN_LEFT
			label.autowrap = true
			label.size_flags_horizontal = SIZE_EXPAND_FILL
			label.text = outString
			box.add_child(label)
			bonusSection.add_child(box)
			Style.init(box)
	
	focussedPanel = techPanel
	updateCostLabels()
	





func updateCostLabels():
	find_node("LabelIronCost").text = ""
	find_node("LabelWaterCost").text = ""
	find_node("LabelSandCost").text = ""
	
	if not focussedPanel:
		return 
	
	var costs = GameWorld.upgrades[focussedPanel.techId].get("cost", [])
	for costType in costs:
		var cost = costs[costType]
		var newInventory = int(Data.getInventory(costType)) - int(cost)
		var color = null
		if GameWorld.boughtUpgrades.has(focussedPanel.techId):
			newInventory = 0
		if newInventory < 0:
			color = Style.FONT_COLOR_WARNING
		find_node("Label" + costType.capitalize() + "Cost").text = "%s" % cost
		find_node("Label" + costType.capitalize() + "Cost").set("custom_colors/font_color", color)
