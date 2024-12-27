extends JsonSerializable
class_name UserTitleInfo


var AvatarUrl: String


var Created: String


var DisplayName: String


var FirstLogin: String


var LastLogin: String


var Origination: String


var TitlePlayerAccount: EntityKey


var isBanned: bool

func _get_type_for_property(property_name: String)->String:
	match property_name:
		"Origination":
			return "UserOrigination"
		"TitlePlayerAccount":
			return "EntityKey"
	
	push_error("Could not find mapping for property: " + property_name)
	return ._get_type_for_property(property_name)
