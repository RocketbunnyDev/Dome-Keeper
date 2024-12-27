extends JsonSerializable
class_name LoginWithCustomIdRequest


var TitleId: String


var CreateAccount: bool


var CustomId: String


var CustomTags: Dictionary


var EncryptedRequest: String


var InfoRequestParameters: GetPlayerCombinedInfoRequestParams


var PlayerSecret: String


func _get_type_for_property(property_name: String)->String:
	match property_name:
		"InfoRequestParameters":
			return "GetPlayerCombinedInfoRequestParams"
		_:
			pass
	
	push_error("Could not find mapping for property: " + property_name)
	return ._get_type_for_property(property_name)
	
