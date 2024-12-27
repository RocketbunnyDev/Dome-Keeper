extends CenterContainer

signal quit

func init():
	find_node("SuccessPopup").visible = false
	find_node("LoadingSpinner").visible = false
	find_node("ErrorLabel").visible = false
	find_node("PanelContainer").visible = true

func _on_SubmitButton_pressed():
	Backend.trackRequest("SubmitBugReport")
	
	find_node("SubmitButton").visible = false
	find_node("LoadingSpinner").visible = true
	find_node("ErrorLabel").visible = false
	var data = {}
	data["description"] = find_node("Content1").text
	data["context"] = find_node("Content2").text
	data["playerId"] = GameWorld.playerId
	data["sceneContext"] = StageManager.getContext()
	
	var headers = ["Content-Type: text/plain"]
	var body = Marshalls.utf8_to_base64(JSON.print(data))











func _on_ButtonQuit_pressed():
	emit_signal("quit")

func _on_SubmitBugReport_request_completed(result, response_code, headers, body):
	Backend.trackResponse("SubmitBugReport", result, response_code)
	find_node("SubmitButton").visible = true
	find_node("LoadingSpinner").visible = false
	
	if result != HTTPRequest.RESULT_SUCCESS or response_code != 200:

		find_node("ErrorLabel").text = "An error occurred (" + str(response_code) + "), the bug report could not be sent."
		find_node("ErrorLabel").visible = true
		return 

	find_node("PanelContainer").visible = false
	find_node("SuccessPopup").visible = true
	find_node("Content1").text = ""
	find_node("Content2").text = ""
