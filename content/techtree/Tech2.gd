extends TextureRect

enum State{UNAVAILABLE, AVAILABLE, BOUGHT, LOCKED, INITIAL}

const RECT_SCALE_ON_HOVER: = 1.3

var state: int = - 1
var techId: String
var title: String
var propertyChanges: Array
var icon: Texture
var explanationBb: String
var original_position
var hasMultiplePredecessors: = false
var costLabels: = {}


var focusCounter: = 0

const colorUnavailable: = Color(40.0 / 255.0, 0, 220.0 / 256.0)
const colorAvailable: = Color(120.0 / 255.0, 0, 0.0 / 256.0)



var track

func build(id: String, tier: = - 1):
	self.techId = id
	if tier == 1:
		state = State.INITIAL
		$Icon.rect_min_size = Vector2.ONE * 144
		$Icon.rect_position = Vector2( - 4, - 4)
		texture = preload("res://content/techtree/panels/big.png")
		$SelectedPanel.texture = preload("res://content/techtree/panels/big_focus.png")
	$SelectedPanel.visible = false
	var data = GameWorld.upgrades.get(id)
	if data.has("cost"):
		var cost = data.get("cost")
		var costsBox = find_node("Costs")
		for costType in cost:
			var label = Label.new()
			label.align = Label.ALIGN_RIGHT
			label.size_flags_horizontal = label.SIZE_EXPAND_FILL
			label.text = str(cost[costType])
			label.add_to_group("unstyled")
			costsBox.add_child(label)
			costLabels[costType] = label
			
			var rect = TextureRect.new()
			var tex: Texture
			match costType:
				CONST.WATER:
					tex = preload("res://content/icons/icon_water.png")
				CONST.IRON:
					tex = preload("res://content/icons/icon_iron.png")
				CONST.SAND:
					tex = preload("res://content/icons/icon_sand.png")
			rect.texture = tex
			costsBox.add_child(rect)
	
	propertyChanges = data.get("propertychanges", [])
	
	title = tr("upgrades." + id + ".title")
	explanationBb = GameWorld.iconify(tr("upgrades." + id + ".desc"))
	
	updateState()
	
	icon = load("res://content/icons/" + id + ".png")
	find_node("Icon").texture = icon
	
	_on_Tech_focus_exited()
	





func showLockGroup():
	$lockIcon.show()
	$AnimationPlayer.play("afraid")
	$Icon.hide()
	if texture == preload("res://content/techtree/panels/two_bright.png"):
		texture = preload("res://content/techtree/panels/two_dark.png")
	elif texture == preload("res://content/techtree/panels/one_bright.png"):
		texture = preload("res://content/techtree/panels/one_dark.png")
	
func hideLockGroup():
	$Icon.show()
	$lockIcon.hide()
	$AnimationPlayer.play("calm")
	updateState()

func _on_Tech_focus_entered():
	var start: Vector2 = Vector2(1, 1)
	var end: Vector2 = Vector2(RECT_SCALE_ON_HOVER, RECT_SCALE_ON_HOVER)
	$Tween.interpolate_property(self, "rect_scale", start, end, 0.2, Tween.TRANS_SINE, Tween.EASE_OUT)
	$Tween.start()
	$SelectedPanel.visible = true
	
	var repair: = 0
	for propertyChange in propertyChanges:
		if propertyChange.doesRepair:
			match propertyChange.key:
				"dome.baserepair":
					repair += propertyChange.value
				"dome.healthfractionrepair":
					repair += propertyChange.value * Data.of("dome.maxhealth")
	Data.apply("dome.potentialrepair", repair)

func _on_Tech_focus_exited():
	$Tween.stop(self)
	rect_scale = Vector2.ONE
	$SelectedPanel.visible = false

func upgrade():
	$Tween.remove_all()
	Audio.sound("upgrade")
	$IconUnlock.texture = $Icon.texture
	$IconUnlock.rect_size = $Icon.rect_min_size
	$IconUnlock.rect_position = $Icon.rect_position
	$IconUnlock.show()
	$Tween.interpolate_property($IconUnlock, "modulate:a", 1.0, 0.0, 2.3, Tween.TRANS_EXPO, Tween.EASE_OUT)
	$Tween.interpolate_property($IconUnlock, "rect_scale", Vector2.ONE, Vector2.ONE * 3.5, 2.3, Tween.TRANS_EXPO, Tween.EASE_OUT)
	$Tween.start()
	
func error():
	Audio.sound("gui_err")
	if original_position == null:
		original_position = rect_position
	var start: Vector2 = rect_position + Vector2( - 8, 0)
	var end: Vector2 = original_position
	$Tween.interpolate_property(self, "rect_position", start, end, 0.5, Tween.TRANS_ELASTIC, Tween.EASE_OUT)
	$Tween.start()

func hasMultiplePredecessorLock()->bool:
	return $AnyAll.visible

func updateState():
	var tech = GameWorld.upgrades.get(techId)
	var isRepeatable = tech.has("repeatable")
	var any = tech.get("predecessorsany", false)
	var predecessorCount = tech.get("predecessors", []).size()
	hasMultiplePredecessors = false
	$AnyAll.hide()
	
	var cost = tech.get("cost", [])
	for costType in cost:
		if costLabels.has(costType):
			costLabels[costType].text = str(cost[costType])
	
	if state != State.INITIAL:
		state = State.UNAVAILABLE
		if GameWorld.lockedUpgrades.has(techId):
			state = State.LOCKED
		elif (GameWorld.boughtUpgrades.has(techId) and not isRepeatable) or Data.gadgets.has(techId):
			state = State.BOUGHT
		else:
			if GameWorld.upgrades.has(techId):
				var unlocked = false
				if tech.has("predecessors"):
					
					var count = 0
					for techId in tech.get("predecessors"):
						if GameWorld.boughtUpgrades.has(techId):
							count += 1
					
					if any and count > 0:
						unlocked = true
					elif count == predecessorCount:
						unlocked = true
					
					if not unlocked and predecessorCount > 1:
						$AnyAll.show()
						var missing = 1 if any else predecessorCount - count
						$AnyAll.find_node("LockCountLabel").text = str(missing)
						hasMultiplePredecessors = true
				
				if unlocked:
					state = State.AVAILABLE
				else:
					state = State.UNAVAILABLE
		if not has_focus():
			_on_Tech_focus_exited()
		
		match state:
			0:
				for c in find_node("Costs").get_children():
					if c is Label:
						c.set("custom_colors/font_color", Style.mapColor(colorUnavailable))
			1:
				for c in find_node("Costs").get_children():
					if c is Label:
						c.set("custom_colors/font_color", Style.mapColor(colorAvailable))
	
		var open = state == State.UNAVAILABLE or state == State.AVAILABLE
		find_node("Costs").visible = open
		match state:
			State.UNAVAILABLE:
				if GameWorld.upgrades[techId]["cost"].size() == 1:
					if isRepeatable:
						texture = preload("res://content/techtree/panels/one_reload_dark.png")
					else:
						texture = preload("res://content/techtree/panels/one_dark.png")
					
					if $AnyAll.visible:
						$AnyAll.texture = preload("res://content/techtree/panels/lock_dark.png")
					$SelectedPanel.texture = preload("res://content/techtree/panels/one_focus.png")
				else:
					if isRepeatable:
						texture = preload("res://content/techtree/panels/two_reload_dark.png")
					else:
						texture = preload("res://content/techtree/panels/two_dark.png")
					if $AnyAll.visible:
						$AnyAll.texture = preload("res://content/techtree/panels/lock_dark.png")
					$SelectedPanel.texture = preload("res://content/techtree/panels/two_focus.png")
			State.AVAILABLE:
				if GameWorld.upgrades[techId]["cost"].size() == 1:
					if isRepeatable:
						texture = preload("res://content/techtree/panels/one_reload_bright.png")
					else:
						texture = preload("res://content/techtree/panels/one_bright.png")
					if $AnyAll.visible:
						$AnyAll.texture = preload("res://content/techtree/panels/lock_bright.png")
					$SelectedPanel.texture = preload("res://content/techtree/panels/one_focus.png")
				else:
					if isRepeatable:
						texture = preload("res://content/techtree/panels/two_reload_bright.png")
					else:
						texture = preload("res://content/techtree/panels/two_bright.png")
					if $AnyAll.visible:
						$AnyAll.texture = preload("res://content/techtree/panels/lock_bright.png")
					$SelectedPanel.texture = preload("res://content/techtree/panels/two_focus.png")
			State.BOUGHT:
				texture = preload("res://content/techtree/panels/zero_bright.png")
				if $AnyAll.visible:
					$AnyAll.texture = preload("res://content/techtree/panels/lock_bright.png")
				$SelectedPanel.texture = preload("res://content/techtree/panels/zero_focus.png")
			State.LOCKED:
				texture = preload("res://content/techtree/panels/zero_dark.png")
				if $AnyAll.visible:
					$AnyAll.texture = preload("res://content/techtree/panels/lock_dark.png")
				$SelectedPanel.texture = preload("res://content/techtree/panels/zero_focus.png")
	
	rect_pivot_offset = texture.get_size() * 0.5
	
func isLocked()->bool:
	return state == State.LOCKED

func setAnalytics(count):
	$lockIcon.visible = false
	var costsBox = find_node("Costs")
	for c in costsBox.get_children():
		c.queue_free()
	
	var label = Label.new()
	label.align = Label.ALIGN_RIGHT
	label.size_flags_horizontal = label.SIZE_EXPAND_FILL
	label.text = str(count)
	label.add_to_group("unstyled")
	costsBox.add_child(label)

func _on_Tech_mouse_entered():
	
	InputSystem.grabFocus(self)
