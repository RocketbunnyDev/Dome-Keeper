extends JsonSerializable
class_name EventContents


var CustomTags: Dictionary



var Entity: EntityKey


var EventNamespace: String


var Name: String


var OriginalId: String


var OriginalTimestamp: String



var Payload: Dictionary


func _get_type_for_property(property_name: String)->String:
	match property_name:
		"Entity":
			return "EntityKey"
		_:
			pass

	push_error("Could not find mapping for property: " + property_name)
	return ._get_type_for_property(property_name)

