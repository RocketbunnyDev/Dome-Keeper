tool 
extends Control

var editor_resource_filesystem_cached

func _ready():
	
	editor_resource_filesystem_cached = EditorPlugin.new().get_editor_interface().get_resource_filesystem()

func _on_SaveModel_pressed():
	
	if not guard_class_name_set():
		return 
		
	var file_dialog = $FileDialog
	file_dialog.current_file = $VBoxContainer / ClassNameContainer / LineEdit.text + ".gd"
	file_dialog.show()
	file_dialog.connect("file_selected", self, "_on_file_selected", [], CONNECT_ONESHOT)


func _on_save_direct_pressed():
	
	if not guard_class_name_set():
		return 
		
	var file_name = $VBoxContainer / ClassNameContainer / LineEdit.text + ".gd"
	var file_path = "res://addons/godot-playfab/Models/" + file_name
	_on_file_selected(file_path)


func _on_file_selected(file_path: String):
	
	var model = to_model($VBoxContainer / ClassNameContainer / LineEdit.text, $VBoxContainer / Input.text)
	var file = File.new()
	file.open(file_path, File.WRITE)
	file.store_string(model)
	file.close()
	
	
	editor_resource_filesystem_cached.scan()
	
	print("Saved model to file path: \"%s\"" % file_path)
	

func guard_class_name_set()->bool:
	if $VBoxContainer / ClassNameContainer / LineEdit.text.empty():
		$ErrorPopupDialog / Label.text = "Please first enter a Class Name!"
		$ErrorPopupDialog.popup_centered(Vector2(0, 0))
		return false
		
	return true


static func to_model(object_name: String, input: String)->String:
	var lines = input.split("\n", true)
	lines.push_back("")
	
	var props = []
	var current_prop = ""
	var prop_line = 0
	for line in lines:
		
		var str_line = (line as String).strip_edges()
		
		if not str_line.empty():
			match prop_line:
				0:
					current_prop = "var " + str_line
				1:
					str_line = fix_type(str_line)
					if not str_line.empty() and not str_line.begins_with("#"):
						current_prop += ": %s" % str_line
					else:
						current_prop = str_line
				2:
					current_prop = "# %s\n%s" % [str_line, current_prop]
			
			prop_line += 1
		else:
			props.append(current_prop)
			prop_line = 0
		
	var model = "extends JsonSerializable\nclass_name " + object_name + "\n\n"
	for prop in props:
		model += prop + "\n\n"
	
	
	model += \
\
\
\
\
\
\
\
\
\
\
	"\nfunc _get_type_for_property(property_name: String) -> String:\n	match property_name:\n#		\"<PROPERTY NAME>\":\n#			return \"<PROPERTY TYPE>\"\n		_:\n			pass\n	\n	push_error(\"Could not find mapping for property: \" + property_name)\n	return ._get_type_for_property(property_name)\n	\n"
	return model

static func fix_type(type: String)->String:
	
	match type:
		"string":
			return "String"
		"boolean":
			return "bool"
		_:
			if type.ends_with("]"):
				return "Array"
			return type

