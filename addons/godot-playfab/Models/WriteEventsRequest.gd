extends JsonSerializable
class_name WriteEventsRequest


var Events: EventContentsCollection


var CustomTags: Dictionary


func _init():
	Events = EventContentsCollection.new()


func _get_type_for_property(property_name: String)->String:
	match property_name:
		"Events":
			return "EventContentsCollection"
		_:
			pass

	push_error("Could not find mapping for property: " + property_name)
	return ._get_type_for_property(property_name)

