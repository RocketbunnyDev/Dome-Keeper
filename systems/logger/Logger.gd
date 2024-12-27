extends Node

func info(message: String, source: = "", data = null):
	if source:
		print(source + ": " + message + (" Data: " + JSON.print(data) if data else ""))
	else:
		print(message + (" Data: " + JSON.print(data) if data else ""))

func warn(message: String, source: = "", data = null):
	if source:
		var data_out = JSON.print(data) if data else ""
		var msg = source + ": " + message + (" Data: " + data_out)
		print(msg)
		Backend.event("warning", {"message": message, "source": source, "data": data_out})
	else:
		var data_out = JSON.print(data) if data else ""
		var msg = message + (" Data: " + data_out)
		print(msg)
		Backend.event("warning", {"message": message, "source": source, "data": data_out})
	
func error(message: String, source: = "", data = null):
	if source:
		push_error(source + ": " + message)
		var data_out = JSON.print(data) if data else ""
		var msg = source + ": " + message + (" Data: " + data_out)
		printerr(msg)
		Backend.event("error", {"message": message, "source": source, "data": data_out})
	else:
		push_error(message)
		var data_out = JSON.print(data) if data else ""
		var msg = source + ": " + message + (" Data: " + data_out)
		printerr(msg)
		Backend.event("error", {"message": message, "source": source, "data": data_out})
