extends InputProcessor

var camera

func drag_right(event: InputEventMouseMotion)->bool:
	var change = - event.relative * camera.zoom
	camera.position += change
	return true

func wheel_up(event: InputEventMouseButton)->bool:
	changeZoom(0.9)
	return true

func wheel_down(event: InputEventMouseButton)->bool:
	changeZoom(1.1)
	return true

func changeZoom(zoom_change: float):
	var viewport_size = get_viewport().size
	var previous_zoom = camera.zoom
	camera.zoom = camera.zoom * zoom_change
	var mouse_position = get_viewport().get_mouse_position()
	camera.offset += ((viewport_size * 0.5) - mouse_position) * (camera.zoom - previous_zoom)
