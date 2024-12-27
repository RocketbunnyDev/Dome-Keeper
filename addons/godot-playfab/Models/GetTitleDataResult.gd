extends JsonSerializable
class_name GetTitleDataResult


var Data: Dictionary


func _get_type_for_property(property_name: String)->String:
	match property_name:
		_:
			pass
	
	push_error("Could not find mapping for property: " + property_name)
	return ._get_type_for_property(property_name)
