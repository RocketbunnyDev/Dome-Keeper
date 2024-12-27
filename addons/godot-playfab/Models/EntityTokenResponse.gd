extends JsonSerializable
class_name EntityTokenResponse


var Entity: EntityKey


var EntityToken: String


var TokenExpiration: String

func _get_type_for_property(property_name: String)->String:
	match property_name:
		"Entity":
			return "EntityKey"
	
	push_error("Could not find mapping for property: " + property_name)
	return ._get_type_for_property(property_name)
