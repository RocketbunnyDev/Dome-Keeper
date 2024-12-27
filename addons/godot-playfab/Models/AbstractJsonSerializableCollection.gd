
extends JsonSerializable
class_name AbstractJsonSerializableCollection



var _Items: Array












var _item_type


func append(item: JsonSerializable):
	_Items.append(item)



func size()->int:
	return _Items.size()


func clear():
	_Items.clear();






func to_dict()->Dictionary:
	var index = 0
	var dict = []
	for item in _Items:
		dict.append((item as JsonSerializable).to_dict())
		index += 1

	return dict



func from_dict(data, instance: JsonSerializable):
	var index = 0
	for item in data:
		var nested_instance = _item_type.new()
		nested_instance.from_dict(item, nested_instance)
		_Items.append(nested_instance)
		index += 1
