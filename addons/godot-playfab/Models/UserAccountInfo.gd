extends JsonSerializable
class_name UserAccountInfo


var AndroidDeviceInfo


var AppleAccountInfo


var Created: String


var CustomIdInfo


var FacebookInfo


var FacebookInstantGamesIdInfo


var GameCenterInfo


var GoogleInfo


var IosDeviceInfo


var KongregateInfo


var NintendoSwitchAccountInfo


var NintendoSwitchDeviceIdInfo


var OpenIdInfo: Array


var PlayFabId: String


var PrivateInfo


var PsnInfo


var SteamInfo


var TitleInfo: UserTitleInfo


var TwitchInfo


var Username: String


var XboxInfo

func _get_type_for_property(property_name: String)->String:
	match property_name:
		"TitleInfo":
			return "UserTitleInfo"
	
	push_error("Could not find mapping for property: " + property_name)
	return ._get_type_for_property(property_name)
