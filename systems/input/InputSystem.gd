extends Node

var processorsToAdd = []
var processorsToRemove = []

var doInputLogging: = true

func _ready():
	Input.connect("joy_connection_changed", self, "_on_joy_connection_changed")

func _on_joy_connection_changed(device_id, connected):
	if not connected and Options.useGamepad:
		Options.setUseGamepad(false)

func pr(s: String):
	if doInputLogging:
		print(s)

func addProcessor(processor: InputProcessor):
	pr("add input: " + processor.name + " - " + processor.get_parent().name)
	processorsToAdd.append(processor)

func removeProcessor(processor: InputProcessor):
	pr("stop input: " + processor.name + " - " + processor.get_parent().name)
	processorsToRemove.append(processor)

func clearProcessors():
	var currentNode = getLastChild()
	while currentNode != $RootProcessor:
		processorsToRemove.append(currentNode)
		currentNode = currentNode.parent

func _process(delta):
	for p in processorsToRemove.duplicate():
		if not is_instance_valid(p) or not p.parent:
			processorsToRemove.erase(p)
	
	for processor in processorsToRemove:
		if processor.canStop():
			var index = processorsToAdd.find(processor)
			if index != - 1:
				processorsToAdd.remove(index)
			
			processor.parent.child = null
			var c = processor.child
			var lastParent = processor.parent
			while c != null and processor.attachedChildren:
				if c.doTransitiveStop:
					pr("transitive stop input: " + c.name + " - " + c.get_parent().name)
					deleteInputProcessor(c)
					var childIndex = processorsToRemove.find(c)
					if childIndex != - 1:
						processorsToRemove.remove(childIndex)
					c = c.child
				else:
					c.parent = lastParent
					lastParent.child = c
					c = c.child
			deleteInputProcessor(processor)
		printout()
	if processorsToRemove.size() > 0 and processorsToAdd.size() == 0:
		getLastChild().becameLeaf()
	processorsToRemove.clear()
	
	for processor in processorsToAdd:
		if processor.stopNamed != "":
			var split = processor.stopNamed.split(",")
			for splitName in split:
				var last = getLastChild()
				if splitName == last.name or "@" + splitName in last.name:
					last.desintegrate()
					return 
		if processor.desiredParent != "":
			var last = getLastChild()
			if not (last.name == processor.desiredParent or "@" + processor.desiredParent in last.name):
				last.desintegrate()
				return 
				
		var lastChild: = getLastChild()
		processor.parent = lastChild
		lastChild.child = processor
		lastChild.notLeaf()
		processor.emit_signal("onStart")
		processor.handleStart()
		processor.becameLeaf()
		
		printout()
	processorsToAdd.clear()

func printout():
	if doInputLogging:
		var prefix = "- "
		var currentNode: InputProcessor = get_child(0)
		print("--- input state ---")
		while currentNode.child != null:
			currentNode = currentNode.child
			print(prefix + currentNode.name + " - " + currentNode.get_parent().name)
			prefix = prefix + "   "
		print("-------------------")

func _unhandled_input(event):
	var currentNode: = getLastChild()
	var handled = false
	while not handled:
		handled = currentNode.handle(event)
		
		if not handled:
			if currentNode.parent != null:
				currentNode = currentNode.parent
			else:
				handled = true

func getLastChild()->InputProcessor:
	var currentNode: InputProcessor = get_child(0)
	while currentNode.child and is_instance_valid(currentNode.child) and currentNode.child.is_inside_tree():
		currentNode = currentNode.child
	return currentNode

func deleteInputProcessor(processor):
	processor.emit_signal("onStop")
	processor.handleStop()
	var parent = processor.get_parent()
	if parent is Stage:
		var i = parent.inputs.find(processor)
		parent.inputs.remove(i)
	
	if not processor.attachedChildren and processor.child:
		processor.child.parent = processor.parent
		processor.parent.child = processor.child
	
	if parent:
		parent.remove_child(processor)
	processor.queue_free()

func getCamera()->Camera2D:
	for cam in get_tree().get_nodes_in_group("cameras"):
		if cam.is_current():
			return cam
	return null

func getViewCamera(node)->Camera2D:
	for cam in get_tree().get_nodes_in_group("cameras"):
		if cam.is_current() and cam.get_viewport() == node.get_viewport():
			return cam
	return null

func cameraScreenToWorld(v: Vector2):
	var c = getCamera()
	var factor = c.zoom * (get_viewport().get_visible_rect().size / get_viewport().size)
	v = v * factor + c.position - get_viewport().size * factor * 0.5
	return v

func viewCameraScreenToWorld(node, v: Vector2):
	var c = getViewCamera(node)
	v = v * c.zoom + c.position - get_viewport().get_visible_rect().size * c.zoom * 0.5
	return v

func cameraWorldToScreen(v: Vector2):
	var c = getCamera()
	v = (v - c.position) / c.zoom + get_viewport().get_visible_rect().size * 0.5
	return v

func cleanString(string: String)->String:
	var regex = RegEx.new()
	regex.compile("[\\p{L} ]*")
	var t = ""
	var matches = regex.search_all(string)
	for m in matches:
		for s in m.strings:
			t += s
	return t

func updateLinEdit(edit, new_text):
	var t = cleanString(new_text)
	var cp = edit.caret_position - (edit.text.length() - t.length())
	edit.text = t
	edit.caret_position = clamp(cp, 0, t.length())

func grabFocusIfNone(uiElement):
	if uiElement.get_focus_owner() == null:
		grabFocus(uiElement)
	
func grabFocus(uiElement):
	Audio.ignoreNextHover()
	uiElement.grab_focus()

func getInputDirection()->Vector2:
	var left = Input.get_action_raw_strength("ui_left")
	var right = Input.get_action_raw_strength("ui_right")
	var up = Input.get_action_raw_strength("ui_up")
	var down = Input.get_action_raw_strength("ui_down")
	left = max(0.0, left - Options.gamepadStickDeadZone)
	right = max(0.0, right - Options.gamepadStickDeadZone)
	up = max(0.0, up - Options.gamepadStickDeadZone)
	down = max(0.0, down - Options.gamepadStickDeadZone)
	var hor = right - left
	var ver = down - up
	if Options.gamepadStickDeadZone > 0.0:
		hor *= (1.0 / (1.0 - Options.gamepadStickDeadZone))
		ver *= (1.0 / (1.0 - Options.gamepadStickDeadZone))
	var movedir = Vector2(hor, ver)
	
	if movedir.length() > 1.0:
		movedir = movedir.normalized()
	return movedir
