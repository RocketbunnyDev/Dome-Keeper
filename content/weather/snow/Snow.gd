extends Sprite

enum {STARTING, RUNNING, ENDING}
var state = STARTING

var far_snow = null
var far_bg = null

func _ready():
	Style.init(self)
	start_weather()
	Data.listen(self, "keeper.insidedome", true)

func propertyChanged(property: String, oldValue, newValue):
	match property:
		"keeper.insidedome":
			if newValue:
				
				var start = $ice / overlay.modulate
				start.a = 0
				var end = $ice / overlay.modulate
				end.a = 1














func freeze(v):
	var mat: ShaderMaterial = $ice / overlay.material
	mat.set_shader_param("strength", v)

func start_weather():
	state = STARTING
	
	var possible_positions = get_tree().get_nodes_in_group("weather-rain")
	if possible_positions.size():
		get_parent().remove_child(self)
		possible_positions[0].add_child(self)
		
		var start = modulate
		start.a = 0.0
		var end = modulate
		end.a = 1

		var far_position = get_tree().get_nodes_in_group("weather-snowfar")
		if far_position.size():
			far_snow = $Snow.duplicate()
			far_snow.lifetime *= 2
			far_snow.preprocess *= 2
			far_snow.process_material = far_snow.process_material.duplicate()
			(far_snow.process_material as ShaderMaterial).set_shader_param("scale", 0.5)
			far_position[0].add_child(far_snow)
			$Tween.interpolate_property(far_snow, "modulate", start, end, 10.0)
			
			far_bg = $ColorRect.duplicate()
			far_bg.color.a = 0.5
			far_position[0].add_child(far_bg)
			$Tween.interpolate_property(far_bg, "modulate", start, end, 10.0)

		$Tween.interpolate_property(self, "modulate", start, end, 10.0)
		$Tween.interpolate_property($SnowSound, "volume_db", - 30, 0, 10.0)
		$Tween.interpolate_callback(self, 10.0, "started")
		$Tween.start()
		$ice / overlay.modulate.a = 0
	else:
		queue_free()

func started():
	state = RUNNING
	
func stop():
	state = ENDING
	var start = modulate
	var end = modulate
	end.a = 0
	$Tween.interpolate_property(self, "modulate", start, end, 3.0)
	$Tween.interpolate_property($SnowSound, "volume_db", 0, - 40, 3.0)
	$Tween.interpolate_callback(self, 3.0, "queue_free")
	if far_snow:
		$Tween.interpolate_property(far_snow, "modulate", start, end, 3.0)
		$Tween.interpolate_callback(far_snow, 3.0, "queue_free")
	if far_bg:
		$Tween.interpolate_property(far_bg, "modulate", start, end, 3.0)
		$Tween.interpolate_callback(far_bg, 3.0, "queue_free")
	$Tween.start()






func pauseChanged():
	if GameWorld.paused:
		$Tween.stop_all()
	else:
		$Tween.resume_all()
