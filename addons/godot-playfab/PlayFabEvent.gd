extends PlayFab
class_name PlayFabEvent, "res://addons/godot-playfab/icon.png"





signal event_batch_playstream_flushed(event_ids)



signal event_batch_telemetry_flushed(event_ids)


export (int) var event_batch_size = 5


export (int) var event_batch_timeout_seconds = 10



export (bool) var use_local_time = true


var playstream_event_batch = EventContentsCollection.new()
var telemetry_event_batch = EventContentsCollection.new()

func _ready():
	var timer = Timer.new()
	timer.process_mode = Timer.TIMER_PROCESS_IDLE
	timer.wait_time = event_batch_timeout_seconds
	timer.one_shot = false
	timer.autostart = true
	timer.connect("timeout", self, "_flush_playstream_event_batch")
	timer.connect("timeout", self, "_flush_telemetry_event_batch")
	add_child(timer)


func _process(_delta):
	_flush_batches_on_batch_size_met()



func event_telemetry_write_events(request_data: WriteEventsRequest, callback: FuncRef):
	_post_with_entity_auth(request_data, "/Event/WriteTelemetryEvents", callback)



func event_playstream_write_events(request_data: WriteEventsRequest, callback: FuncRef):
	_post_with_entity_auth(request_data, "/Event/WriteEvents", callback)



func write_title_player_telemetry_event(event_name: String, payload: Dictionary, callback: FuncRef, event_namespace = "custom.%s" % _title_id):
	var event = _assemble_event(event_name, payload, event_namespace)
	
	var request = WriteEventsRequest.new()
	request.Events.append(event)
	event_telemetry_write_events(request, callback)



func write_title_player_playstream_event(event_name: String, payload: Dictionary, callback: FuncRef, event_namespace = "custom.%s" % _title_id):
	var event = _assemble_event(event_name, payload, event_namespace)
	
	var request = WriteEventsRequest.new()
	request.Events.append(event)
	event_playstream_write_events(request, callback)



func batch_title_player_telemetry_event(event_name: String, payload: Dictionary, callback: FuncRef, event_namespace = "custom.%s" % _title_id):
	var event = _assemble_event(event_name, payload, event_namespace)
	telemetry_event_batch.append(event)



func batch_title_player_playstream_event(event_name: String, payload: Dictionary, callback: FuncRef, event_namespace = "custom.%s" % _title_id):
	var event = _assemble_event(event_name, payload, event_namespace)
	playstream_event_batch.append(event)



func _assemble_event(event_name: String, payload: Dictionary, callback: FuncRef, event_namespace = "custom.%s" % _title_id)->EventContents:
	var event = EventContents.new()
	event.Name = event_name
	event.EventNamespace = event_namespace
	event.Payload = payload
	
	if use_local_time:
		event.OriginalTimestamp = DateTimeHelper.get_date_time_string_utc()

	
	
	

	return event




func _flush_batches_on_batch_size_met():
	if playstream_event_batch.size() >= event_batch_size:
		_flush_playstream_event_batch()
	elif telemetry_event_batch.size() >= event_batch_size:
		_flush_telemetry_event_batch()



func _flush_playstream_event_batch():
	if playstream_event_batch.size() < 1:
		return 

	var request = WriteEventsRequest.new()
	request.Events = playstream_event_batch
	event_playstream_write_events(request, funcref(self, "_on_playstream_batch_flush"))
	playstream_event_batch.clear()




func _flush_telemetry_event_batch():
	if telemetry_event_batch.size() < 1:
		return 

	var request = WriteEventsRequest.new()
	request.Events = telemetry_event_batch
	event_telemetry_write_events(request, funcref(self, "_on_telemetry_batch_flush"))
	telemetry_event_batch.clear()




func _on_playstream_batch_flush(response: Dictionary):
	var event_ids: Array = response["data"]["AssignedEventIds"]
	emit_signal("event_batch_playstream_flushed", event_ids)




func _on_telemetry_batch_flush(response: Dictionary):
	var event_ids: Array = response["data"]["AssignedEventIds"]
	emit_signal("event_batch_telemetry_flushed", event_ids)
