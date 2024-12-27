extends PlayFabHttp
class_name PlayFab, "res://addons/godot-playfab/icon.png"


signal registered(RegisterPlayFabUserResult)



signal logged_in(login_result)

enum AUTH_TYPE{SESSION_TICKET, ENTITY_TOKEN}


func _init():

	if ProjectSettings.has_setting(PlayFabConstants.SETTING_PLAYFAB_TITLE_ID) and ProjectSettings.get_setting(PlayFabConstants.SETTING_PLAYFAB_TITLE_ID) != "":
		_title_id = ProjectSettings.get_setting(PlayFabConstants.SETTING_PLAYFAB_TITLE_ID)
	else:
		push_error("Title Id was not set in ProjectSettings: %s" % PlayFabConstants.SETTING_PLAYFAB_TITLE_ID)


func _ready():
	connect("logged_in", self, "_on_logged_in")


func _on_logged_in(login_result: LoginResult):
	
	PlayFabManager.client_config.session_ticket = login_result.SessionTicket
	PlayFabManager.client_config.master_player_account_id = login_result.PlayFabId
	PlayFabManager.client_config.entity_token = login_result.EntityToken
	PlayFabManager.save_client_config()


func register_email_password(username: String, email: String, password: String, info_request_parameters: GetPlayerCombinedInfoRequestParams):
	var request_params = RegisterPlayFabUserRequest.new()
	request_params.TitleId = _title_id
	request_params.DisplayName = username
	request_params.Username = username
	request_params.Email = email
	request_params.Password = password
	request_params.InfoRequestParameters = info_request_parameters
	request_params.RequireBothUsernameAndEmail = true

	var result = _post(request_params, "/Client/RegisterPlayFabUser", funcref(self, "_on_register_email_password"))


func login_with_email(email: String, password: String, custom_tags: Dictionary, info_request_parameters: GetPlayerCombinedInfoRequestParams):
	PlayFabManager.client_config.login_type = PlayFabClientConfig.LoginType.LOGIN_EMAIL
	PlayFabManager.client_config.login_id = email

	var request_params = LoginWithEmailAddressRequest.new()
	request_params.TitleId = _title_id
	request_params.Email = email
	request_params.Password = password
	request_params.CustomTags = custom_tags
	request_params.InfoRequestParameters = info_request_parameters

	var result = _post(request_params, "/Client/LoginWithEmailAddress", funcref(self, "_on_login_with_email"))


func login_with_custom_id(custom_id: String, create_user: bool, info_request_parameters: GetPlayerCombinedInfoRequestParams):
	PlayFabManager.client_config.login_type = PlayFabClientConfig.LoginType.LOGIN_CUSTOM_ID
	PlayFabManager.client_config.login_id = custom_id

	var request_params = LoginWithCustomIdRequest.new()
	request_params.TitleId = _title_id
	request_params.CustomId = custom_id
	request_params.CreateAccount = create_user
	request_params.InfoRequestParameters = info_request_parameters

	var result = _post(request_params, "/Client/LoginWithCustomID", funcref(self, "_on_login_with_email"))


func _on_register_email_password(result: Dictionary):
	var register_result = RegisterPlayFabUserResult.new()
	register_result.from_dict(result["data"], register_result)

	emit_signal("registered", register_result)


func _on_login_with_email(result: Dictionary):
	var login_result = LoginResult.new()
	login_result.from_dict(result["data"], login_result)

	emit_signal("logged_in", login_result)


func _post_with_session_auth(body: JsonSerializable, path: String, callback: FuncRef, additional_headers: Dictionary = {})->bool:
	var result = _add_auth_headers(additional_headers, AUTH_TYPE.SESSION_TICKET)
	if not result:
		return false

	var dict = body.to_dict()
	_http_request(HTTPClient.METHOD_POST, dict, path, callback, additional_headers)
	return true










func _post_with_entity_auth(body: JsonSerializable, path: String, callback: FuncRef, additional_headers: Dictionary = {})->bool:
	var result = _add_auth_headers(additional_headers, AUTH_TYPE.ENTITY_TOKEN)
	if not result:
		return false

	var dict = body.to_dict()
	_http_request(HTTPClient.METHOD_POST, dict, path, callback, additional_headers)
	return true


func _post(body: JsonSerializable, path: String, callback: FuncRef, additional_headers: Dictionary = {}):
	var dict = body.to_dict()
	_http_request(HTTPClient.METHOD_POST, dict, path, callback, additional_headers)











func post_dict_auth(body: Dictionary, path: String, auth_type, callback: FuncRef, additional_headers: Dictionary = {}):
	_add_auth_headers(additional_headers, auth_type)
	_http_request(HTTPClient.METHOD_POST, body, path, callback, additional_headers)











func post_dict(body: Dictionary, path: String, callback: FuncRef, additional_headers: Dictionary = {}):
	_http_request(HTTPClient.METHOD_POST, body, path, callback, additional_headers)








func _add_auth_headers(additional_headers: Dictionary, auth_type)->bool:
	if not PlayFabManager.client_config.is_logged_in():
		push_error("Player is not logged in.")
		return false

	if auth_type == AUTH_TYPE.SESSION_TICKET:
		additional_headers["X-Authorization"] = PlayFabManager.client_config.session_ticket
	elif auth_type == AUTH_TYPE.ENTITY_TOKEN:
		additional_headers["X-EntityToken"] = PlayFabManager.client_config.entity_token.EntityToken
	else:
		push_error("auth_type \"" + auth_type + "\" is invalid")

	return true
