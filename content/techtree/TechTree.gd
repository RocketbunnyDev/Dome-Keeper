extends Control

signal techFocussed(techPanel)

var trackIds: = []

var focussedTechPanel

func _process(delta: float)->void :
	var dirty: = false
	for track in $Tracks.get_children():
		dirty = dirty or track.dirty
		track.dirty = false
	if dirty:
		_on_Tracks_sort_children2()
		
func build():
	trackIds.clear()
	
	var upgrades = Data.orderedUpgradeKeys.duplicate()
	for u in Data.orderedUpgradeKeys:
		if not GameWorld.upgrades.has(u):
			continue
		
		if GameWorld.upgrades[u]["tier"] == 0 and u in GameWorld.boughtUpgrades:
			trackIds.append([[u]])
			upgrades.erase(u)
	
	
	for track in trackIds:
		var removed: = 1
		var currentTier: = 1
		while removed > 0:
			removed = 0
			var newTechs: = []
			for u in upgrades:
				if not GameWorld.upgrades.has(u):
					continue
				if GameWorld.lockedUpgrades.has(u):
					continue
				
				var upgrade = GameWorld.upgrades[u]
				
				if GameWorld.isUpgradeLimited(upgrade):
					continue
				
				if upgrade["tier"] != track.size():
					continue
				
				var predecessors: Array = upgrade.get("predecessors")
				var missingPredecessorCount: = 1 if upgrade.get("predecessorsany", false) else predecessors.size()
				for predecessor in predecessors:
					if track[currentTier - 1].has(predecessor):
						missingPredecessorCount -= 1
				if missingPredecessorCount <= 0:
					newTechs.append(u)
			
			if newTechs.size() > 0:
				track.append(newTechs)
			for u in newTechs:
				upgrades.erase(u)
				removed += 1
			currentTier += 1
	
	focussedTechPanel = null
	for t in trackIds:
		var track = preload("res://content/techtree/TechTrack.tscn").instance()
		track.build(t, self)
		$Tracks.add_child(track)


func focus():
	if not focussedTechPanel:
		focussedTechPanel = $Tracks.get_children().front().panelsByTier.front().front()
	InputSystem.grabFocus(focussedTechPanel)

func showExplanation(techPanel, explanationBb):
	find_node("ExplanationLabel").bbcode_text = tr(explanationBb)
	find_node("Explanation").rect_global_position.x = techPanel.rect_global_position.x
	find_node("Explanation").rect_global_position.y = techPanel.rect_global_position.y + techPanel.rect_size.y
	find_node("Explanation").rect_size.x = techPanel.rect_size.x
	find_node("Explanation").rect_size.y = 1

func _on_Tracks_sort_children2():
	for track in $Tracks.get_children():
		track.updateLines()
	
	var tracks: Array = $Tracks.get_children()
	for i in range(0, tracks.size()):
		var track = tracks[i]
		
		
		for tier in track.panelsByTier:
			for j in range(1, tier.size()):
				tier[j].focus_neighbour_top = tier[j - 1].get_path()
				tier[j - 1].focus_neighbour_bottom = tier[j].get_path()
		
		if i > 0:
			
			var bottomSize = tracks[i - 1].bottomTechPanelsByTier.size() - 1
			for j in range(0, track.topTechPanelsByTier.size()):
				track.topTechPanelsByTier[j].focus_neighbour_top = tracks[i - 1].bottomTechPanelsByTier[min(j, bottomSize)].get_path()
		else:
			
			for j in range(0, track.topTechPanelsByTier.size()):
				track.topTechPanelsByTier[j].focus_neighbour_top = track.topTechPanelsByTier[j].get_path()
		
		if i < tracks.size() - 1:
			
			var topSize = tracks[i + 1].topTechPanelsByTier.size() - 1
			for j in range(0, track.bottomTechPanelsByTier.size()):
				track.bottomTechPanelsByTier[j].focus_neighbour_bottom = tracks[i + 1].topTechPanelsByTier[min(j, topSize)].get_path()
		else:
			
			for j in range(0, track.bottomTechPanelsByTier.size()):
				track.bottomTechPanelsByTier[j].focus_neighbour_bottom = track.bottomTechPanelsByTier[j].get_path()
		
		for techPanel in track.rightTechPanels:
			techPanel.focus_neighbour_right = techPanel.get_path()

var tempLeftNeighborOverrides: = {}
var tempRightNeighborOverrides: = {}
func techFocussed(techPanel):
	if focussedTechPanel and focussedTechPanel.track == techPanel.track:
		
		
		if techPanel.rect_global_position.x < focussedTechPanel.rect_global_position.x:
			if not tempRightNeighborOverrides.has(techPanel):
				tempRightNeighborOverrides[techPanel] = techPanel.focus_neighbour_right
			techPanel.focus_neighbour_right = focussedTechPanel.get_path()
		elif tempRightNeighborOverrides.has(techPanel):
			techPanel.focus_neighbour_right = tempRightNeighborOverrides[techPanel]
			tempRightNeighborOverrides.erase(techPanel)
		
		
		
		if techPanel.rect_global_position.x > focussedTechPanel.rect_global_position.x:
			if GameWorld.upgrades.get(techPanel.techId, {}).get("predecessors", []).has(focussedTechPanel.techId):
				if not tempLeftNeighborOverrides.has(techPanel):
					tempLeftNeighborOverrides[techPanel] = techPanel.focus_neighbour_left
				techPanel.focus_neighbour_left = focussedTechPanel.get_path()
		elif tempLeftNeighborOverrides.has(techPanel):
			techPanel.focus_neighbour_left = tempLeftNeighborOverrides[techPanel]
			tempLeftNeighborOverrides.erase(techPanel)
	
	focussedTechPanel = techPanel
	focussedTechPanel.focusCounter = 0
	var scrollX = techPanel.rect_global_position.x + get_parent().scroll_horizontal - get_parent().rect_global_position.x - get_parent().rect_size.x * 0.5 + techPanel.rect_size.x * 0.5
	var scrollY = techPanel.track.rect_global_position.y - get_parent().rect_size.y * 0.5 + techPanel.track.rect_size.y * 0.5 + get_parent().scroll_vertical - get_parent().rect_global_position.y
	if abs(get_parent().scroll_horizontal - scrollX) > 30:
		$Tween.interpolate_property(get_parent(), "scroll_horizontal", get_parent().scroll_horizontal, scrollX, 0.2, Tween.TRANS_QUAD, Tween.EASE_IN_OUT)
	if abs(get_parent().scroll_vertical - scrollY) > 30:
		$Tween.interpolate_property(get_parent(), "scroll_vertical", get_parent().scroll_vertical, scrollY, 0.2, Tween.TRANS_QUAD, Tween.EASE_IN_OUT)
	$Tween.start()
	emit_signal("techFocussed", techPanel)

func techUnfocussed(techPanel):
	pass




func techInput(event, techPanel):
	if event is InputEventMouseButton and event.pressed and event.button_index == BUTTON_LEFT:
		if techPanel == focussedTechPanel:
			techPanel.focusCounter += 1
			if techPanel.focusCounter > 1:
				buyCurrentUpgrade()


		pass

func buyCurrentUpgrade():
	if focussedTechPanel:
		var tech = GameWorld.upgrades.get(focussedTechPanel.techId)
		var bought: = false
		if focussedTechPanel.state == 1:
			var enoughResources: = true
			var cost = tech.get("cost", {})
			for costType in cost:
				if Data.of("inventory." + costType) < cost[costType]:
					enoughResources = false
					break
			if enoughResources:
				bought = true
				GameWorld.buyUpgrade(focussedTechPanel.techId)
				focussedTechPanel.upgrade()
				focussedTechPanel.track.updateState()
				emit_signal("techFocussed", focussedTechPanel)
				focussedTechPanel.track.updateLineColors()
				focussedTechPanel.track.updateLines()
		if not bought:
			focussedTechPanel.error()
	
func _on_Tracks_resized()->void :
	pass
