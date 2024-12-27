extends InputProcessor

signal captured

var inputLabel
var buttonName: String
var bindingEntry

var capturedEvent: InputEvent

func handleStart():
	inputLabel.text = tr("options.keybindings.rebinding.inputprocessor")
	
func handle(event)->bool:
	if capturedEvent:
		return false
	
	if not capturedEvent:
		handleStart()
	
	if event is InputEventKey and event.pressed:
		inputLabel.text = OS.get_scancode_string(event.scancode)
		capturedEvent = event
		emit_signal("captured")
	elif event is InputEventJoypadMotion and event.axis_value > 0.1:
		inputLabel.text = Options.getGamepadTranslations("axis" + str(event.axis))
		capturedEvent = event
		emit_signal("captured")
	elif event is InputEventJoypadButton and event.pressed:
		inputLabel.text = Options.getGamepadTranslations(event.button_index)
		capturedEvent = event
		emit_signal("captured")
	return true

func apply():
	if not capturedEvent or not bindingEntry:
		return 
	
	bindingEntry.apply(buttonName, capturedEvent)

func startCapture():
	capturedEvent = null
	
