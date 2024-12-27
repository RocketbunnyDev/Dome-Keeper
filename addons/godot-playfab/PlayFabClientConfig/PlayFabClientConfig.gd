extends Reference
class_name PlayFabClientConfig, "res://addons/godot-playfab/icon.png"


const TOKEN_TIMEOUT = 23 * 3600


var session_ticket: String setget _set_session_ticket


var master_player_account_id: String


var entity_token: EntityTokenResponse = EntityTokenResponse.new()


var login_type = LoginType.LOGIN_NONE




var login_id = ""


var login_timestamp = 0

enum LoginType{LOGIN_NONE, LOGIN_EMAIL, LOGIN_CUSTOM_ID}



func is_logged_in()->bool:
	if session_ticket.empty() or is_login_token_expired():
		return false

	return true



func is_login_token_expired()->bool:
	var elapsed_time = OS.get_unix_time() - login_timestamp

	if elapsed_time < 0 or elapsed_time > TOKEN_TIMEOUT:
		return true

	return false



func _set_session_ticket(value: String):
	login_timestamp = OS.get_unix_time()
	session_ticket = value
