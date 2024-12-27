class_name UUID
extends Reference













var _data: PoolByteArray
var _string: String


func _init(from = null):
	if from is PoolByteArray:
		assert (from.size() == 16)
		_data = from
	elif from is String:
		assert (from.length() == 36)
		_data = PoolByteArray([
			_hex_byte(from, 0), _hex_byte(from, 2), _hex_byte(from, 4), _hex_byte(from, 6), 
			
			_hex_byte(from, 9), _hex_byte(from, 11), 
			
			_hex_byte(from, 14), _hex_byte(from, 16), 
			
			_hex_byte(from, 19), _hex_byte(from, 21), 
			
			_hex_byte(from, 24), _hex_byte(from, 26), _hex_byte(from, 28), 
			_hex_byte(from, 30), _hex_byte(from, 32), _hex_byte(from, 34)
		])
		_string = from
	else:
		_data = v4bin()

	
	assert (_data[6] & 240 == 64)
	assert (_data[8] & 192 == 128)




func _to_string()->String:
	if _string:
		return _string
	_string = format(_data)
	return _string



func is_equal(object)->bool:
	
	if object is Object and get_script().instance_has(object):
		
		if _string and object._string:
			return _string == object._string
		
		
		assert (object._data is PoolByteArray)
		object = object._data
		

	
	if object is PoolByteArray:
		if object.size() != 16:
			return false
		for i in 16:
			if _data[i] != object[i]:
				return false
		return true

	
	if not _string:
		_string = format(_data)
	return _string == str(object)



static func v4()->String:
	return format(v4bin())





static func v4bin()->PoolByteArray:
	var data: PoolByteArray

	if OS.has_feature("web"):
		
		if OS.has_feature("JavaScript"):
			
			var output = JavaScript.eval("window.crypto.getRandomValues(new Uint8Array(16));")
			if output is PoolByteArray and output.size() == 16:
				data = output

		if not data:
			
			
			randomize()
			data = PoolByteArray([
				_randb(), _randb(), _randb(), _randb(), 
				_randb(), _randb(), _randb(), _randb(), 
				_randb(), _randb(), _randb(), _randb(), 
				_randb(), _randb(), _randb(), _randb()
			])

	else:
		
		data = Crypto.new().generate_random_bytes(16)

	data[6] = (data[6] & 15) | 64
	data[8] = (data[8] & 63) | 128
	return data


static func format(data: PoolByteArray)->String:
	assert (data.size() == 16)
	return "%02x%02x%02x%02x-%02x%02x-%02x%02x-%02x%02x-%02x%02x%02x%02x%02x%02x" % (data as Array)



static func _randb()->int:
	return randi() % 256


static func _hex_byte(text: String, offset: int)->int:
	return ("0x" + text.substr(offset, 2)).hex_to_int()
