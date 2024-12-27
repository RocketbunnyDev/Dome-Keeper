extends JsonSerializable
class_name GetTitleDataRequest










var Keys: Array = []


var OverrideLabel: String = ""


func _get_type_for_property(property_name: String)->String:
	match property_name:
		_:
			pass
	
	push_error("Could not find mapping for property: " + property_name)
	return ._get_type_for_property(property_name)
