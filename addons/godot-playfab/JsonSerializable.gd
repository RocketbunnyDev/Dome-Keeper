extends Reference
class_name JsonSerializable







func _get_type_for_property(property_name: String):
	push_error("No mapping for property " + property_name)
	return ""



func to_dict()->Dictionary:

	var dict = {}
	var props = get_property_list()

	
	for i in range(3, props.size()):
		var prop = props[i]
		var name = prop["name"]
		var type = prop["type"]

		if (type == TYPE_OBJECT):
			
			var sub_prop = get(name)
			if sub_prop == null:
				
				dict[name] = null
			elif sub_prop.has_method("to_dict"):
				
				dict[name] = sub_prop.to_dict()
			else:
				var type_name = sub_prop.get_class()
				
				
				
				print_debug("If '%s' is not a builtin class, please implement a to_dict() method! If it IS a builtin class, a special handler needs to be implemented in JsonSerializable." % type_name)
				dict[name] = type_name
		else:
			
			dict[name] = get(name)

	return dict





func from_dict(data: Dictionary, instance: JsonSerializable):

	var props = instance.get_property_list()
	for key in data.keys():

		var type
		for prop in props:
			if prop["name"] == key:
				type = prop["type"]
				break

		
		if type != TYPE_OBJECT:
			instance.set(key, data[key])
		elif data[key] == null:
			instance.set(key, null)
		else:
			
			var type_name = instance._get_type_for_property(key)
			var nested_instance = instance.get_class_instance(type_name)
			
			nested_instance.from_dict(data[key], nested_instance)
			instance.set(key, nested_instance)





func get_class_instance(name: String)->Reference:
	var classes = ProjectSettings.get_setting("_global_script_classes")
	for element in classes:
		if element["class"] == name:
			return load(element["path"]).new()


	push_error("Class \"" + name + "\" could not be found")
	return null
