extends "res://content/gadgets/CellarGadget.gd"

enum State{IDLE, PROCESSING, OPENING, READY}
var state: int = State.IDLE

var processingCountdown: = 0.0
var producedResource: String
var producedAmount: int

func _ready():
	$Sprite.play("idle")
	$Overlay.visible = false
	$ResourcePosition / Resource.visible = false
	
	Style.init(self)
	
	Achievements.addIfOpen(self, "CONVERTER_USE")

func serialize()->Dictionary:
	var data = .serialize()
	data["state"] = state
	data["processingCountdown"] = processingCountdown
	data["producedResource"] = producedResource
	data["producedAmount"] = producedAmount
	return data
	
func deserialize(data: Dictionary):
	.deserialize(data)
	state = int(data["state"])
	processingCountdown = data["processingCountdown"]
	producedResource = data["producedResource"]
	producedAmount = data["producedAmount"]

	if state == State.IDLE:
		$ResourcePosition / Resource.visible = false
		$Sprite.play("idle")
		$Overlay.visible = false

	if state == State.PROCESSING:
		$Sprite.play("active")
	
	if state == State.OPENING:
		$Sprite.play("release")
		
	if state == State.READY:
		$Sprite.play("ready")
		$Overlay.visible = true
		$ResourcePosition / Resource.texture = Data.DROP_ICONS.get(producedResource)
		$ResourcePosition / Resource.visible = true
		
func _process(delta):
	if GameWorld.softPaused():
		return 
	
	match int(state):
		State.IDLE:
			pass
		State.PROCESSING:
			if processingCountdown > 0.0:
				processingCountdown -= delta
			else:
				$Sprite.play("release")
				$FinishedSound.play()
				state = State.OPENING
		State.OPENING:
			pass
		State.READY:
			pass

func canFocusUse()->bool:
	return state == State.IDLE or state == State.READY

func useHold(keeper: Keeper):
	useHit(keeper)

func useHit(keeper: Keeper)->bool:
	if state == State.READY:
		for _i in producedAmount:
			var res = Data.DROP_SCENES.get(producedResource).instance()
			res.position = $ResourcePosition.global_position
			Level.map.addDrop(res)
			keeper.attachCarry(res)
		$ResourcePosition / Resource.visible = false
		$Sprite.play("idle")
		$Overlay.visible = false
		state = State.IDLE
		Backend.event("gadget_used", {"gadget": "converter"})
	elif state == State.IDLE:
		var i = preload("res://content/gadgets/converter/ConverterInputProcessor.gd").new()
		var popup = preload("res://content/gadgets/converter/ConverterPopup.tscn").instance()
		$Canvas.add_child(popup)
		popup.moveIn()
		i.popup = popup
		i.connect("onStop", Level.stage, "unpause")
		i.connect("onStop", popup, "moveOut")
		i.connect("conversion_selected", self, "conversionSelected")
		i.integrate(self)
		Level.stage.pause()
	return false

func conversionSelected(conversion: Control):
	Data.changeByInt("inventory." + conversion.from, - conversion.resourcesIn)
	processingCountdown = conversion.time * GameWorld.getTimeBetweenWaves()
	producedResource = conversion.to
	producedAmount = conversion.resourcesOut
	$Sprite.play("active")
	state = State.PROCESSING
	$ActiveAmb.play()
	$StartSound.play()
	Backend.event("converter", {"from": conversion.from, "in": conversion.resourcesIn, "to": conversion.to, "out": conversion.resourcesOut})

func _on_Sprite_animation_finished():
	if $Sprite.animation == "release":
		$Sprite.play("ready")
		$Overlay.visible = true
		state = State.READY
		$ResourcePosition / Resource.texture = Data.DROP_ICONS.get(producedResource)
		$ResourcePosition / Resource.visible = true
		$ActiveAmb.stop()
