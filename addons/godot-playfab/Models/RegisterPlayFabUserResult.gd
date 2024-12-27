extends JsonSerializable
class_name RegisterPlayFabUserResult




var EntityToken: EntityTokenResponse


var PlayFabId: String


var SessionTicket: String


var SettingsForUser


var Username: String

func _get_type_for_property(property_name: String)->String:
	match property_name:
		"EntityToken":
			return "EntityTokenResponse"
	
	push_error("Could not find mapping for property: " + property_name)
	return ._get_type_for_property(property_name)
