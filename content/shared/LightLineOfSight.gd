extends Node2D

export  var light_name: String = "default"
export  var light_color: Color = Color.white
export  var light_expansion: float = 3.0
export  var light_size: float = 64.0
export  var light_precision: int = 144
export  var light_active: bool = true setget set_light_active
export  var light_flicker_strength: float = 0.0
export  var light_flicker_speed: float = 1.0

var flicker_tween: Tween = null
var flicker_expansion: float = 0.0
var angle_slice: float = 32.0

onready var los_ray: RayCast2D = RayCast2D.new()

func _ready()->void :
	add_child(los_ray)
	los_ray.enabled = true
	light_name += "_" + str(get_instance_id())
	los_ray.cast_to = Vector2(0, light_size)
	angle_slice = TAU / light_precision
	
	if light_flicker_strength > 0.0:
		flicker_tween = Tween.new()
		add_child(flicker_tween)
		flicker_tween.connect("tween_all_completed", self, "start_flicker")
		start_flicker()


func start_flicker():
	var strength: float = rand_range(light_flicker_strength, light_flicker_strength * 2)
	flicker_tween.interpolate_property(self, "flicker_expansion", flicker_expansion, strength, 0.08 * light_flicker_speed, Tween.TRANS_CUBIC)
	flicker_tween.start()


func set_light_active(value: bool):
	if light_active == value:
		return 
	
	light_active = value
	if not light_active:
		Level.map.lights.remove_light(light_name)


func _physics_process(delta):
	if not light_active:
		return 
	
	var points: PoolVector2Array = []
	
	for i in light_precision:
		los_ray.rotation = angle_slice * i
		los_ray.force_raycast_update()
		
		var direction: Vector2 = Vector2.ZERO
		var distance: float = 0.0
		var los_point: Vector2 = Vector2.ZERO
		if los_ray.is_colliding():
			los_point = los_ray.get_collision_point() - global_position
		else:
			los_point = los_ray.cast_to.rotated(los_ray.rotation)
		
		direction = los_point.normalized()
		distance = los_point.length() + light_expansion
		var new_point = direction * (distance + flicker_expansion)
		
		points.append(new_point)
		
	Level.map.lights.update_light_poly(light_name, points, light_color, global_position)
