extends CenterContainer

signal quit

func init():
	find_node("SuccessPopup").visible = false
	find_node("LoadingSpinner").visible = false
	find_node("ErrorLabel").visible = false
	find_node("PanelContainer").visible = true
	InputSystem.grabFocus(find_node("Content"))

func _on_SubmitButton_pressed():
	find_node("SubmitButton").visible = false
	find_node("LoadingSpinner").visible = true
	find_node("ErrorLabel").visible = false


















func _on_SubmitFeedback_request_completed(result, response_code, headers, body):
	find_node("SubmitButton").visible = true
	find_node("LoadingSpinner").visible = false
	
	if result != HTTPRequest.RESULT_SUCCESS or response_code != 200:
		find_node("ErrorLabel").text = "An error occurred (" + str(response_code) + "), the feedback could not be sent."
		find_node("ErrorLabel").visible = true
		return 

	find_node("PanelContainer").visible = false
	find_node("SuccessPopup").visible = true
	find_node("Content").text = ""

func _on_ButtonQuit_pressed():
	emit_signal("quit")

func _on_ButtonOkay_pressed()->void :
	emit_signal("quit")

func _on_CancelButton_pressed()->void :
	emit_signal("quit")
