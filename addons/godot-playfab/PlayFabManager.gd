extends Node




var _client_config_loader = PlayFabClientConfigLoader.new()




var title_id: String



var client_config: PlayFabClientConfig



var client: PlayFabClient = PlayFabClient.new()



var event: PlayFabEvent = PlayFabEvent.new()



func _init():
	if ProjectSettings.has_setting(PlayFabConstants.SETTING_PLAYFAB_TITLE_ID) and ProjectSettings.get_setting(PlayFabConstants.SETTING_PLAYFAB_TITLE_ID) != "":
		title_id = ProjectSettings.get_setting(PlayFabConstants.SETTING_PLAYFAB_TITLE_ID)
	else:
		push_error("Title Id was not set in ProjectSettings: %s" % PlayFabConstants.SETTING_PLAYFAB_TITLE_ID)



func _ready():
	add_child(client)
	add_child(event)
	client_config = _client_config_loader.load(title_id)



func save_client_config():
	_client_config_loader.save(title_id, client_config)
