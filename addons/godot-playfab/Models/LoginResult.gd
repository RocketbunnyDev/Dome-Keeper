extends JsonSerializable
class_name LoginResult


var EntityToken: EntityTokenResponse


var InfoResultPayload: GetPlayerCombinedInfoResultPayload


var LastLoginTime: String


var NewlyCreated: bool


var PlayFabId: String


var SessionTicket: String


var SettingsForUser


var TreatmentAssignment

func _get_type_for_property(property_name: String)->String:
	match property_name:
		"EntityToken":
			return "EntityTokenResponse"
		"InfoResultPayload":
			return "GetPlayerCombinedInfoResultPayload"
	
	push_error("Could not find mapping for property: " + property_name)
	return ._get_type_for_property(property_name)
