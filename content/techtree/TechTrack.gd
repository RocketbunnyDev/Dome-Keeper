extends Control

var techs: = {}
var lockGroupBoxes: = {}

var techPanels: = {}
var topTechPanelsByTier: = []
var bottomTechPanelsByTier: = []
var rightTechPanels: = []
var panelsByTier: = []
var edges: = []

var invisId: = 0
var lockGroupsByTier: = []
var prevTier: Array

var dirty: = false

const vIn = Vector2( - 30, 0)
const vOut = Vector2(30, 0)
var linesByTech: = []
var curve: = Curve2D.new()

func build(techsByTier: Array, focusListener):
	
	var tierN: = 0
	for tier in techsByTier:
		for techId in tier:
			var tierData: = {"id": techId, "tier": tierN}
			var tech = GameWorld.upgrades.get(techId)
			if tech.has("locks"):
				tierData["locks"] = tech.get("locks")
			if tech.has("requires"):
				tierData["requires"] = tech.get("requires")
			if tech.has("predecessors"):
				tierData["predecessors"] = tech.get("predecessors")
			techs[techId] = tierData
		tierN += 1
	
	
	for tier in techsByTier:
		var remainingTechs = tier.duplicate()
		
		var lockGroups: = []
		while remainingTechs.size() > 0:
			var techId = remainingTechs.pop_front()
			var tech = techs[techId]
			if tech.has("locks"):
				var lockGroup: = []
				for l in tech.get("locks"):
					if tier.has(l):
						lockGroup.append(l)
						remainingTechs.erase(l)
						techs[l]["lockGroup"] = lockGroup
				if lockGroup.size() > 0:
					lockGroup.append(techId)
					lockGroups.append(lockGroup)
					techs[techId]["lockGroup"] = lockGroup
		
		lockGroupsByTier.append(lockGroups)
	
	
	var i: = 0
	for tier in techsByTier:
		tier.sort_custom(self, "sortByPredecessorIndex")
		var box: = VBoxContainer.new()
		box.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if i == 0:
			box.alignment = BoxContainer.ALIGN_CENTER
		else:
			box.alignment = BoxContainer.ALIGN_BEGIN
		i += 1
		box.set("custom_constants/separation", 20)
		var panelsOfTier: = []
		for techId in tier:
			var tech = techs[techId]
			var boxToUse
			if tech.has("lockGroup"):
				var lockGroupId = tech.get("lockGroup").front()
				if lockGroupBoxes.has(lockGroupId):
					boxToUse = lockGroupBoxes.get(lockGroupId)
				else:
					var lockBox: = PanelContainer.new()
					lockBox.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
					lockBox.mouse_filter = Control.MOUSE_FILTER_IGNORE
					boxToUse = VBoxContainer.new()
					boxToUse.mouse_filter = Control.MOUSE_FILTER_IGNORE
					boxToUse.alignment = BoxContainer.ALIGN_CENTER
					boxToUse.set("custom_constants/separation", 20)
					lockBox.set("custom_styles/panel", preload("res://content/techtree/panels/panel_lockgroup_open.tres"))
					lockGroupBoxes[lockGroupId] = boxToUse
					lockBox.add_child(boxToUse)
					box.add_child(lockBox)
			else:
				boxToUse = box
			
			var panel = preload("res://content/techtree/Tech2.tscn").instance()
			panel.build(techId, i)
			panel.track = self
			techPanels[techId] = panel
			panelsOfTier.append(panel)
			boxToUse.add_child(panel)
			panel.connect("focus_entered", focusListener, "techFocussed", [panel])
			panel.connect("focus_entered", self, "techFocussed", [panel])
			panel.connect("focus_exited", focusListener, "techUnfocussed", [panel])
			panel.connect("gui_input", focusListener, "techInput", [panel])
			panel.connect("resized", self, "set", ["dirty", true])
				
		find_node("Tiers").add_child(box)
		topTechPanelsByTier.append(panelsOfTier.front())
		bottomTechPanelsByTier.append(panelsOfTier.back())
		panelsByTier.append(panelsOfTier)
		rightTechPanels = panelsOfTier
		prevTier = tier
	
	
	var lastTier: = []
	for tier in techsByTier:
		for techId in tier:
			if techs[techId].has("predecessors"):
				var predecessors = techs[techId].get("predecessors")
				for r in predecessors:
					if lastTier.has(r):
						
						edges.append([r, techId])
		lastTier = tier

func techFocussed(panel):
	for c in get_tree().get_nodes_in_group("techpanel"):
		if c.state != 3:
			c.hideLockGroup()
		
	if not techs[panel.techId].has("lockGroup"):
		return 
		
	var lockGroupId = techs[panel.techId].get("lockGroup").front()
	var box = lockGroupBoxes[lockGroupId]
	var groupLocked: = false
	for tech in box.get_children():
		if GameWorld.boughtUpgrades.has(tech.techId):
			groupLocked = true
	for tech in box.get_children():
		if tech.state == 2:
			tech.hideLockGroup()
		elif not groupLocked and (tech.state == 2 or panel != tech):
			tech.showLockGroup()

func sortByPredecessorIndex(a, b):
	if not prevTier:
		return false

	var up1 = techs[a]
	var up2 = techs[b]
	
	if up1.has("predecessors") and up2.has("predecessors"):
		var r1 = up1.get("predecessors")
		var p1 = 999
		for pred in r1:
			var index = prevTier.find(pred)
			if index >= 0:
				p1 = min(p1, index)
		var r2 = up2.get("predecessors")
		var p2 = 999
		for pred in r2:
			var index = prevTier.find(pred)
			if index >= 0:
				p2 = min(p2, index)
		return p1 < p2
	return false

func updateState():
	for techPanelId in techPanels:
		var techPanel = techPanels[techPanelId]
		techPanel.updateState()
		if techPanel.isLocked():
			var tech = techs[techPanelId]
			if tech.has("lockGroup"):
				var lockGroupId = tech.get("lockGroup").front()
				if lockGroupBoxes.has(lockGroupId):
					var box = lockGroupBoxes.get(lockGroupId)
					box.get_parent().set("custom_styles/panel", preload("res://content/techtree/panels/panel_lockgroup_closed.tres"))

func updateLines():
	for c in $Lines.get_children():
		$Lines.remove_child(c)
		c.queue_free()
	linesByTech.clear()
	
	var line_width = 8
	
	var Lines = find_node("Lines")
	for edge in edges:
		curve.clear_points()
		
		if not edge[0]:
			continue
		
		
		
		
		
		var t1 = techPanels[edge[0]]
		var t2 = techPanels[edge[1]]
		var t1BaseSize = t1.rect_size
		var t2BaseSize = t2.rect_size
		var t2OffsetX = - 40 if t2.hasMultiplePredecessorLock() else - 15
		var t1BasePos = t1.rect_global_position + (t1.rect_size * t1.rect_scale - t1.rect_size) * 0.5
		var t2BasePos = t2.rect_global_position + (t2.rect_size * t2.rect_scale - t2.rect_size) * 0.5
		var p1 = t1BasePos + Vector2(t1BaseSize.x - 20, t1BaseSize.y * 0.5 - line_width) - rect_global_position
		var p2 = t2BasePos + Vector2(t2OffsetX, t2BaseSize.y * 0.5 - line_width) - rect_global_position
		if t2.focus_neighbour_left == "":
			t2.focus_neighbour_left = t1.get_path()
		if t1.focus_neighbour_right == "":
			t1.focus_neighbour_right = t2.get_path()
		else:
			
			var currentNeighbor = get_tree().root.get_node(t1.focus_neighbour_right)
			if abs(t1.rect_global_position.y - t2.rect_global_position.y) < abs(t1.rect_global_position.y - currentNeighbor.rect_global_position.y):
				t1.focus_neighbour_right = t2.get_path()
			
		curve.add_point(p1, vIn, vOut)
		curve.add_point(p2, vIn, vOut)
		
		var l: = Line2D.new()
		l.z_index = 0
		l.texture_mode = Line2D.LINE_TEXTURE_TILE
		l.end_cap_mode = Line2D.LINE_CAP_ROUND
		l.begin_cap_mode = Line2D.LINE_CAP_ROUND
		l.antialiased = true
		l.width = line_width
		l.material = preload("res://content/techtree/common/marching-ants-material.tres")
		for point in curve.get_baked_points():
			l.add_point(point)
		Lines.add_child(l)
		linesByTech.append([edge[0], edge[1], l])
	
	Style.init(Lines)
	updateLineColors()

func updateLineColors():
	for line in linesByTech:
		if GameWorld.lockedUpgrades.has(line[0]) or GameWorld.lockedUpgrades.has(line[1]):
			line[2].texture = preload("res://content/techtree/common/line-locked.png")
		elif GameWorld.boughtUpgrades.has(line[0]):
			if GameWorld.boughtUpgrades.has(line[1]):
				line[2].texture = preload("res://content/techtree/common/line-bought.png")
			else:
				line[2].texture = preload("res://content/techtree/common/line-available.png")
		else:
			line[2].texture = preload("res://content/techtree/common/line-unavailable.png")

func _on_TechTrack_sort_children():
	dirty = true
