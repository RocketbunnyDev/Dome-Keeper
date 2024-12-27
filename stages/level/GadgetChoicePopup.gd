extends Container

onready var GadgetContainer = find_node("Gadgets")


var isIn: = false
var animationDone: bool

var gadgets: Array
var currentGadgetIndex: = - 1
var selectedGadget

func _ready():
	visible = true
	rect_position.y += get_viewport_rect().size.y

func loadGadgets(gadgets: Array):
	currentGadgetIndex = 0
	
	for c in GadgetContainer.get_children():
		GadgetContainer.remove_child(c)
		c.queue_free()
	
	var amount: int
	if GameWorld.isUpgradeLimitAvailable("cobaltgeneration"):
		amount = 2
		gadgets.append({
			"id": "shredgadgettocobalt", 
			"dropType": CONST.SAND, 
			"amount": amount})
	else:
		amount = 8
		gadgets.append({
			"id": "shredgadgettoiron", 
			"dropType": CONST.IRON, 
			"amount": amount})
	self.gadgets = gadgets
	
	for g in gadgets:
		var id = g.get("id", "missing_id")
		var choice = preload("res://stages/level/GadgetChoice.tscn").instance()
		choice.find_node("TitleLabel").text = tr("upgrades." + id + ".title")
		var desc = tr("upgrades." + id + ".desc")
		if g.has("amount"):
			desc = desc.format({"amount": g.get("amount")})
		choice.find_node("DescriptionLabel").bbcode_text = desc
		var icon = choice.find_node("IconTextureRect")
		match id:
			"shredgadgettoiron":
				icon.texture = load("res://content/icons/icon_iron.png")
				icon.rect_min_size *= 0.5
				icon.rect_size *= 0.5
				icon.rect_position += icon.rect_size * 0.5
				icon.rect_position.y += icon.rect_size.y * 0.25
			"shredgadgettocobalt":
				icon.texture = load("res://content/icons/icon_sand.png")
				icon.rect_min_size *= 0.5
				icon.rect_size *= 0.5
				icon.rect_position += icon.rect_size * 0.5

			_:
				icon.texture = load("res://content/icons/" + id + ".png")
		GadgetContainer.add_child(choice)
		choice.connect("focus_entered", self, "optionFocussed", [g])
	
	InputSystem.grabFocus(GadgetContainer.get_children().front())
	
func optionFocussed(gadgetData: Dictionary):
	selectedGadget = gadgetData

func moveIn():
	if isIn:
		return 
	
	isIn = true
	animationDone = false
	$Tween.stop_all()
	$Tween.remove_all()
	$Tween.interpolate_property(self, "rect_position:y", rect_position.y, 0, 0.6, Tween.TRANS_CUBIC, Tween.EASE_OUT)
	$Tween.interpolate_callback(self, 0.7, "set", "animationDone", true)
	$Tween.start()
	
func moveOut():
	if not isIn:
		return 
	
	for c in GadgetContainer.get_children():
		if c.has_focus():
			c.release_focus()
	
	isIn = false
	$Tween.stop_all()
	$Tween.remove_all()
	$Tween.interpolate_property(self, "rect_position:y", rect_position.y, get_viewport_rect().size.y, 0.3, Tween.TRANS_CUBIC, Tween.EASE_IN)
	$Tween.start()
