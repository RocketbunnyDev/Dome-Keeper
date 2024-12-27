extends Area2D

export (NodePath) var modulateOnFocus
export (NodePath) var visibleOnFocus
var inFocusArea: = []
var focussed: = false
var modulationNode: Node
var visibilityNode: Node













func _ready():
	if visibleOnFocus:
		visibilityNode = get_node(visibleOnFocus)
		visibilityNode.visible = false
		visibilityNode.material = preload("res://content/shared/HighlightShader.material")
	elif modulateOnFocus:
		modulationNode = get_node(modulateOnFocus)
	else:
		modulationNode = get_parent()
	
	get_parent().add_to_group("usables")
	get_parent().set_meta("usable", self)
	
func focusUse(keeper: Keeper):
	inFocusArea.append(keeper)
	updateFocus()

func updateFocus():
	if canFocusUse() and inFocusArea.size() > 0:
		if visibilityNode:
			visibilityNode.visible = true
		else:
			modulationNode.modulate = Style.FOCUS_MODULATE
		focussed = true
	else:
		if visibilityNode:
			visibilityNode.visible = false
		else:
			modulationNode.modulate = Color.white
		focussed = false

func unfocusUse(keeper: Keeper):
	inFocusArea.erase(keeper)
	updateFocus()

func canFocusUse()->bool:
	return get_parent().canFocusUse()

func canPickup()->bool:
	return visibleOnFocus != null and canFocusUse()

func useHold(keeper: Keeper)->bool:
	if focussed:
		var handled = get_parent().useHold(keeper)
		if handled:
			updateFocus()
		return handled
	else:
		return false

func useHit(keeper: Keeper)->bool:
	if focussed:
		var handled = get_parent().useHit(keeper)
		if handled:
			updateFocus()
		return handled
	else:
		return false
